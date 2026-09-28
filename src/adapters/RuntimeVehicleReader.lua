-- Lê o veículo de preview da ShopConfigScreen (ou qualquer veículo com dados
-- de servidor, graças a setForceServer(true)) e converte para o Snapshot
-- schema 1 (tabela Lua pura, serializável, consumida por core/ e pelo
-- SnapshotXmlWriter). Cada bloco roda sob pcall próprio (guard): uma falha em
-- um bloco vira campo ausente + log DEBUG, nunca um erro que suba para quem
-- chamou. Único ponto de exceção proposital: debug#simulateFailure=="reader".
local NS = VehiclePerformance
local RuntimeVehicleReader = {}

--- Roda fn protegida; em erro, loga DEBUG com o nome do campo e o motivo.
--- Nunca propaga o erro.
local function guard(logger, field, fn)
    local ok, err = pcall(fn)
    if not ok and logger then
        logger:debug("reader", "campo '%s' falhou: %s", field, tostring(err))
    end
    return ok
end

--- Extrai .ratio numérico de uma lista de marchas/grupos (forwardGears,
--- gearGroups). Tolerante a tabela ausente ou itens sem campo numérico.
local function ratios(list)
    local out = {}
    if type(list) ~= "table" then
        return out
    end
    for _, item in ipairs(list) do
        if type(item) == "table" and type(item.ratio) == "number" then
            out[#out + 1] = item.ratio
        end
    end
    return out
end

--- Conta rodas visuais adicionais (duplas/triplas) além da roda física
--- principal. [A VALIDAR na Fase 3, conforme spec]: assume que
--- w.visualWheels inclui a própria roda como primeiro elemento.
local function additionalCount(w)
    if type(w) == "table" and type(w.visualWheels) == "table" then
        local n = #w.visualWheels - 1
        if n > 0 then
            return n
        end
    end
    return 0
end

--- Lê vehicle/storeItem (preview da loja) → Snapshot schema 1.
---@param vehicle table veículo de preview (Vehicle + spec_motorized/spec_wheels)
---@param storeItem table storeItem correspondente (specs, configurations, brandIndex, ...)
---@param logger table? porta Logger (error/warning/info/debug), pode ser nil
function RuntimeVehicleReader.read(vehicle, storeItem, logger)
    -- Injeção de falha manual para o smoke de degradação da Fase 5: com
    -- debug#enabled e debug#simulateFailure=="reader", read() lança de
    -- propósito (fora de qualquer guard, portanto propaga).
    local settings = NS.app.settings
    if settings and settings:get("debug#enabled") and settings:get("debug#simulateFailure") == "reader" then
        error("falha simulada: reader")
    end

    local s = {
        schema = 1,
        identity = {},
        configuration = {},
        declared = {},
        mass = {},
        differentials = {},
        wheels = {},
    }

    guard(logger, "identity", function()
        storeItem = storeItem or {}
        s.identity.xmlFilename = storeItem.xmlFilename
        s.identity.name = storeItem.name
        s.identity.categoryName = storeItem.categoryName
        s.identity.typeName = vehicle.typeName
        if type(g_brandManager) == "table" and type(g_brandManager.getBrandByIndex) == "function" then
            local brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)
            if type(brand) == "table" then
                s.identity.brand = brand.title or brand.name
            end
        end
    end)

    guard(logger, "configuration", function() -- cópia de vehicle.configurations
        for name, idx in pairs(vehicle.configurations or {}) do
            s.configuration[name] = idx
        end
    end)

    guard(logger, "declared", function()
        local specs = storeItem.specs or {}
        s.declared.powerHp = type(specs.power) == "number" and specs.power or nil
        local cfgs = storeItem.configurations and storeItem.configurations.motor
        local idx = s.configuration.motor
        if cfgs and idx and cfgs[idx] and type(cfgs[idx].power) == "number" then
            s.declared.powerHp = cfgs[idx].power
        end
        s.declared.price = storeItem.price
    end)

    guard(logger, "mass", function()
        if type(vehicle.updateMass) == "function" then
            vehicle:updateMass()
        end
        s.mass.totalT = vehicle:getTotalMass(true)
        if type(vehicle.getDefaultMass) == "function" then
            s.mass.defaultT = vehicle:getDefaultMass()
        end
    end)

    guard(logger, "motor", function()
        local spec = vehicle.spec_motorized
        local m = spec and spec.motor
        if m == nil then
            return
        end
        local curve = {}
        for _, kf in ipairs((m.torqueCurve and m.torqueCurve.keyframes) or {}) do
            curve[#curve + 1] = { rpm = kf.time, torque = kf[1] } -- keyframe {torque, time=rpm} (Motorized.lua:1338)
        end
        s.motor = {
            minRpm = m.minRpm,
            maxRpm = m.maxRpm,
            peakTorque = m.peakMotorTorque,
            peakPowerKw = m.peakMotorPower,
            maxForwardSpeedMs = m.maxForwardSpeed,
            torqueCurve = curve,
            minForwardGearRatio = m.minForwardGearRatio,
            maxForwardGearRatio = m.maxForwardGearRatio,
            forwardGears = ratios(m.forwardGears),
            gearGroups = ratios(m.gearGroups),
        }
    end)

    guard(logger, "differentials", function() -- cópia dos 6 campos (Motorized.lua:1191-1198)
        local spec = vehicle.spec_motorized
        local diffs = spec and spec.differentials
        if type(diffs) ~= "table" then
            return
        end
        for i, d in ipairs(diffs) do
            s.differentials[i] = {
                torqueRatio = d.torqueRatio,
                maxSpeedRatio = d.maxSpeedRatio,
                diffIndex1 = d.diffIndex1,
                diffIndex1IsWheel = d.diffIndex1IsWheel,
                diffIndex2 = d.diffIndex2,
                diffIndex2IsWheel = d.diffIndex2IsWheel,
            }
        end
    end)

    guard(logger, "wheels", function()
        for i, w in ipairs(vehicle:getWheels()) do
            local p = w.physics
            s.wheels[i] = {
                radius = p.radius,
                width = p.width,
                shapeWidth = p.wheelShapeWidth,
                massT = w:getMass(),
                restLoad = p.restLoad,
                frictionScale = p.frictionScale,
                isLeft = w.isLeft,
                tireTypeName = WheelsUtil.getTireTypeName(p.tireType),
                fieldFriction = WheelsUtil.getTireFriction(p.tireType, WheelsUtil.GROUND_FIELD, 0, 0),
                additionalCount = additionalCount(w),
            }
        end
    end)

    return s
end

NS.adapters.RuntimeVehicleReader = RuntimeVehicleReader
