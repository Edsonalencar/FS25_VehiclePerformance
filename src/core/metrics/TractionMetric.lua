-- F8 (motorForceKn = peakTorqueKnm * maxRatio) e F10 (tractionForceKn =
-- min(F8,F9), tractionLimit). Só um dos dois disponível => usa esse valor e
-- tractionLimit="partial"; unknown só se ambos forem unknown.
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.metrics = NS.core.metrics or {}

local PerformanceData = NS.core.model.PerformanceData

local TractionMetric = {}

function TractionMetric.analyze(snapshot, data, opts) -- luacheck: ignore 212/snapshot 212/opts
    local torqueMetric = data:get("peakTorqueKnm")
    local ratioMetric = data:get("maxRatio")

    local motorForce
    if torqueMetric and torqueMetric.status == "ok" and ratioMetric and ratioMetric.status == "ok" then
        motorForce = torqueMetric.value * ratioMetric.value
        data:set("motorForceKn", PerformanceData.value(motorForce, "kN", "calculated"))
    else
        data:set("motorForceKn", PerformanceData.unknown("kN", "calculated", "F3 ou F7 unknown"))
    end

    local adhesionMetric = data:get("adhesionForceKn")
    local adhesionOk = adhesionMetric and adhesionMetric.status == "ok"
    local motorOk = motorForce ~= nil

    if motorOk and adhesionOk then
        local adhesion = adhesionMetric.value
        local traction = math.min(motorForce, adhesion)
        local limit = (adhesion < motorForce) and "adhesion" or "motor"
        data:set("tractionForceKn", PerformanceData.value(traction, "kN", "estimated"))
        data:set("tractionLimit", PerformanceData.value(limit, "", "estimated"))
    elseif motorOk or adhesionOk then
        local value = motorOk and motorForce or adhesionMetric.value
        data:set("tractionForceKn", PerformanceData.value(value, "kN", "estimated"))
        data:set("tractionLimit", PerformanceData.value("partial", "", "estimated"))
    else
        data:set("tractionForceKn", PerformanceData.unknown("kN", "estimated", "F8 e F9 unknown"))
        data:set("tractionLimit", PerformanceData.unknown("", "estimated", "F8 e F9 unknown"))
    end
end

NS.core.metrics.TractionMetric = TractionMetric
