-- Implementa a porta `text` consumida por app/RowFormatter.lua, isolando-o
-- de g_i18n. Toda função tem guarda de tipo e nunca lança erro: sem g_i18n
-- (testes offline, tela carregada cedo demais), cai num fallback razoável.
local NS = VehiclePerformance
local GameText = {}

function GameText.get(key)
    if type(g_i18n) == "table" and type(g_i18n.getText) == "function" then
        local ok, out = pcall(g_i18n.getText, g_i18n, key)
        if ok and out ~= nil then
            return out
        end
    end
    return key
end

function GameText.number(v, precision)
    if type(g_i18n) == "table" and type(g_i18n.formatNumber) == "function" then
        local ok, out = pcall(g_i18n.formatNumber, g_i18n, v, precision)
        if ok and out ~= nil then
            return out
        end
    end
    local ok, out = pcall(string.format, "%." .. tostring(precision) .. "f", v)
    if ok then
        return out
    end
    return tostring(v)
end

function GameText.speed(kmh)
    if
        type(g_i18n) == "table"
        and type(g_i18n.getSpeed) == "function"
        and type(g_i18n.getSpeedMeasuringUnit) == "function"
    then
        local ok1, value = pcall(g_i18n.getSpeed, g_i18n, kmh)
        local ok2, unit = pcall(g_i18n.getSpeedMeasuringUnit, g_i18n)
        if ok1 and ok2 and value ~= nil and unit ~= nil then
            return value, unit
        end
    end
    return kmh, "km/h"
end

NS.adapters.GameText = GameText
