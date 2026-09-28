require("tests.support.load").load()
local NS = VehiclePerformance
local VehicleAnalyzer = NS.core.VehicleAnalyzer

local BASE_DIFFS = {
    { diffIndex1 = 1, diffIndex1IsWheel = true, diffIndex2 = 2, diffIndex2IsWheel = true },
}
local BASE_WHEELS = {
    { restLoad = 2.5, fieldFriction = 0.9, frictionScale = 1.5 },
    { restLoad = 2.5, fieldFriction = 0.9, frictionScale = 1.5 },
}
-- Torque constante = 1 kN.m entre 1000 e 2000 rpm (peakTorqueKnm = 1).
local FLAT_CURVE = { { rpm = 1000, torque = 1 }, { rpm = 2000, torque = 1 } }

describe("TractionMetric (F8/F10)", function()
    it("tractionLimit = adhesion quando F_ad < F_mot", function()
        -- F_mot = peakTorque*maxRatio = 1*100 = 100; F_ad = 9.81*1.35*5 = ~66.2
        local data = VehicleAnalyzer.analyze({
            schema = 1,
            mass = { totalT = 5 },
            motor = { maxForwardGearRatio = 100, torqueCurve = FLAT_CURVE },
            differentials = BASE_DIFFS,
            wheels = BASE_WHEELS,
        }, {})
        local traction = data:get("tractionForceKn")
        assert.are.equal("ok", traction.status)
        assert.are.equal("adhesion", data:get("tractionLimit").value)
        assert.is_true(traction.value < 100)
    end)

    it("tractionLimit = motor quando F_mot < F_ad", function()
        local data = VehicleAnalyzer.analyze({
            schema = 1,
            mass = { totalT = 5 },
            motor = { maxForwardGearRatio = 5, torqueCurve = FLAT_CURVE },
            differentials = BASE_DIFFS,
            wheels = BASE_WHEELS,
        }, {})
        assert.are.equal("motor", data:get("tractionLimit").value)
    end)

    it("com só F8 disponível, tractionLimit fica partial", function()
        -- Sem diferenciais válidos: F9 unknown; F8 continua calculável.
        local data = VehicleAnalyzer.analyze({
            schema = 1,
            mass = { totalT = 5 },
            motor = { maxForwardGearRatio = 100, torqueCurve = FLAT_CURVE },
            differentials = {},
            wheels = BASE_WHEELS,
        }, {})
        assert.are.equal("ok", data:get("tractionForceKn").status)
        assert.are.equal("partial", data:get("tractionLimit").value)
        assert.are.equal(100, data:get("tractionForceKn").value)
    end)

    it("com só F9 disponível, tractionLimit fica partial", function()
        -- Sem ratio válido: F8 unknown; F9 continua calculável.
        local data = VehicleAnalyzer.analyze({
            schema = 1,
            mass = { totalT = 5 },
            motor = { torqueCurve = FLAT_CURVE },
            differentials = BASE_DIFFS,
            wheels = BASE_WHEELS,
        }, {})
        assert.are.equal("ok", data:get("tractionForceKn").status)
        assert.are.equal("partial", data:get("tractionLimit").value)
    end)

    it("soma restLoad = 0 dá unknown em F9 e volta a traction so com F8 (partial)", function()
        local data = VehicleAnalyzer.analyze({
            schema = 1,
            mass = { totalT = 5 },
            motor = { maxForwardGearRatio = 100, torqueCurve = FLAT_CURVE },
            differentials = BASE_DIFFS,
            wheels = {
                { restLoad = 0, fieldFriction = 0.9, frictionScale = 1.5 },
                { restLoad = 0, fieldFriction = 0.9, frictionScale = 1.5 },
            },
        }, {})
        assert.are.equal("unknown", data:get("adhesionForceKn").status)
        assert.are.equal("partial", data:get("tractionLimit").value)
    end)
end)
