-- F1 (powerDeclaredCv), F2 (peakPowerKw/peakPowerCv), F3 (peakTorqueKnm),
-- F4 (torqueReservePct). Ver §Fórmulas no spec da Fase 2.
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.analyzers = NS.core.analyzers or {}

local Units = NS.core.util.Units
local PerformanceData = NS.core.model.PerformanceData

local MotorAnalyzer = {}

--- Curva ordenada por rpm (não confia na ordem de entrada).
local function sortedCurve(curve)
    local sorted = {}
    for i, p in ipairs(curve) do
        sorted[i] = p
    end
    table.sort(sorted, function(a, b)
        return a.rpm < b.rpm
    end)
    return sorted
end

--- Replica VehicleMotor.lua:169-201: em cada segmento linear da curva,
--- rpm* = clamp((r2*T1 - r1*T2)/(2*(T1-T2)), r1, r2) e P = T(rpm*)*rpm*.
--- Curva com 1 ponto usa rpm*torque diretamente. Devolve kW (rpm em rpm,
--- torque em kN.m).
function MotorAnalyzer.peakPowerFromCurve(curve)
    if type(curve) ~= "table" or #curve == 0 then
        return nil
    end
    if #curve == 1 then
        return curve[1].rpm * curve[1].torque * Units.RPM_TO_RADS
    end
    local best = 0
    for i = 2, #curve do
        local a, b = curve[i - 1], curve[i]
        local rpm, t = a.rpm, a.torque
        if math.abs(a.torque - b.torque) > 0.0001 then
            local opt = (b.rpm * a.torque - a.rpm * b.torque) / (2 * (a.torque - b.torque))
            rpm = math.min(math.max(opt, a.rpm), b.rpm)
            t = a.torque + (b.torque - a.torque) * (rpm - a.rpm) / (b.rpm - a.rpm)
        end
        if t * rpm > best then
            best = t * rpm
        end
    end
    return best * Units.RPM_TO_RADS
end

local function curveMaxTorque(curve)
    local best = 0
    for _, p in ipairs(curve) do
        if Units.isNum(p.torque) and p.torque > best then
            best = p.torque
        end
    end
    return best
end

function MotorAnalyzer.analyze(snapshot, data, opts) -- luacheck: ignore 212/opts
    local declared = snapshot and snapshot.declared
    if type(declared) == "table" and Units.isNum(declared.powerHp) then
        data:set("powerDeclaredCv", PerformanceData.value(declared.powerHp, "cv", "declared"))
    else
        data:set("powerDeclaredCv", PerformanceData.unknown("cv", "declared", "ausente"))
    end

    local motor = snapshot and snapshot.motor
    if type(motor) ~= "table" then
        data:set("peakPowerKw", PerformanceData.unknown("kW", "calculated", "sem motor"))
        data:set("peakPowerCv", PerformanceData.unknown("cv", "calculated", "sem motor"))
        data:set("peakTorqueKnm", PerformanceData.unknown("kN.m", "calculated", "sem motor"))
        data:set("torqueReservePct", PerformanceData.unknown("%", "calculated", "sem motor"))
        return
    end

    local hasCurve = type(motor.torqueCurve) == "table" and #motor.torqueCurve > 0
    local curve = hasCurve and sortedCurve(motor.torqueCurve) or nil

    -- F2
    local peakKw
    if Units.isNum(motor.peakPowerKw) then
        peakKw = motor.peakPowerKw
    elseif curve then
        peakKw = MotorAnalyzer.peakPowerFromCurve(curve)
    end
    if Units.isNum(peakKw) then
        data:set("peakPowerKw", PerformanceData.value(peakKw, "kW", "calculated"))
        data:set("peakPowerCv", PerformanceData.value(peakKw / Units.KW_PER_CV, "cv", "calculated"))
    else
        data:set("peakPowerKw", PerformanceData.unknown("kW", "calculated", "sem curva e sem peak"))
        data:set("peakPowerCv", PerformanceData.unknown("cv", "calculated", "sem curva e sem peak"))
    end

    -- F3
    local peakTorque
    if Units.isNum(motor.peakTorque) then
        peakTorque = motor.peakTorque
    elseif curve then
        peakTorque = curveMaxTorque(curve)
    end
    if Units.isNum(peakTorque) then
        data:set("peakTorqueKnm", PerformanceData.value(peakTorque, "kN.m", "calculated"))
    else
        data:set("peakTorqueKnm", PerformanceData.unknown("kN.m", "calculated", "sem curva"))
    end

    -- F4: T(maxRpm) é o torque do último ponto da curva ordenada por rpm.
    if Units.isNum(peakTorque) and curve then
        local tMax = curve[#curve].torque
        if Units.isNum(tMax) and tMax > 0 then
            data:set("torqueReservePct", PerformanceData.value(100 * (peakTorque - tMax) / tMax, "%", "calculated"))
        else
            data:set("torqueReservePct", PerformanceData.unknown("%", "calculated", "T(maxRpm) <= 0"))
        end
    else
        data:set("torqueReservePct", PerformanceData.unknown("%", "calculated", "sem curva"))
    end
end

NS.core.analyzers.MotorAnalyzer = MotorAnalyzer
