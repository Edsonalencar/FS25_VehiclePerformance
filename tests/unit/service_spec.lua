-- Testa PerformanceService: hit/miss, mudança de chave, FIFO e clear().
-- NS.app.ConfigurationResolver (Fase 3) ainda não existe neste worktree, por
-- isso o teste injeta um dublê mínimo cuja chave é só o campo `id` do
-- snapshot fake usado aqui.
require("tests.support.load").load()
local NS = VehiclePerformance

NS.app.ConfigurationResolver = {
    key = function(snapshot)
        return snapshot.id
    end,
}

local function fakeSettings()
    local values = { ["metrics#loadRefWeightFraction"] = 0.5, ["metrics#pullingRefKN"] = 50 }
    return {
        get = function(_, key)
            return values[key]
        end,
    }
end

describe("PerformanceService", function()
    local logger, analyzeCalls, analyze

    before_each(function()
        logger = require("tests.stubs.MemoryLogger").new()
        analyzeCalls = 0
        analyze = function(snapshot, opts)
            analyzeCalls = analyzeCalls + 1
            return { id = snapshot.id, opts = opts, availability = { missing = {} } }
        end
    end)

    it("miss roda analyze e cacheia; hit repete sem rodar analyze de novo", function()
        local service = NS.app.PerformanceService.new({ analyze = analyze, settings = fakeSettings(), logger = logger })
        local snapshot = { id = "a" }

        local first = service:get(snapshot)
        local second = service:get(snapshot)

        assert.are.equal(1, analyzeCalls)
        assert.are.equal(1, service.hits)
        assert.are.equal(first, second)
    end)

    it("a chave muda quando muda uma configuração no snapshot", function()
        local service = NS.app.PerformanceService.new({ analyze = analyze, settings = fakeSettings(), logger = logger })

        service:get({ id = "config-a" })
        service:get({ id = "config-b" })

        assert.are.equal(2, analyzeCalls)
        assert.are.equal(0, service.hits)
    end)

    it("FIFO com maxEntries=2 remove a entrada mais antiga", function()
        local service = NS.app.PerformanceService.new({
            analyze = analyze,
            settings = fakeSettings(),
            logger = logger,
            maxEntries = 2,
        })

        service:get({ id = "a" })
        service:get({ id = "b" })
        service:get({ id = "c" }) -- excede maxEntries: expulsa "a"
        assert.are.equal(3, analyzeCalls)

        -- "a" foi expulsa: pedir de novo é miss (reanalisa).
        service:get({ id = "a" })
        assert.are.equal(4, analyzeCalls)

        -- "c" ainda está no cache: hit.
        service:get({ id = "c" })
        assert.are.equal(4, analyzeCalls)
        assert.are.equal(1, service.hits)
    end)

    it("clear() zera cache, ordem e hits", function()
        local service = NS.app.PerformanceService.new({ analyze = analyze, settings = fakeSettings(), logger = logger })

        service:get({ id = "a" })
        service:get({ id = "a" })
        assert.are.equal(1, service.hits)

        service:clear()
        assert.are.equal(0, service.hits)
        assert.are.equal(0, #service.order)

        service:get({ id = "a" })
        assert.are.equal(2, analyzeCalls) -- 1 antes do clear + 1 depois (cache vazio)
    end)
end)
