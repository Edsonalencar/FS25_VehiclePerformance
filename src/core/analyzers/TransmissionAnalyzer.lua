-- F7 (maxRatio), mais transmissionType, gearCount e groupCount.
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.analyzers = NS.core.analyzers or {}

local Units = NS.core.util.Units
local PerformanceData = NS.core.model.PerformanceData

local TransmissionAnalyzer = {}

local function setUnknown(data, reason)
    data:set("maxRatio", PerformanceData.unknown("", "calculated", reason))
    data:set("transmissionType", PerformanceData.value("unknown", "", "calculated"))
    data:set("gearCount", PerformanceData.value(0, "", "calculated"))
    data:set("groupCount", PerformanceData.value(0, "", "calculated"))
end

function TransmissionAnalyzer.analyze(snapshot, data, opts) -- luacheck: ignore 212/opts
    local motor = snapshot and snapshot.motor
    if type(motor) ~= "table" then
        setUnknown(data, "sem motor")
        return
    end

    -- CVT.
    if Units.isNum(motor.maxForwardGearRatio) then
        data:set("maxRatio", PerformanceData.value(motor.maxForwardGearRatio, "", "calculated"))
        data:set("transmissionType", PerformanceData.value("cvt", "", "calculated"))
        data:set("gearCount", PerformanceData.value(0, "", "calculated"))
        data:set("groupCount", PerformanceData.value(0, "", "calculated"))
        return
    end

    -- Marchas: max(forwardGears[i].ratio) * max(gearGroups[j].ratio or 1).
    local gears = motor.forwardGears
    if type(gears) == "table" and #gears > 0 then
        local maxGear = 0
        for _, g in ipairs(gears) do
            if Units.isNum(g.ratio) and g.ratio > maxGear then
                maxGear = g.ratio
            end
        end
        local groups = motor.gearGroups
        local maxGroup = 1
        if type(groups) == "table" and #groups > 0 then
            maxGroup = 0
            for _, g in ipairs(groups) do
                local r = g.ratio or 1
                if r > maxGroup then
                    maxGroup = r
                end
            end
        end
        data:set("maxRatio", PerformanceData.value(maxGear * maxGroup, "", "calculated"))
        data:set("transmissionType", PerformanceData.value("gears", "", "calculated"))
        data:set("gearCount", PerformanceData.value(#gears, "", "calculated"))
        data:set("groupCount", PerformanceData.value(type(groups) == "table" and #groups or 0, "", "calculated"))
        return
    end

    setUnknown(data, "sem ratios")
end

NS.core.analyzers.TransmissionAnalyzer = TransmissionAnalyzer
