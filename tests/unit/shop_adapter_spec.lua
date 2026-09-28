-- Testa ShopConfigAdapter com stubs mínimos de ShopConfigScreen/Utils, no
-- padrão de tests/unit/bootstrap_spec.lua (rawset de globais do jogo). Usa
-- reader/service/formatter dublês locais: não depende dos arquivos reais das
-- Fases 2/3 (RuntimeVehicleReader, VehicleAnalyzer etc.), só do contrato
-- reader.read(vehicle, storeItem, logger) e service:get(snapshot).
-- luacheck: globals ShopConfigScreen
local function setGlobal(name, value)
    rawset(_G, name, value)
end

local function clearGlobals()
    setGlobal("Utils", nil)
    setGlobal("ShopConfigScreen", nil)
end

local GUI_PROFILE = { WHEELS = "p1", POWER = "p2", WEIGHT = "p3", TRANSMISSION = "p4", MAX_SPEED = "p5" }

local function setUtilsStub()
    -- Recriado a cada before_each: outros specs (bootstrap_spec.lua) também
    -- usam e limpam o global compartilhado _G.Utils entre seus próprios
    -- testes, então não dá para confiar num único rawset feito aqui no
    -- carregamento do arquivo.
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
end

setUtilsStub()
setGlobal("ShopConfigScreen", {
    registerCustomSpecValues = function() end,
    GUI_PROFILE = GUI_PROFILE,
    storeItem = {},
})

require("tests.support.load").load({ adapters = true })
local NS = VehiclePerformance

local function fakeSettings(overrides)
    local values = { ["ui#enabled"] = true, ["ui#showPullingIndex"] = false }
    for k, v in pairs(overrides or {}) do
        values[k] = v
    end
    return {
        get = function(_, key)
            return values[key]
        end,
    }
end

describe("ShopConfigAdapter", function()
    local adapter, values, vehicle, logger

    before_each(function()
        -- Reseta o alvo do hook a cada teste: senão o wrapper de Utils.appendedFunction
        -- acumularia os corpos instalados por testes anteriores.
        setUtilsStub()
        setGlobal("ShopConfigScreen", {
            registerCustomSpecValues = function() end,
            GUI_PROFILE = GUI_PROFILE,
            storeItem = {},
        })
        NS.adapters.HookRegistry.hooks = {}
        NS.adapters.HookRegistry.enabled = true

        logger = require("tests.stubs.MemoryLogger").new()
        NS.app.logger = logger
        NS.app.state = NS.app.StateMachine.new(logger)

        values = {}
        vehicle = { spec_motorized = {} }

        local reader = {
            read = function(v, storeItem, log) -- luacheck: ignore 212
                return { vehicle = v, storeItem = storeItem }
            end,
        }
        local service = {
            get = function(_, snapshot)
                return { snapshot = snapshot }
            end,
        }
        local formatter = {
            rows = function(_, _, _)
                return {
                    { profile = "WHEELS", text = "linha-tracao" },
                    { profile = "POWER", text = "linha-potencia" },
                }
            end,
        }

        adapter = NS.adapters.ShopConfigAdapter.new({
            reader = reader,
            service = service,
            formatter = formatter,
            text = {},
            settings = fakeSettings(),
            logger = logger,
            state = NS.app.state,
        })
        assert.is_true(adapter:install())
    end)

    after_each(clearGlobals)

    local function callHook()
        ShopConfigScreen.registerCustomSpecValues(ShopConfigScreen, values, nil, vehicle, nil)
    end

    it("veículo motorizado com values={} insere as linhas formatadas", function()
        callHook()
        assert.are.equal(2, #values)
        assert.are.equal("p1", values[1].profile)
        assert.are.equal("linha-tracao", values[1].value)
        assert.are.equal("p2", values[2].profile)
        assert.are.equal("linha-potencia", values[2].value)
    end)

    it("com spec_motorized=nil não insere nada", function()
        vehicle.spec_motorized = nil
        callHook()
        assert.are.equal(0, #values)
    end)

    it("com ui#enabled=false nada é inserido", function()
        adapter.settings = fakeSettings({ ["ui#enabled"] = false })
        callHook()
        assert.are.equal(0, #values)
    end)

    it("reader que sempre lança erro desativa o hook após 3 chamadas, sem erro escapando", function()
        adapter.reader = {
            read = function()
                error("falha proposital de leitura")
            end,
        }

        for _ = 1, 3 do
            assert.has_no.errors(callHook)
        end

        assert.are.equal(0, #values)
        assert.is_false(NS.adapters.HookRegistry.hooks["ShopConfigScreen.registerCustomSpecValues"].active)
        assert.are.equal(3, logger:countLevel("error"))

        -- uma 4ª chamada não deve sequer tentar rodar o corpo (hook inativo).
        callHook()
        assert.are.equal(0, #values)
    end)
end)
