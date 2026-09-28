-- Fase 5: endurecimento/degradação segura (requisitos §11.4, §12).
--
-- Nas Fases 2/3/4 (em paralelo, em outros worktrees) o hook real de leitura
-- vive em `adapters/ShopConfigAdapter.lua`, que aqui pode não existir ainda.
-- Por isso este spec simula um hook genérico equivalente via HookRegistry,
-- reaproveitando o padrão já validado em tests/unit/bootstrap_spec.lua (que
-- cobre HookRegistry e SafeCall isoladamente): um alvo com um método vanilla
-- e um "mod" (nosso hook) que falha de propósito quando
-- `debug#simulateFailure` bate com o cenário testado e `debug#enabled` está
-- ligado — exatamente a chave que `SettingsStore` já reserva para isso.
require("tests.support.load").load({ adapters = true })
local NS = VehiclePerformance

local function setGlobal(name, value)
    rawset(_G, name, value)
end

local function clearGlobals()
    rawset(_G, "Utils", nil)
end

-- Instala um hook "append" cujo corpo falha de propósito quando
-- settings#debug#enabled=true e settings#debug#simulateFailure==failureId.
-- O alvo simula `ShopConfigScreen:registerCustomSpecValues(self, values)`:
-- o método original (vanilla) sempre acrescenta uma linha; o nosso hook só
-- acrescentaria uma linha própria se não tivesse falhado antes.
local function installFakeHook(settings, failureId)
    local target = {
        registerCustomSpecValues = function(_, values)
            values[#values + 1] = "linha-vanilla"
        end,
    }
    NS.adapters.HookRegistry.add({
        id = "teste:resilience:" .. failureId,
        target = target,
        method = "registerCustomSpecValues",
        kind = "append",
        fn = function(_, values)
            local enabled = settings:get("debug#enabled")
            local simulateFailure = settings:get("debug#simulateFailure")
            if enabled and simulateFailure == failureId then
                error("falha simulada: " .. failureId)
            end
            values[#values + 1] = "linha-" .. failureId
        end,
    })
    return target
end

describe("Resiliência (Fase 5) — hook genérico via HookRegistry", function()
    local logger, state, settings

    before_each(function()
        logger = require("tests.stubs.MemoryLogger").new()
        state = NS.app.StateMachine.new(logger)
        NS.app.logger = logger
        NS.app.state = state
        NS.adapters.HookRegistry.hooks = {}
        NS.adapters.HookRegistry.enabled = true
        settings = NS.adapters.SettingsStore.new()
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

    after_each(clearGlobals)

    for _, failureId in ipairs({ "reader", "hook" }) do
        it(
            'simulateFailure="' .. failureId .. '": 3 aberturas desativam o hook e "values" só tem linhas vanilla',
            function()
                settings.values["debug#enabled"] = true
                settings.values["debug#simulateFailure"] = failureId
                local target = installFakeHook(settings, failureId)

                local values
                for _ = 1, 3 do
                    values = {}
                    target:registerCustomSpecValues(values)
                end

                assert.is_false(NS.adapters.HookRegistry.hooks["teste:resilience:" .. failureId].active)
                assert.are.same({ "linha-vanilla" }, values)
                assert.are.equal(3, logger:countLevel("error"))
            end
        )
    end

    it("uma 4ª abertura depois da desativação continua só com a linha vanilla, sem novo erro", function()
        settings.values["debug#enabled"] = true
        settings.values["debug#simulateFailure"] = "reader"
        local target = installFakeHook(settings, "reader")

        for _ = 1, 3 do
            target:registerCustomSpecValues({})
        end
        local errorsAfterDeactivation = logger:countLevel("error")

        local values = {}
        target:registerCustomSpecValues(values)

        assert.are.same({ "linha-vanilla" }, values)
        assert.are.equal(errorsAfterDeactivation, logger:countLevel("error"))
    end)

    it("sem debug#enabled, o mesmo simulateFailure não falha (linha própria aparece)", function()
        settings.values["debug#enabled"] = false
        settings.values["debug#simulateFailure"] = "reader"
        local target = installFakeHook(settings, "reader")

        local values = {}
        target:registerCustomSpecValues(values)

        assert.are.same({ "linha-vanilla", "linha-reader" }, values)
        assert.is_true(NS.adapters.HookRegistry.hooks["teste:resilience:reader"].active)
    end)

    it("StateMachine não sai de degraded uma vez lá", function()
        state:set("ready")
        state:degrade("motivo-1")
        assert.is_true(state:is("degraded"))

        -- Uma 2ª degradação não deve emitir novo log de erro (early-return).
        state:degrade("motivo-2")
        assert.are.equal(1, logger:countLevel("error"))

        -- Nenhuma transição para fora de "degraded" é aceita.
        assert.is_false(state:set("ready"))
        assert.is_false(state:set("loaded"))
        assert.is_true(state:is("degraded"))
    end)

    it('SafeCall no equivalente a "loadMap" com erro degrada sem propagar', function()
        NS.app.SafeCall.failures = {}
        local results = {}

        local ok = pcall(function()
            for i = 1, 3 do
                results[i] = NS.app.SafeCall.run("teste:loadMap-equivalente", function()
                    error("falha simulada no bootstrap")
                end)
            end
        end)

        assert.is_true(ok) -- o erro nunca escapou de SafeCall.run
        assert.is_nil(results[1])
        assert.is_nil(results[2])
        assert.is_nil(results[3])
        assert.is_true(state:is("degraded"))
    end)
end)
