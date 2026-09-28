-- F5 (parte da potência/peso): powerToWeightKgPerCv = massT*1000 / peakPowerCv.
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.metrics = NS.core.metrics or {}

local PerformanceData = NS.core.model.PerformanceData

local PowerToWeightMetric = {}

function PowerToWeightMetric.analyze(snapshot, data, opts) -- luacheck: ignore 212/snapshot 212/opts
    local massMetric = data:get("massT")
    local powerMetric = data:get("peakPowerCv")
    local massOk = massMetric and massMetric.status == "ok" and massMetric.value > 0
    local powerOk = powerMetric and powerMetric.status == "ok"

    if not massOk or not powerOk then
        data:set(
            "powerToWeightKgPerCv",
            PerformanceData.unknown("kg/cv", "calculated", "massa <= 0 ou potência desconhecida")
        )
        return
    end

    data:set(
        "powerToWeightKgPerCv",
        PerformanceData.value(massMetric.value * 1000 / powerMetric.value, "kg/cv", "calculated")
    )
end

NS.core.metrics.PowerToWeightMetric = PowerToWeightMetric
