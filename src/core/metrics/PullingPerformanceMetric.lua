-- F12 (pullingIndex, 0-100, heurístico): 100*F10/(F10+F_ref), F_ref =
-- opts.pullingRefKN (padrão 50). unknown se F10 for unknown.
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.metrics = NS.core.metrics or {}

local Units = NS.core.util.Units
local PerformanceData = NS.core.model.PerformanceData

local DEFAULT_PULLING_REF_KN = 50

local PullingPerformanceMetric = {}

function PullingPerformanceMetric.analyze(snapshot, data, opts) -- luacheck: ignore 212/snapshot
    local tractionMetric = data:get("tractionForceKn")
    if not tractionMetric or tractionMetric.status == "unknown" or not Units.isNum(tractionMetric.value) then
        data:set("pullingIndex", PerformanceData.unknown("", "heuristic", "F10 unknown"))
        return
    end

    local fRef = (opts and Units.isNum(opts.pullingRefKN)) and opts.pullingRefKN or DEFAULT_PULLING_REF_KN
    local f10 = tractionMetric.value
    data:set("pullingIndex", PerformanceData.value(100 * f10 / (f10 + fRef), "", "heuristic"))
end

NS.core.metrics.PullingPerformanceMetric = PullingPerformanceMetric
