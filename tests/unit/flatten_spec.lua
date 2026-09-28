require("tests.support.load").load()
local NS = VehiclePerformance
local Flatten = NS.core.util.Flatten

local FIXTURES = {
    "ford_auto_largo",
    "ford_manual_dual_ballast",
    "valtra_145_michelin",
    "valtra_205_michelin",
    "valtra_145_4x2",
    "volvo_6x2_ferro",
    "volvo_6x4_alcoa",
    "no_motor",
    "bad_diff",
    "empty",
    "single_point_curve",
}

--- Comparação profunda recursiva (sem depender de libs externas).
local function deepEqual(a, b)
    if a == b then
        return true
    end
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end
    for k, v in pairs(a) do
        if not deepEqual(v, b[k]) then
            return false
        end
    end
    for k in pairs(b) do
        if a[k] == nil then
            return false
        end
    end
    return true
end

describe("Flatten/unflatten", function()
    it("achata em uma lista de {k,t,v}, com tipos n/s/b (e o marcador de tabela vazia 'e')", function()
        local list = Flatten.flatten({ a = 1, b = "x", c = true, nested = { 1, 2, 3 }, vazio = {} })
        assert.is_true(#list > 0)
        for _, item in ipairs(list) do
            assert.is_true(item.t == "n" or item.t == "s" or item.t == "b" or item.t == "e")
        end
    end)

    it("gera chaves ordenadas deterministicamente", function()
        local list1 = Flatten.flatten({ z = 1, a = 2, m = 3 })
        local list2 = Flatten.flatten({ a = 2, m = 3, z = 1 })
        assert.are.same(list1, list2)
        assert.are.equal("a", list1[1].k)
        assert.are.equal("m", list1[2].k)
        assert.are.equal("z", list1[3].k)
    end)

    it("arrays viram chaves N.1, N.2, ... (1-based)", function()
        local list = Flatten.flatten({ wheels = { { radius = 0.5 }, { radius = 0.6 } } })
        local byKey = {}
        for _, item in ipairs(list) do
            byKey[item.k] = item.v
        end
        assert.are.equal(0.5, byKey["wheels.1.radius"])
        assert.are.equal(0.6, byKey["wheels.2.radius"])
    end)

    for _, name in ipairs(FIXTURES) do
        it("roundtrip perfeito para o fixture " .. name, function()
            local snapshot = dofile("tests/fixtures/manual/" .. name .. ".lua")
            local roundtripped = Flatten.unflatten(Flatten.flatten(snapshot))
            assert.is_true(deepEqual(snapshot, roundtripped))
            assert.is_true(deepEqual(roundtripped, snapshot))
        end)
    end
end)
