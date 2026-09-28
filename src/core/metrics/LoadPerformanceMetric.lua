-- F11 (loadSpeedKmh). F_load = k*massT*G, k = opts.loadRefWeightFraction
-- (padrão 0.5). Se F10 >= F_load: v = min(peakPowerKw/F_load,
-- maxForwardSpeedMs)*3.6, status="ok". Senão status="insufficient".
-- unknown se F2 ou F5 (massa/potência) forem unknown, ou se F10 for unknown
-- (sem força de tração não há como comparar com F_load).
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.metrics = NS.core.metrics or {}

local Units = NS.core.util.Units
local PerformanceData = NS.core.model.PerformanceData

local DEFAULT_LOAD_FRACTION = 0.5

local LoadPerformanceMetric = {}

function LoadPerformanceMetric.analyze(snapshot, data, opts)
    local powerMetric = data:get("peakPowerKw")
    local massMetric = data:get("massT")
    if not powerMetric or powerMetric.status ~= "ok" or not massMetric or massMetric.status ~= "ok" then
        data:set("loadSpeedKmh", PerformanceData.unknown("km/h", "estimated", "F2 ou F5 unknown"))
        return
    end

    local tractionMetric = data:get("tractionForceKn")
    if not tractionMetric or tractionMetric.status == "unknown" then
        data:set("loadSpeedKmh", PerformanceData.unknown("km/h", "estimated", "F10 unknown"))
        return
    end

    local k = (opts and Units.isNum(opts.loadRefWeightFraction)) and opts.loadRefWeightFraction or DEFAULT_LOAD_FRACTION
    local fLoad = k * massMetric.value * Units.G

    local motor = (snapshot and type(snapshot.motor) == "table") and snapshot.motor or {}
    local maxSpeedMs = Units.isNum(motor.maxForwardSpeedMs) and motor.maxForwardSpeedMs or math.huge

    if tractionMetric.value >= fLoad then
        local vKmh = math.min(powerMetric.value / fLoad, maxSpeedMs) * 3.6
        data:set("loadSpeedKmh", PerformanceData.value(vKmh, "km/h", "estimated"))
    else
        data:set("loadSpeedKmh", { value = nil, unit = "km/h", kind = "estimated", status = "insufficient" })
    end
end

NS.core.metrics.LoadPerformanceMetric = LoadPerformanceMetric
