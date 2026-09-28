-- Comandos de console (vpStatus/vpDump/vpAnalyze/vpSet), registrados via uma
-- porta `registrar` injetada (:add(name, helpText, fn) / :remove(name); ver
-- ConsoleRegistrar em adapters/GameBootstrap.lua). app/ não pode usar g_* nem
-- XMLFile: todo acesso ao jogo chega aqui já resolvido em `deps`
-- (previewSource, reader, writer, analyze, hookStatus, settings, logger).
local NS = VehiclePerformance
local Console = {}

local COMMAND_NAMES = { "vpStatus", "vpDump", "vpAnalyze", "vpSet" }

local SET_KEYS = {
    showIndex = "ui#showPullingIndex",
    logLevel = "debug#logLevel",
    pullingRef = "metrics#pullingRefKN",
}

local function previewList(deps)
    if deps.previewSource and type(deps.previewSource.list) == "function" then
        return deps.previewSource.list()
    end
    return {}
end

local function vpStatus(deps)
    local lines = {}
    lines[#lines + 1] = string.format("VehiclePerformance v%s", tostring(NS.VERSION))
    lines[#lines + 1] = string.format("estado: %s", NS.app.state and tostring(NS.app.state.current) or "?")

    local hooks = type(deps.hookStatus) == "function" and deps.hookStatus() or {}
    if #hooks == 0 then
        lines[#lines + 1] = "hooks: nenhum registrado"
    else
        for _, h in ipairs(hooks) do
            lines[#lines + 1] =
                string.format("hook %s: %s (falhas=%d)", h.id, h.active and "ativo" or "inativo", h.failures or 0)
        end
    end
    -- Fase 4/5: cache e status do Additional Vehicle Info entram aqui.

    local msg = table.concat(lines, "\n")
    if deps.logger then
        deps.logger:info("console", "%s", msg)
    end
    return msg
end

local function vpDump(deps)
    local list = previewList(deps)
    if #list == 0 then
        return "vpDump: abra a tela de configuração de um veículo"
    end

    local paths = {}
    for _, item in ipairs(list) do
        local ok, pathOrErr = pcall(function()
            local snapshot = deps.reader.read(item.vehicle, item.storeItem, deps.logger)
            return deps.writer.write(snapshot, deps.logger)
        end)
        if ok and pathOrErr then
            paths[#paths + 1] = pathOrErr
        elseif not ok and deps.logger then
            deps.logger:error("console", "vpDump: %s", tostring(pathOrErr))
        end
    end

    if #paths == 0 then
        return "vpDump: nenhum snapshot gravado (ver log DEBUG)"
    end
    return "vpDump:\n" .. table.concat(paths, "\n")
end

local function formatMetric(id, metric)
    if type(metric) ~= "table" then
        return string.format("%s = %s", id, tostring(metric))
    end
    return string.format(
        "%s = %s %s [%s/%s]",
        id,
        tostring(metric.value),
        tostring(metric.unit or ""),
        tostring(metric.kind or "?"),
        tostring(metric.status or "?")
    )
end

local function vpAnalyze(deps)
    local list = previewList(deps)
    if #list == 0 then
        return "vpAnalyze: abra a tela de configuração de um veículo"
    end
    if type(deps.analyze) ~= "function" then
        return "vpAnalyze: núcleo de análise indisponível"
    end

    local lines = {}
    for _, item in ipairs(list) do
        local ok, dataOrErr = pcall(function()
            local snapshot = deps.reader.read(item.vehicle, item.storeItem, deps.logger)
            local options = {
                loadRefWeightFraction = deps.settings and deps.settings:get("metrics#loadRefWeightFraction"),
                pullingRefKN = deps.settings and deps.settings:get("metrics#pullingRefKN"),
            }
            return deps.analyze(snapshot, options)
        end)
        if ok and dataOrErr and dataOrErr.metrics then
            local ids = {}
            for id in pairs(dataOrErr.metrics) do
                ids[#ids + 1] = id
            end
            table.sort(ids)
            for _, id in ipairs(ids) do
                lines[#lines + 1] = formatMetric(id, dataOrErr.metrics[id])
            end
        elseif not ok and deps.logger then
            deps.logger:error("console", "vpAnalyze: %s", tostring(dataOrErr))
        end
    end

    if #lines == 0 then
        return "vpAnalyze: sem métricas (ver log DEBUG)"
    end
    return table.concat(lines, "\n")
end

local function coerceSetValue(name, raw)
    if name == "showIndex" then
        return raw == "true" or raw == "1"
    elseif name == "pullingRef" then
        return tonumber(raw)
    end
    return raw
end

local function vpSet(deps, name, raw)
    local key = SET_KEYS[name]
    if not key or raw == nil then
        return "vpSet: uso: vpSet <showIndex|logLevel|pullingRef> <valor>"
    end
    local value = coerceSetValue(name, raw)
    if value == nil then
        return "vpSet: valor inválido para " .. tostring(name)
    end
    if not deps.settings then
        return "vpSet: settings indisponível"
    end
    deps.settings:set(key, value)
    if name == "logLevel" and deps.logger and type(deps.logger.setLevel) == "function" then
        deps.logger:setLevel(value)
    end
    return string.format("vpSet: %s = %s", key, tostring(value))
end

--- Registra vpStatus/vpDump/vpAnalyze/vpSet em `registrar` (porta
--- ConsoleRegistrar), usando `deps` para tudo que precisa tocar o jogo.
function Console.install(registrar, deps)
    Console.uninstall()
    deps = deps or {}

    registrar:add("vpStatus", "Mostra o estado do VehiclePerformance", function()
        return vpStatus(deps)
    end)
    registrar:add("vpDump", "Grava um dump XML por veículo de preview da loja", function()
        return vpDump(deps)
    end)
    registrar:add("vpAnalyze", "Mostra as métricas calculadas do(s) veículo(s) de preview", function()
        return vpAnalyze(deps)
    end)
    registrar:add("vpSet", "vpSet <showIndex|logLevel|pullingRef> <valor>", function(name, raw)
        return vpSet(deps, name, raw)
    end)

    Console._registrar = registrar
    Console._names = COMMAND_NAMES
end

--- Remove os comandos registrados por install (idempotente).
function Console.uninstall()
    if Console._registrar then
        for _, name in ipairs(Console._names or {}) do
            Console._registrar:remove(name)
        end
    end
    Console._registrar = nil
    Console._names = nil
end

NS.app.Console = Console
