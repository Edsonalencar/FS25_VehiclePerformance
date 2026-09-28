-- F6 (drivetrain: label, drivenWheels, drivenAxles). Rodas motrizes = união
-- dos índices de roda referenciados diretamente por qualquer diferencial
-- (diffIndexNIsWheel=true; índice 1-based). label = "<#wheels>x<#driven>".
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.analyzers = NS.core.analyzers or {}

local Units = NS.core.util.Units
local PerformanceData = NS.core.model.PerformanceData

local DifferentialAnalyzer = {}

function DifferentialAnalyzer.analyze(snapshot, data, opts) -- luacheck: ignore 212/opts
    local diffs = snapshot and snapshot.differentials
    if type(diffs) ~= "table" or #diffs == 0 then
        data:set("drivetrain", PerformanceData.unknown("", "calculated", "no_differentials"))
        return
    end

    local wheels = (snapshot and type(snapshot.wheels) == "table") and snapshot.wheels or {}
    local driven = {}
    local axles = 0

    for _, d in ipairs(diffs) do
        for side = 1, 2 do
            local idx = d["diffIndex" .. side]
            local isWheel = d["diffIndex" .. side .. "IsWheel"]
            if isWheel then
                if not Units.isNum(idx) or idx < 1 or idx > #wheels then
                    data:set("drivetrain", PerformanceData.unknown("", "calculated", "bad_wheel_index"))
                    return
                end
                driven[idx] = true
            else
                if not Units.isNum(idx) or idx < 0 or idx > (#diffs - 1) then
                    data:set("drivetrain", PerformanceData.unknown("", "calculated", "bad_diff_index"))
                    return
                end
            end
        end
        if d.diffIndex1IsWheel and d.diffIndex2IsWheel then
            axles = axles + 1
        elseif d.diffIndex1IsWheel or d.diffIndex2IsWheel then
            axles = axles + 1 -- roda sem par (raro)
        end
    end

    local drivenCount = 0
    for _ in pairs(driven) do
        drivenCount = drivenCount + 1
    end
    if drivenCount == 0 then
        data:set("drivetrain", PerformanceData.unknown("", "calculated", "no_driven_wheels"))
        return
    end

    local label = string.format("%dx%d", #wheels, drivenCount)
    data:set(
        "drivetrain",
        PerformanceData.value({ label = label, drivenWheels = driven, drivenAxles = axles }, "", "calculated")
    )
end

NS.core.analyzers.DifferentialAnalyzer = DifferentialAnalyzer
