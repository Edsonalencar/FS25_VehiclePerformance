-- Invariantes relativos do spec (§Fórmulas, linha 139-143), testados sobre os
-- fixtures manuais e (nas fases seguintes) sobre os dumps reais.
require("tests.support.load").load()
local NS = VehiclePerformance
local VehicleAnalyzer = NS.core.VehicleAnalyzer

local function analyze(name)
    local snapshot = dofile("tests/fixtures/manual/" .. name .. ".lua")
    return VehicleAnalyzer.analyze(snapshot, {})
end

describe("Invariantes relativos", function()
    it("valtra_205 > valtra_145 em potência, F_tração e índice", function()
        local v145 = analyze("valtra_145_michelin")
        local v205 = analyze("valtra_205_michelin")
        assert.is_true(v205:get("peakPowerKw").value > v145:get("peakPowerKw").value)
        assert.is_true(v205:get("tractionForceKn").value > v145:get("tractionForceKn").value)
        assert.is_true(v205:get("pullingIndex").value > v145:get("pullingIndex").value)
    end)

    it("volvo_6x4 > volvo_6x2 em F_tração", function()
        local v6x2 = analyze("volvo_6x2_ferro")
        local v6x4 = analyze("volvo_6x4_alcoa")
        assert.is_true(v6x4:get("tractionForceKn").value > v6x2:get("tractionForceKn").value)
    end)

    it("valtra_145 (4x4) > valtra_145_4x2 em F_tração", function()
        local v4x4 = analyze("valtra_145_michelin")
        local v4x2 = analyze("valtra_145_4x2")
        assert.is_true(v4x4:get("tractionForceKn").value > v4x2:get("tractionForceKn").value)
    end)

    it("ford_manual_dual_ballast > ford_auto_largo em massT e F_ad", function()
        local auto = analyze("ford_auto_largo")
        local manual = analyze("ford_manual_dual_ballast")
        assert.is_true(manual:get("massT").value > auto:get("massT").value)
        assert.is_true(manual:get("adhesionForceKn").value > auto:get("adhesionForceKn").value)
    end)
end)
