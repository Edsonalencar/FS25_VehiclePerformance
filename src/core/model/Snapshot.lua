-- Snapshot schema 1: contrato entre adapter (RuntimeVehicleReader, Fase 4) e
-- core. Tabela Lua pura e serializável, todas as grandezas em unidades SI do
-- projeto (§Convenções gerais). Campos ausentes valem nil.
--
-- {
--   schema = 1,
--   identity = { xmlFilename, name, brand, category, typeName },
--   configuration = { [configName] = index },                 -- vehicle.configurations
--   declared = { powerHp, maxSpeedKmh, price },
--   mass = { totalT, defaultT },
--   motor = { minRpm, maxRpm, peakTorque, peakPowerKw, maxForwardSpeedMs,
--             torqueCurve = { {rpm=, torque=}, ... },           -- ordenado por rpm
--             forwardGears = { {ratio=}, ... } | nil, gearGroups = { {ratio=}, ... } | nil,
--             minForwardGearRatio, maxForwardGearRatio } | nil,
--   differentials = { {torqueRatio, maxSpeedRatio, diffIndex1, diffIndex1IsWheel,
--                       diffIndex2, diffIndex2IsWheel}, ... },
--   wheels = { {radius, width, shapeWidth, massT, restLoad, frictionScale, fieldFriction,
--               tireTypeName, isLeft, additionalCount}, ... },
-- }
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.model = NS.core.model or {}

local Snapshot = {}

local TOP_LEVEL_FIELDS = { "identity", "configuration", "declared", "mass", "motor", "differentials", "wheels" }

--- validate(s) -> (ok:boolean, missing:string[]). Nunca lança erro; só lista
--- campos de alto nível ausentes (para log DEBUG e data.availability.missing).
function Snapshot.validate(s)
    local missing = {}
    if type(s) ~= "table" then
        return false, { "snapshot" }
    end
    for _, field in ipairs(TOP_LEVEL_FIELDS) do
        if s[field] == nil then
            missing[#missing + 1] = field
        end
    end
    if type(s.mass) == "table" and s.mass.totalT == nil then
        missing[#missing + 1] = "mass.totalT"
    end
    return #missing == 0, missing
end

NS.core.model.Snapshot = Snapshot
