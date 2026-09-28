require("tests.support.load").load()
local NS = VehiclePerformance
local VehicleAnalyzer = NS.core.VehicleAnalyzer

local DIFFS = {
    { diffIndex1 = 1, diffIndex1IsWheel = true, diffIndex2 = 2, diffIndex2IsWheel = true },
}
local WHEELS = {
    { restLoad = 2.5, fieldFriction = 0.95, frictionScale = 1.6 },
    { restLoad = 2.5, fieldFriction = 0.95, frictionScale = 1.6 },
}

describe("LoadPerformanceMetric (F11)", function()
    it("é limitado por maxForwardSpeed", function()
        -- Potência enorme, tração enorme: sem o teto de maxForwardSpeed a
        -- velocidade sob carga explodiria.
        local data = VehicleAnalyzer.analyze({
            schema = 1,
            mass = { totalT = 2 },
            motor = {
                maxForwardGearRatio = 1000,
                maxForwardSpeedMs = 10,
                torqueCurve = { { rpm = 1000, torque = 5 }, { rpm = 2000, torque = 5 } },
            },
            differentials = DIFFS,
            wheels = WHEELS,
        }, {})
        local load = data:get("loadSpeedKmh")
        assert.are.equal("ok", load.status)
        assert.is_true(load.value <= 10 * 3.6 + 1e-6)
    end)

    it("dá insufficient quando F10 < k*m*g", function()
        -- Tração mínima (ratio muito pequeno e aderência baixa), massa grande.
        local data = VehicleAnalyzer.analyze({
            schema = 1,
            mass = { totalT = 20 },
            motor = {
                maxForwardGearRatio = 0.01,
                maxForwardSpeedMs = 30,
                torqueCurve = { { rpm = 1000, torque = 0.1 }, { rpm = 2000, torque = 0.1 } },
            },
            differentials = DIFFS,
            wheels = {
                { restLoad = 2.5, fieldFriction = 0.1, frictionScale = 0.1 },
                { restLoad = 2.5, fieldFriction = 0.1, frictionScale = 0.1 },
            },
        }, {})
        local load = data:get("loadSpeedKmh")
        assert.are.equal("insufficient", load.status)
    end)

    it("dá unknown quando a massa é desconhecida", function()
        local data = VehicleAnalyzer.analyze({
            schema = 1,
            motor = {
                maxForwardGearRatio = 100,
                torqueCurve = { { rpm = 1000, torque = 1 }, { rpm = 2000, torque = 1 } },
            },
            differentials = DIFFS,
            wheels = WHEELS,
        }, {})
        assert.are.equal("unknown", data:get("loadSpeedKmh").status)
    end)
end)
