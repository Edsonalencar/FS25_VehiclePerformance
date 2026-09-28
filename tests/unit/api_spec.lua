-- Fase 5: app/PublicApi.lua. Camada pura (sem g_*/XMLFile/adapters); usa só
-- as portas injetadas em `deps`. Nunca lança erro para o chamador
-- (requisitos §15) — outro mod pode chamar isso a qualquer momento.
require("tests.support.load").load()
local NS = VehiclePerformance

describe("PublicApi", function()
    local deps, vehicle, fakeData

    before_each(function()
        fakeData = {
            values = { drivetrain = "4x2 · 1 eixo motriz" },
            get = function(self, metricId)
                return self.values[metricId]
            end,
        }
        deps = {
            logger = require("tests.stubs.MemoryLogger").new(),
            storeItemOf = function(v)
                if v == nil then
                    return nil
                end
                return { xmlFilename = v.configFileName }
            end,
            reader = {
                read = function(v, storeItem, _)
                    return { vehicle = v, storeItem = storeItem }
                end,
            },
            service = {
                get = function(_, _)
                    return fakeData
                end,
            },
        }
        vehicle = { configFileName = "fake.xml", configurations = { motor = 1, wheels = 2 } }
        NS.app.PublicApi.install(NS, deps)
    end)

    it("getPerformance(nil) devolve nil", function()
        assert.is_nil(NS.api.getPerformance(nil))
    end)

    it("um veículo falso com deps fakes devolve os dados do service", function()
        local data = NS.api.getPerformance(vehicle)
        assert.are.equal(fakeData, data)
    end)

    it("getMetric devolve o Value específico", function()
        assert.are.equal("4x2 · 1 eixo motriz", NS.api.getMetric(vehicle, "drivetrain"))
    end)

    it("getMetric com métrica ausente devolve nil sem erro", function()
        assert.is_nil(NS.api.getMetric(vehicle, "metrica_inexistente"))
    end)

    it("um reader que lança erro faz getPerformance devolver nil (nunca erro)", function()
        deps.reader.read = function()
            error("falha simulada no reader")
        end
        NS.app.PublicApi.install(NS, deps)

        local ok, data = pcall(NS.api.getPerformance, vehicle)

        assert.is_true(ok)
        assert.is_nil(data)
    end)

    it("storeItemOf que devolve nil faz getPerformance devolver nil", function()
        deps.storeItemOf = function()
            return nil
        end
        NS.app.PublicApi.install(NS, deps)

        assert.is_nil(NS.api.getPerformance(vehicle))
    end)

    it("getCurrentConfiguration devolve uma cópia rasa: mutar a cópia não altera o veículo", function()
        local config = NS.api.getCurrentConfiguration(vehicle)
        assert.are.same({ motor = 1, wheels = 2 }, config)

        config.motor = 999
        config.campoNovo = "não deveria vazar"

        assert.are.equal(1, vehicle.configurations.motor)
        assert.is_nil(vehicle.configurations.campoNovo)
    end)

    it("getCurrentConfiguration(nil) devolve tabela vazia, não erro", function()
        assert.are.same({}, NS.api.getCurrentConfiguration(nil))
    end)

    it("VERSION fica exposta como 1", function()
        assert.are.equal(1, NS.api.VERSION)
    end)
end)
