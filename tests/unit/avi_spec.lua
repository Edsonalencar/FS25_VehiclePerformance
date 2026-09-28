-- Fase 5: adapters/AdditionalVehicleInfoAdapter.lua. Só detecta o Additional
-- Vehicle Info (AVI) para diagnóstico (`vpStatus`); nunca instala hooks nem
-- toca a loja (ADR-0006, requisitos §11).
require("tests.support.load").load({ adapters = true })
local NS = VehiclePerformance

local GLOBALS = { "g_modIsLoaded", "g_modManager" }

local function setGlobal(name, value)
    rawset(_G, name, value)
end

local function clearGlobals()
    for _, name in ipairs(GLOBALS) do
        rawset(_G, name, nil)
    end
end

describe("AdditionalVehicleInfoAdapter", function()
    local logger

    before_each(function()
        logger = require("tests.stubs.MemoryLogger").new()
        clearGlobals()
    end)

    after_each(clearGlobals)

    it("ausente: g_modIsLoaded sem a chave do AVI", function()
        setGlobal("g_modIsLoaded", { ["outro_mod_qualquer"] = true })

        local status = NS.adapters.AdditionalVehicleInfoAdapter.detect(logger)

        assert.is_false(status.present)
        assert.is_nil(status.version)
        assert.are.equal("coexist", status.integration)
        assert.is_true(logger:countLevel("info") > 0)
    end)

    it("ausente: g_modIsLoaded inexistente (nil)", function()
        local status = NS.adapters.AdditionalVehicleInfoAdapter.detect(logger)

        assert.is_false(status.present)
        assert.are.equal("coexist", status.integration)
    end)

    it("presente: g_modIsLoaded com a chave exata (minúscula) e versão via g_modManager", function()
        setGlobal("g_modIsLoaded", { ["FS25_additionalVehicleInfo"] = true })
        setGlobal("g_modManager", {
            getModByName = function(_, name)
                if name == "FS25_additionalVehicleInfo" then
                    return { version = "1.0.0.0" }
                end
                return nil
            end,
        })

        local status = NS.adapters.AdditionalVehicleInfoAdapter.detect(logger)

        assert.is_true(status.present)
        assert.are.equal("1.0.0.0", status.version)
        assert.are.equal("coexist", status.integration)
    end)

    it("presente, mas sem g_modManager: version fica nil, integration continua coexist", function()
        setGlobal("g_modIsLoaded", { ["FS25_additionalVehicleInfo"] = true })

        local status = NS.adapters.AdditionalVehicleInfoAdapter.detect(logger)

        assert.is_true(status.present)
        assert.is_nil(status.version)
        assert.are.equal("coexist", status.integration)
    end)

    it("erro dentro do g_modManager: integration=error, sem lançar erro para o chamador", function()
        setGlobal("g_modIsLoaded", { ["FS25_additionalVehicleInfo"] = true })
        setGlobal("g_modManager", {
            getModByName = function()
                error("falha simulada no g_modManager")
            end,
        })

        local ok, status = pcall(NS.adapters.AdditionalVehicleInfoAdapter.detect, logger)

        assert.is_true(ok)
        assert.are.equal("error", status.integration)
    end)

    it("não registra nenhum hook (só lê estado, não instala nada)", function()
        NS.adapters.HookRegistry.hooks = {}
        local originalAdd = NS.adapters.HookRegistry.add
        local addCalls = 0
        NS.adapters.HookRegistry.add = function(...)
            addCalls = addCalls + 1
            return originalAdd(...)
        end

        setGlobal("g_modIsLoaded", { ["FS25_additionalVehicleInfo"] = true })
        setGlobal("g_modManager", {
            getModByName = function()
                return { version = "1.0.0.0" }
            end,
        })
        NS.adapters.AdditionalVehicleInfoAdapter.detect(logger)

        NS.adapters.HookRegistry.add = originalAdd
        assert.are.equal(0, addCalls)
        assert.are.same({}, NS.adapters.HookRegistry.hooks)
    end)
end)
