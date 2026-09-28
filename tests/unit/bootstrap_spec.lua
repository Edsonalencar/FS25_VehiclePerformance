-- Adapters com stubs mínimos dos globais do FS25. Não valida a API real do
-- jogo: só a lógica própria dos adapters em torno dela.
require("tests.support.load").load({ adapters = true })
local NS = VehiclePerformance

local GLOBALS = { "addModEventListener", "addConsoleCommand", "removeConsoleCommand", "g_dedicatedServer", "XMLFile" }

local function setGlobal(name, value)
    rawset(_G, name, value)
end

local function clearGlobals()
    for _, name in ipairs(GLOBALS) do
        rawset(_G, name, nil)
    end
end

-- tests/support/load.lua exclui adapters/GameBootstrap.lua de propósito (ele
-- só é seguro de carregar com os globais do jogo já presentes/stubados), então
-- este spec o carrega separadamente, como o adapters_spec.lua do SSS faz para
-- casos equivalentes.
setGlobal("addModEventListener", function() end)
dofile("src/adapters/GameBootstrap.lua")

describe("GameBootstrap", function()
    local registeredListener

    before_each(function()
        registeredListener = nil
        setGlobal("addModEventListener", function(listener)
            registeredListener = listener
        end)
        NS.app.SafeCall.failures = {}
    end)
    after_each(clearGlobals)

    it("install registra o listener e cria settings/logger/state", function()
        NS.adapters.GameBootstrap.install(NS)
        assert.is_not_nil(registeredListener)
        assert.is_not_nil(NS.app.settings)
        assert.is_not_nil(NS.app.logger)
        assert.is_not_nil(NS.app.state)
    end)

    it("loadMap com g_dedicatedServer definido leva a disabled-dedicated", function()
        NS.adapters.GameBootstrap.install(NS)
        setGlobal("g_dedicatedServer", {})
        registeredListener:loadMap()
        assert.is_true(NS.app.state:is("disabled-dedicated"))
    end)

    it("loadMap sem dedicated server leva a ready", function()
        NS.adapters.GameBootstrap.install(NS)
        registeredListener:loadMap()
        assert.is_true(NS.app.state:is("ready"))
    end)
end)

describe("SafeCall", function()
    it("degrada o estado após 3 falhas no mesmo contexto", function()
        local logger = require("tests.stubs.MemoryLogger").new()
        NS.app.logger = logger
        NS.app.state = NS.app.StateMachine.new(logger)
        NS.app.SafeCall.failures = {}

        for _ = 1, 3 do
            NS.app.SafeCall.run("teste:contexto", function()
                error("falha proposital")
            end)
        end

        assert.is_true(NS.app.state:is("degraded"))
        -- 3 erros do próprio SafeCall.run + 1 do StateMachine:degrade na 3ª falha.
        assert.are.equal(4, logger:countLevel("error"))
    end)
end)

describe("HookRegistry", function()
    local logger, state

    before_each(function()
        logger = require("tests.stubs.MemoryLogger").new()
        state = NS.app.StateMachine.new(logger)
        NS.app.logger = logger
        NS.app.state = state
        NS.adapters.HookRegistry.hooks = {}
        NS.adapters.HookRegistry.enabled = true
        setGlobal("Utils", {
            appendedFunction = function(orig, fn)
                return function(...)
                    if orig then
                        orig(...)
                    end
                    return fn(...)
                end
            end,
        })
    end)
    after_each(function()
        clearGlobals()
        rawset(_G, "Utils", nil)
    end)

    it("add é idempotente por id", function()
        local target = { method = function() end }
        local calls = 0
        local spec = {
            id = "teste:idempotente",
            target = target,
            method = "method",
            kind = "append",
            fn = function()
                calls = calls + 1
            end,
        }
        assert.is_true(NS.adapters.HookRegistry.add(spec))
        assert.is_true(NS.adapters.HookRegistry.add(spec))
        target.method()
        assert.are.equal(1, calls)
    end)

    it("se desativa após 3 erros no corpo do hook", function()
        local target = { method = function() end }
        NS.adapters.HookRegistry.add({
            id = "teste:falhas",
            target = target,
            method = "method",
            kind = "append",
            fn = function()
                error("falha do hook")
            end,
        })
        for _ = 1, 3 do
            target.method()
        end
        assert.is_false(NS.adapters.HookRegistry.hooks["teste:falhas"].active)
        assert.are.equal(3, logger:countLevel("error"))
    end)
end)
