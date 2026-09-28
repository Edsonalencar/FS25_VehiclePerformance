-- F9 (adhesionForceKn) = G * soma_{i em motrizes}(mu_i * m_i), com
-- m_i = massT * restLoad_i / soma_total(restLoad) e mu_i = fieldFriction_i *
-- frictionScale_i. Usa o conjunto de rodas motrizes do DifferentialAnalyzer.
-- massT em toneladas e G em m/s^2 já dão o resultado direto em kN.
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.analyzers = NS.core.analyzers or {}

local Units = NS.core.util.Units
local PerformanceData = NS.core.model.PerformanceData

local TractionAnalyzer = {}

function TractionAnalyzer.analyze(snapshot, data, opts) -- luacheck: ignore 212/opts
    local drivetrain = data:get("drivetrain")
    if not drivetrain or drivetrain.status ~= "ok" then
        data:set("adhesionForceKn", PerformanceData.unknown("kN", "estimated", "F6 unknown"))
        return
    end

    local massMetric = data:get("massT")
    if not massMetric or massMetric.status ~= "ok" then
        data:set("adhesionForceKn", PerformanceData.unknown("kN", "estimated", "massa desconhecida"))
        return
    end
    local massT = massMetric.value

    local wheels = (type(snapshot.wheels) == "table") and snapshot.wheels or {}
    local sumRestLoad = 0
    for _, w in ipairs(wheels) do
        if Units.isNum(w.restLoad) then
            sumRestLoad = sumRestLoad + w.restLoad
        end
    end
    if sumRestLoad <= 0 then
        data:set("adhesionForceKn", PerformanceData.unknown("kN", "estimated", "soma restLoad <= 0"))
        return
    end

    local sumMuM = 0
    for idx in pairs(drivetrain.value.drivenWheels) do
        local w = wheels[idx]
        if
            type(w) ~= "table"
            or not Units.isNum(w.fieldFriction)
            or not Units.isNum(w.frictionScale)
            or not Units.isNum(w.restLoad)
        then
            data:set("adhesionForceKn", PerformanceData.unknown("kN", "estimated", "friction ausente em roda motriz"))
            return
        end
        local mu = w.fieldFriction * w.frictionScale
        local mi = massT * w.restLoad / sumRestLoad
        sumMuM = sumMuM + mu * mi
    end

    data:set("adhesionForceKn", PerformanceData.value(Units.G * sumMuM, "kN", "estimated"))
end

NS.core.analyzers.TractionAnalyzer = TractionAnalyzer
