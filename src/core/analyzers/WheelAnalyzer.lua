-- wheelCount, hasDuals (additionalCount > 0 em alguma roda) e soma de restLoad.
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.analyzers = NS.core.analyzers or {}

local Units = NS.core.util.Units
local PerformanceData = NS.core.model.PerformanceData

local WheelAnalyzer = {}

function WheelAnalyzer.analyze(snapshot, data, opts) -- luacheck: ignore 212/opts
    local wheels = snapshot and snapshot.wheels
    if type(wheels) ~= "table" or #wheels == 0 then
        data:set("wheelCount", PerformanceData.value(0, "", "calculated"))
        data:set("hasDuals", PerformanceData.value(false, "", "calculated"))
        data:set("sumRestLoad", PerformanceData.unknown("", "calculated", "sem rodas"))
        return
    end

    local hasDuals = false
    local sum = 0
    for _, w in ipairs(wheels) do
        if Units.isNum(w.additionalCount) and w.additionalCount > 0 then
            hasDuals = true
        end
        if Units.isNum(w.restLoad) then
            sum = sum + w.restLoad
        end
    end

    data:set("wheelCount", PerformanceData.value(#wheels, "", "calculated"))
    data:set("hasDuals", PerformanceData.value(hasDuals, "", "calculated"))
    data:set("sumRestLoad", PerformanceData.value(sum, "", "calculated"))
end

NS.core.analyzers.WheelAnalyzer = WheelAnalyzer
