require("tests.support.load").load()
local NS = VehiclePerformance
local VehicleAnalyzer = NS.core.VehicleAnalyzer

local expected = dofile("tests/fixtures/manual/expected.lua")

local REAL_FIXTURES = {
    "ford_auto_largo",
    "ford_manual_dual_ballast",
    "valtra_145_michelin",
    "valtra_205_michelin",
    "valtra_145_4x2",
    "volvo_6x2_ferro",
    "volvo_6x4_alcoa",
}

local DEGENERATE_FIXTURES = { "no_motor", "bad_diff", "empty", "single_point_curve" }

local NUMERIC_FIELDS = {
    "peakPowerKw",
    "peakPowerCv",
    "peakTorqueKnm",
    "torqueReservePct",
    "powerToWeightKgPerCv",
    "maxRatio",
    "motorForceKn",
    "adhesionForceKn",
    "tractionForceKn",
    "loadSpeedKmh",
    "pullingIndex",
}

local METRIC_ID = {
    peakPowerKw = "peakPowerKw",
    peakPowerCv = "peakPowerCv",
    peakTorqueKnm = "peakTorqueKnm",
    torqueReservePct = "torqueReservePct",
    powerToWeightKgPerCv = "powerToWeightKgPerCv",
    maxRatio = "maxRatio",
    motorForceKn = "motorForceKn",
    adhesionForceKn = "adhesionForceKn",
    tractionForceKn = "tractionForceKn",
    loadSpeedKmh = "loadSpeedKmh",
    pullingIndex = "pullingIndex",
}

local function assertClose(actual, expectedValue, tol, msg)
    tol = tol or 1e-3
    local ok = math.abs(actual - expectedValue) <= tol * math.max(math.abs(expectedValue), 1e-9)
    assert.is_true(ok, string.format("%s: esperado ~%s, obtido %s", msg, tostring(expectedValue), tostring(actual)))
end

describe("VehicleAnalyzer.analyze — fixtures reais", function()
    for _, name in ipairs(REAL_FIXTURES) do
        it(name .. " confere com expected.lua (tolerância relativa 1e-3)", function()
            local snapshot = dofile("tests/fixtures/manual/" .. name .. ".lua")
            local data = VehicleAnalyzer.analyze(snapshot, {})
            local exp = expected[name]
            assert.is_not_nil(exp, "fixture sem entrada em expected.lua: " .. name)

            for _, field in ipairs(NUMERIC_FIELDS) do
                local metric = data:get(METRIC_ID[field])
                assert.are.equal("ok", metric.status, name .. "." .. field .. " status")
                assertClose(metric.value, exp[field], 1e-3, name .. "." .. field)
            end

            assert.are.equal(exp.tractionLimit, data:get("tractionLimit").value, name .. ".tractionLimit")
            local drivetrain = data:get("drivetrain")
            assert.are.equal(exp.drivetrain, drivetrain.value.label, name .. ".drivetrain")
            assert.are.equal(exp.drivenAxles, drivetrain.value.drivenAxles, name .. ".drivenAxles")
        end)
    end
end)

describe("VehicleAnalyzer.analyze — fixtures degeneradas", function()
    for _, name in ipairs(DEGENERATE_FIXTURES) do
        it(name .. " não lança erro e devolve métricas coerentes", function()
            local snapshot = dofile("tests/fixtures/manual/" .. name .. ".lua")
            local ok, data = pcall(VehicleAnalyzer.analyze, snapshot, {})
            assert.is_true(ok, name .. " não deveria lançar erro")
            assert.is_not_nil(data)
            assert.is_not_nil(data.metrics)
        end)
    end

    it("no_motor: métricas dependentes de motor viram unknown", function()
        local snapshot = dofile("tests/fixtures/manual/no_motor.lua")
        local data = VehicleAnalyzer.analyze(snapshot, {})
        assert.are.equal("unknown", data:get("peakPowerKw").status)
        assert.are.equal("unknown", data:get("peakTorqueKnm").status)
        assert.are.equal("unknown", data:get("maxRatio").status)
        -- Massa e drivetrain independem do motor.
        assert.are.equal("ok", data:get("massT").status)
        assert.are.equal("ok", data:get("drivetrain").status)
    end)

    it("bad_diff: drivetrain vira unknown com bad_wheel_index", function()
        local snapshot = dofile("tests/fixtures/manual/bad_diff.lua")
        local data = VehicleAnalyzer.analyze(snapshot, {})
        local dt = data:get("drivetrain")
        assert.are.equal("unknown", dt.status)
        assert.are.equal("bad_wheel_index", dt.reason)
        assert.are.equal("unknown", data:get("adhesionForceKn").status)
    end)

    it("empty: campos de alto nível ausentes e métricas todas unknown", function()
        local snapshot = dofile("tests/fixtures/manual/empty.lua")
        local data = VehicleAnalyzer.analyze(snapshot, {})
        assert.is_true(#data.availability.missing > 0)
        for _, field in ipairs(NUMERIC_FIELDS) do
            assert.are.equal("unknown", data:get(METRIC_ID[field]).status, field)
        end
    end)

    it("single_point_curve: peakPowerKw calculado, massa/tração unknown", function()
        local snapshot = dofile("tests/fixtures/manual/single_point_curve.lua")
        local data = VehicleAnalyzer.analyze(snapshot, {})
        assert.are.equal("ok", data:get("peakPowerKw").status)
        assert.are.equal("unknown", data:get("massT").status)
        assert.are.equal("unknown", data:get("tractionForceKn").status)
    end)
end)
