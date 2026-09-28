-- Converte PerformanceData (core/model/PerformanceData.lua, Fases 2/3) em
-- linhas de texto localizadas para o ShopConfigScreen. Não toca no jogo: só
-- recebe a porta `text` (implementada por adapters/GameText.lua) já
-- injetada pelo chamador (adapters/ShopConfigAdapter.lua).
--
-- Contrato assumido para `data` (ainda não fechado pela Fase 2/3 no momento
-- em que este arquivo foi escrito; ver nota de ambiguidade no relato da
-- Fase 4): `data:get(id)` devolve um "Value" `{value, unit, kind, status,
-- reason}` ou nil, igual ao `PerformanceData:get(id)` do spec. Ids usados
-- aqui:
--   "drivetrain"             value = {label=string, drivenAxles=number}
--   "peakPowerCv"            value = number (cv)
--   "peakPowerKw"            value = number (kW)
--   "peakTorqueKnm"          value = number (kN·m; ×1000 = N·m)
--   "torqueReservePct"       value = number (%), pode faltar mesmo com peakPowerCv ok
--   "powerToWeightKgPerCv"   value = number (kg/cv)
--   "tractionForceKn"        value = number (kN)
--   "tractionLimit"          value = "adhesion"|"motor"|"partial"
--   "loadRefWeightFraction"  value = number (0..1)
--   "loadSpeedKmh"           value = number (km/h); status também aceita "insufficient"
--   "pullingIndex"           value = number (0..100)
local NS = VehiclePerformance
local RowFormatter = {}

local LIMIT_KEY = {
    adhesion = "vp_limit_adhesion",
    motor = "vp_limit_motor",
    partial = "vp_limit_partial",
}

local function isOk(v)
    return v ~= nil and v.status == "ok"
end

-- string.format(text.get(key), ...) sob pcall: se o formato falhar (ex.:
-- tradução com mais "%s" do que argumentos), a linha é omitida e um WARNING
-- é logado, se um logger tiver sido injetado via opts.logger. RowFormatter
-- vive em app/ e não tem logger próprio (não pode depender de adapters/), por
-- isso o logger é opcional aqui: sem ele, a omissão é silenciosa.
local function safeFormat(text, logger, key, ...)
    local pattern = text.get(key)
    local ok, out = pcall(string.format, pattern, ...)
    if ok then
        return out
    end
    if logger then
        logger:warning("formatter", "formato inválido para %s", tostring(key))
    end
    return nil
end

--- @param data PerformanceData  ver contrato no comentário de topo deste arquivo
--- @param text table  porta de texto: get(key), number(v,precision), speed(kmh) -> valor, unidade
--- @param opts {showPullingIndex:boolean|nil, logger:table|nil}
--- @return table  lista { {profile=string, text=string}, ... } na ordem fixa do spec (Fase 4)
function RowFormatter.rows(data, text, opts)
    opts = opts or {}
    local logger = opts.logger
    local rows = {}

    -- 1. WHEELS: tração/eixos motrizes. Nunca omitida: sem dado, mostra
    -- vp_drivetrain_unknown (inclusive se a formatação da linha normal falhar).
    local drivetrain = data:get("drivetrain")
    local drivetrainLine
    if isOk(drivetrain) and type(drivetrain.value) == "table" then
        drivetrainLine =
            safeFormat(text, logger, "vp_row_drivetrain", drivetrain.value.label, drivetrain.value.drivenAxles)
    end
    if not drivetrainLine then
        drivetrainLine = text.get("vp_drivetrain_unknown")
    end
    rows[#rows + 1] = { profile = "WHEELS", text = drivetrainLine }

    -- 2. POWER: pico calculado (cv/kW/N·m), com reserva de torque se disponível.
    -- Omite a linha inteira se peakPowerCv for unknown.
    local peakPowerCv = data:get("peakPowerCv")
    if isOk(peakPowerCv) then
        local peakPowerKw = data:get("peakPowerKw")
        local peakTorqueKnm = data:get("peakTorqueKnm")
        if isOk(peakPowerKw) and isOk(peakTorqueKnm) then
            local cv = text.number(peakPowerCv.value, 0)
            local kw = text.number(peakPowerKw.value, 0)
            local nm = text.number(peakTorqueKnm.value * 1000, 0)
            local reserve = data:get("torqueReservePct")
            local line
            if isOk(reserve) then
                line = safeFormat(text, logger, "vp_row_power_calc", cv, kw, nm, text.number(reserve.value, 0))
            else
                line = safeFormat(text, logger, "vp_row_power_calc_noreserve", cv, kw, nm)
            end
            if line then
                rows[#rows + 1] = { profile = "POWER", text = line }
            end
        end
    end

    -- 3. WEIGHT: peso/potência (kg/cv, 1 casa decimal). Omite se unknown.
    local powerToWeight = data:get("powerToWeightKgPerCv")
    if isOk(powerToWeight) then
        local line = safeFormat(text, logger, "vp_row_power_weight", text.number(powerToWeight.value, 1))
        if line then
            rows[#rows + 1] = { profile = "WEIGHT", text = line }
        end
    end

    -- 4. TRANSMISSION: força de tração (kN, 0 casas) e texto do limite. Omite
    -- se tractionForceKn for unknown.
    local tractionForceKn = data:get("tractionForceKn")
    if isOk(tractionForceKn) then
        local tractionLimit = data:get("tractionLimit")
        local limitKey = (isOk(tractionLimit) and LIMIT_KEY[tractionLimit.value]) or LIMIT_KEY.partial
        local line =
            safeFormat(text, logger, "vp_row_traction", text.number(tractionForceKn.value, 0), text.get(limitKey))
        if line then
            rows[#rows + 1] = { profile = "TRANSMISSION", text = line }
        end
    end

    -- 5. MAX_SPEED: velocidade sob carga de referência. status "ok" mostra a
    -- fração/velocidade; "insufficient" mostra a linha de tração insuficiente
    -- (sem argumentos); só omite se completamente unknown (nem ok nem
    -- insufficient).
    local loadSpeed = data:get("loadSpeedKmh")
    if loadSpeed ~= nil and loadSpeed.status == "ok" then
        local fraction = data:get("loadRefWeightFraction")
        local fractionPct = isOk(fraction) and (fraction.value * 100) or 0
        local speedValue, speedUnit = text.speed(loadSpeed.value)
        local line =
            safeFormat(text, logger, "vp_row_load", text.number(fractionPct, 0), text.number(speedValue, 0), speedUnit)
        if line then
            rows[#rows + 1] = { profile = "MAX_SPEED", text = line }
        end
    elseif loadSpeed ~= nil and loadSpeed.status == "insufficient" then
        rows[#rows + 1] = { profile = "MAX_SPEED", text = text.get("vp_row_load_insufficient") }
    end

    -- 6. POWER (índice heurístico): só se habilitado explicitamente e status ok.
    if opts.showPullingIndex then
        local pullingIndex = data:get("pullingIndex")
        if isOk(pullingIndex) then
            local line = safeFormat(text, logger, "vp_row_pulling_index", text.number(pullingIndex.value, 0))
            if line then
                rows[#rows + 1] = { profile = "POWER", text = line }
            end
        end
    end

    return rows
end

NS.app.RowFormatter = RowFormatter
