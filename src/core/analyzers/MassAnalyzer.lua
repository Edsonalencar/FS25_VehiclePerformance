-- F5 (parte da massa): massT = snapshot.mass.totalT.
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.analyzers = NS.core.analyzers or {}

local Units = NS.core.util.Units
local PerformanceData = NS.core.model.PerformanceData

local MassAnalyzer = {}

function MassAnalyzer.analyze(snapshot, data, opts) -- luacheck: ignore 212/opts
    local mass = snapshot and snapshot.mass
    local massT = type(mass) == "table" and mass.totalT or nil
    if Units.isNum(massT) and massT > 0 then
        data:set("massT", PerformanceData.value(massT, "t", "calculated"))
    else
        data:set("massT", PerformanceData.unknown("t", "calculated", "massa ausente ou <= 0"))
    end
end

NS.core.analyzers.MassAnalyzer = MassAnalyzer
