require("tests.support.load").load()
local NS = VehiclePerformance
local VehicleAnalyzer = NS.core.VehicleAnalyzer

local function ratioOf(motor)
    return VehicleAnalyzer.analyze({ schema = 1, motor = motor }, {})
end

describe("TransmissionAnalyzer (F7)", function()
    it("CVT usa maxForwardGearRatio", function()
        local data = ratioOf({ maxForwardGearRatio = 250 })
        local r = data:get("maxRatio")
        assert.are.equal("ok", r.status)
        assert.are.equal(250, r.value)
        assert.are.equal("cvt", data:get("transmissionType").value)
    end)

    it("marchas x grupos: max(gear.ratio) * max(group.ratio or 1)", function()
        local data = ratioOf({
            forwardGears = { { ratio = 10 }, { ratio = 30 }, { ratio = 20 } },
            gearGroups = { { ratio = 2 }, { ratio = 0.5 } },
        })
        local r = data:get("maxRatio")
        assert.are.equal("ok", r.status)
        assert.are.equal(60, r.value) -- max(30) * max(2, 0.5)
        assert.are.equal("gears", data:get("transmissionType").value)
        assert.are.equal(3, data:get("gearCount").value)
        assert.are.equal(2, data:get("groupCount").value)
    end)

    it("marchas sem grupos usa fator 1", function()
        local data = ratioOf({ forwardGears = { { ratio = 10 }, { ratio = 30 } } })
        assert.are.equal(30, data:get("maxRatio").value)
        assert.are.equal(0, data:get("groupCount").value)
    end)

    it("sem ratios (nem CVT nem marchas) dá unknown", function()
        local data = ratioOf({ maxRpm = 2000 })
        assert.are.equal("unknown", data:get("maxRatio").status)
        assert.are.equal("unknown", data:get("transmissionType").value)
    end)

    it("sem motor dá unknown", function()
        local data = VehicleAnalyzer.analyze({ schema = 1 }, {})
        assert.are.equal("unknown", data:get("maxRatio").status)
    end)
end)
