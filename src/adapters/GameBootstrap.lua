-- Instala o mod no ciclo de vida do jogo (addModEventListener) e cria os
-- objetos de app/adapters de nível superior (logger, state, settings).
local NS = VehiclePerformance
local GameBootstrap = {}

-- Adapter fino da porta ConsoleRegistrar (app/Console.lua, Fase 3): traduz
-- add/remove para addConsoleCommand/removeConsoleCommand. Ainda não é usado
-- nesta fase (entra em uso na Fase 3, junto com app/Console.lua).
-- luacheck: ignore 241
local ConsoleRegistrar = {}
ConsoleRegistrar.__index = ConsoleRegistrar

function ConsoleRegistrar.new()
    return setmetatable({}, ConsoleRegistrar)
end

function ConsoleRegistrar:add(name, helpText, fn)
    self[name] = function(_, ...)
        return fn(...)
    end
    if type(addConsoleCommand) == "function" then
        addConsoleCommand(name, helpText, name, self)
    end
end

function ConsoleRegistrar:remove(name)
    self[name] = nil
    if type(removeConsoleCommand) == "function" then
        removeConsoleCommand(name)
    end
end

local listener = {}

function listener:loadMap() -- luacheck: ignore 212/self
    NS.app.SafeCall.run("bootstrap:loadMap", function()
        if g_dedicatedServer ~= nil then
            NS.app.state:set("disabled-dedicated")
            return
        end
        NS.app.settings:loadSettings()
        NS.app.logger:setLevel(NS.app.settings:get("debug#logLevel"))
        -- Fase 4: shopConfigAdapter:install(); Fase 3/5: Console.install(...)
        NS.app.state:set("ready")
        NS.app.logger:info("bootstrap", "v%s carregado", NS.VERSION)
    end)
end

function listener:deleteMap() -- luacheck: ignore 212/self
    NS.app.SafeCall.run("bootstrap:deleteMap", function()
        NS.adapters.HookRegistry.uninstall()
        NS.app.state:set("unloaded")
    end)
end

function GameBootstrap.install(namespace)
    namespace.app.settings = namespace.adapters.SettingsStore.new()
    namespace.app.logger = namespace.adapters.GameLogger.new(namespace.app.settings)
    namespace.app.state = namespace.app.StateMachine.new(namespace.app.logger)

    addModEventListener(listener)
end

NS.adapters.GameBootstrap = GameBootstrap
