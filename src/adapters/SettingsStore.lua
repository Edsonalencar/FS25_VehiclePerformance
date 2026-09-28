-- Lê/grava modSettings/FS25_VehiclePerformance/settings.xml (nunca no
-- savegame, nunca dentro do pacote). Chaves com valores padrão; grava só
-- quando o usuário altera.
local NS = VehiclePerformance
local SettingsStore = {}
SettingsStore.__index = SettingsStore

local DEFAULTS = {
    ["debug#enabled"] = false,
    ["debug#logLevel"] = "info",
    -- Injeção de falha manual para o smoke de degradação: "reader" | "hook"
    -- (só com debug#enabled).
    ["debug#simulateFailure"] = "",
    ["ui#enabled"] = true,
    ["ui#showPullingIndex"] = false,
    ["metrics#pullingRefKN"] = 50,
    ["metrics#loadRefWeightFraction"] = 0.5,
}

local FILE_KEY = "VehiclePerformanceSettings"

-- "debug#enabled" → "settings.debug#enabled" (caminho elemento#atributo do
-- XMLFile). Não gsub("#", ".#"), que geraria "settings.debug.#enabled".
local function xmlKeyOf(key)
    return "settings." .. key
end

local function relPath()
    return (g_modSettingsDirectory or "") .. "FS25_VehiclePerformance/settings.xml"
end

function SettingsStore.new()
    return setmetatable({ values = {}, loaded = false }, SettingsStore)
end

function SettingsStore:loadSettings()
    self.loaded = true
    if type(XMLFile) ~= "table" or type(XMLFile.loadIfExists) ~= "function" then
        return
    end
    local path = relPath()
    local xmlFile = XMLFile.loadIfExists(FILE_KEY, path)
    if not xmlFile then
        return
    end
    for key in pairs(DEFAULTS) do
        local xmlKey = xmlKeyOf(key)
        local default = DEFAULTS[key]
        if type(default) == "boolean" then
            local v = xmlFile:getBool(xmlKey, default)
            self.values[key] = v
        elseif type(default) == "number" then
            local v = xmlFile:getFloat(xmlKey, default)
            self.values[key] = v
        else
            local v = xmlFile:getString(xmlKey, default)
            self.values[key] = v
        end
    end
    if type(xmlFile.delete) == "function" then
        xmlFile:delete()
    end
end

function SettingsStore:get(key, default)
    if self.values[key] ~= nil then
        return self.values[key]
    end
    if default ~= nil then
        return default
    end
    return DEFAULTS[key]
end

function SettingsStore:set(key, value)
    self.values[key] = value
    self:save()
end

function SettingsStore:save()
    if type(XMLFile) ~= "table" or type(XMLFile.create) ~= "function" then
        return
    end
    local path = relPath()
    local xmlFile = XMLFile.create(FILE_KEY, path, "settings")
    if not xmlFile then
        return
    end
    for key, default in pairs(DEFAULTS) do
        local value = self:get(key)
        local xmlKey = xmlKeyOf(key)
        if type(default) == "boolean" then
            xmlFile:setBool(xmlKey, value)
        elseif type(default) == "number" then
            xmlFile:setFloat(xmlKey, value)
        else
            xmlFile:setString(xmlKey, value)
        end
    end
    if type(xmlFile.save) == "function" then
        xmlFile:save()
    end
    if type(xmlFile.delete) == "function" then
        xmlFile:delete()
    end
end

NS.adapters.SettingsStore = SettingsStore
