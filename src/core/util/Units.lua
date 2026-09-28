-- Constantes e utilitários numéricos usados por todo o core (Fase 2, §Fórmulas).
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.util = NS.core.util or {}

local Units = {}

Units.G = 9.81 -- m/s^2
Units.KW_PER_CV = 0.73549875 -- 1 cv em kW
Units.RPM_TO_RADS = math.pi / 30 -- rpm -> rad/s

--- Verdadeiro só para números finitos (exclui NaN e +-inf).
function Units.isNum(x)
    return type(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge
end

--- Restringe v ao intervalo [lo, hi].
function Units.clamp(v, lo, hi)
    if v < lo then
        return lo
    end
    if v > hi then
        return hi
    end
    return v
end

NS.core.util.Units = Units
