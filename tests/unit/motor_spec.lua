require("tests.support.load").load()
local NS = VehiclePerformance
local MotorAnalyzer = NS.core.analyzers.MotorAnalyzer
local VehicleAnalyzer = NS.core.VehicleAnalyzer

local function assertClose(actual, expected, tol)
    tol = tol or 1e-3
    assert.is_true(
        math.abs(actual - expected) <= tol * math.abs(expected),
        string.format("esperado ~%s, obtido %s", tostring(expected), tostring(actual))
    )
end

describe("MotorAnalyzer.peakPowerFromCurve", function()
    it("curva do Ford (auto_largo) dá 148.20 +-0.01 kW", function()
        local curve = {
            { rpm = 990.0, torque = 0.765 },
            { rpm = 1100.0, torque = 0.8245 },
            { rpm = 1298.0, torque = 0.85 },
            { rpm = 1584.0, torque = 0.85 },
            { rpm = 1892.0, torque = 0.748 },
            { rpm = 2200, torque = 0.612 },
        }
        local kw = MotorAnalyzer.peakPowerFromCurve(curve)
        assert.is_true(math.abs(kw - 148.20) <= 0.01)
    end)

    it("segmento de torque constante usa o rpm inicial", function()
        -- Torque constante entre os dois primeiros pontos: o ótimo do
        -- segmento deve ser avaliado no rpm inicial (a.rpm), não recalculado
        -- via interpolação (que dividiria por zero).
        local curve = {
            { rpm = 1000, torque = 1.0 },
            { rpm = 2000, torque = 1.0 },
        }
        local kw = MotorAnalyzer.peakPowerFromCurve(curve)
        -- Com torque igual nos dois pontos do segmento, o algoritmo avalia
        -- em a.rpm (o rpm inicial), não em b.rpm: t*rpm = 1000*1.0, não
        -- 2000*1.0 (que seria o resultado se usasse o rpm final por engano).
        local expectedKw = 1000 * 1.0 * (math.pi / 30)
        assertClose(kw, expectedKw)
    end)

    it("curva de 1 ponto funciona (rpm*torque*pi/30)", function()
        local curve = { { rpm = 2000, torque = 0.5 } }
        local kw = MotorAnalyzer.peakPowerFromCurve(curve)
        assertClose(kw, 2000 * 0.5 * (math.pi / 30))
    end)
end)

describe("MotorAnalyzer.analyze F4 (torqueReservePct)", function()
    it("dá unknown quando T(maxRpm) <= 0", function()
        local snapshot = {
            schema = 1,
            motor = {
                maxRpm = 2000,
                torqueCurve = {
                    { rpm = 1000, torque = 0.5 },
                    { rpm = 2000, torque = 0 },
                },
            },
        }
        local data = VehicleAnalyzer.analyze(snapshot, {})
        local reserve = data:get("torqueReservePct")
        assert.are.equal("unknown", reserve.status)
    end)
end)
