-- Instala o mod no ciclo de vida do jogo (addModEventListener) e cria os
-- objetos de app/adapters de nível superior (logger, state, settings).
local NS = VehiclePerformance
local GameBootstrap = {}

-- Adapter fino da porta ConsoleRegistrar (app/Console.lua, Fase 3): traduz
-- add/remove para addConsoleCommand/removeConsoleCommand.
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

        NS.adapters.reader = NS.adapters.RuntimeVehicleReader
        NS.app.aviStatus = NS.adapters.AdditionalVehicleInfoAdapter.detect(NS.app.logger)
        NS.app.performanceService = NS.app.PerformanceService.new({
            analyze = NS.core.VehicleAnalyzer.analyze,
            settings = NS.app.settings,
            logger = NS.app.logger,
        })

        NS.app.consoleRegistrar = NS.app.consoleRegistrar or ConsoleRegistrar.new()
        NS.app.Console.install(NS.app.consoleRegistrar, {
            hookStatus = NS.adapters.HookRegistry.status,
            previewSource = NS.adapters.PreviewSource,
            reader = NS.adapters.RuntimeVehicleReader,
            writer = NS.adapters.SnapshotXmlWriter,
            analyze = NS.core.VehicleAnalyzer.analyze,
            service = NS.app.performanceService,
            aviStatus = NS.app.aviStatus,
            settings = NS.app.settings,
            logger = NS.app.logger,
        })

        NS.adapters.shopConfigAdapter = NS.adapters.ShopConfigAdapter.new({
            reader = NS.adapters.RuntimeVehicleReader,
            service = NS.app.performanceService,
            formatter = NS.app.RowFormatter,
            text = NS.adapters.GameText,
            settings = NS.app.settings,
            logger = NS.app.logger,
            state = NS.app.state,
        })
        if not NS.adapters.shopConfigAdapter:install() then
            NS.app.logger:warning("bootstrap", "ShopConfigScreen.registerCustomSpecValues indisponível; UI desativada")
        end

        NS.app.PublicApi.install(NS, {
            reader = NS.adapters.RuntimeVehicleReader,
            service = NS.app.performanceService,
            storeItemOf = NS.adapters.PreviewSource.storeItemOf,
            logger = NS.app.logger,
        })
        -- Outros mods rodam em env próprio: o global compartilhado vai no env raiz.
        if type(getfenv) == "function" then
            getfenv(0).g_vehiclePerformanceApi = NS.api
        end

        NS.app.state:set("ready")
        NS.app.logger:info("bootstrap", "v%s carregado", NS.VERSION)
    end)
end

function listener:deleteMap() -- luacheck: ignore 212/self
    NS.app.SafeCall.run("bootstrap:deleteMap", function()
        NS.adapters.HookRegistry.uninstall()
        NS.app.Console.uninstall()
        if NS.app.performanceService then
            NS.app.performanceService:clear()
        end
        if type(getfenv) == "function" then
            getfenv(0).g_vehiclePerformanceApi = nil
        end
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
