require("tests.support.load").load()
local NS = VehiclePerformance
local VehicleAnalyzer = NS.core.VehicleAnalyzer

local function drivetrainOf(snapshot)
    return VehicleAnalyzer.analyze(snapshot, {}):get("drivetrain")
end

describe("DifferentialAnalyzer (F6)", function()
    it("4x4 dá 2 eixos motrizes", function()
        local dt = drivetrainOf({
            schema = 1,
            wheels = { {}, {}, {}, {} },
            differentials = {
                { diffIndex1 = 1, diffIndex1IsWheel = true, diffIndex2 = 2, diffIndex2IsWheel = true },
                { diffIndex1 = 3, diffIndex1IsWheel = true, diffIndex2 = 4, diffIndex2IsWheel = true },
                { diffIndex1 = 0, diffIndex1IsWheel = false, diffIndex2 = 1, diffIndex2IsWheel = false },
            },
        })
        assert.are.equal("ok", dt.status)
        assert.are.equal("4x4", dt.value.label)
        assert.are.equal(2, dt.value.drivenAxles)
    end)

    it("6x2 dá 1 eixo motriz", function()
        local dt = drivetrainOf({
            schema = 1,
            wheels = { {}, {}, {}, {}, {}, {} },
            differentials = {
                { diffIndex1 = 3, diffIndex1IsWheel = true, diffIndex2 = 4, diffIndex2IsWheel = true },
            },
        })
        assert.are.equal("ok", dt.status)
        assert.are.equal("6x2", dt.value.label)
        assert.are.equal(1, dt.value.drivenAxles)
    end)

    it("6x4 dá 2 eixos motrizes", function()
        local dt = drivetrainOf({
            schema = 1,
            wheels = { {}, {}, {}, {}, {}, {} },
            differentials = {
                { diffIndex1 = 5, diffIndex1IsWheel = true, diffIndex2 = 6, diffIndex2IsWheel = true },
                { diffIndex1 = 3, diffIndex1IsWheel = true, diffIndex2 = 4, diffIndex2IsWheel = true },
                { diffIndex1 = 0, diffIndex1IsWheel = false, diffIndex2 = 1, diffIndex2IsWheel = false },
            },
        })
        assert.are.equal("ok", dt.status)
        assert.are.equal("6x4", dt.value.label)
        assert.are.equal(2, dt.value.drivenAxles)
    end)

    it("índice de roda fora do intervalo dá unknown/bad_wheel_index", function()
        local dt = drivetrainOf({
            schema = 1,
            wheels = { {}, {}, {}, {} },
            differentials = {
                { diffIndex1 = 9, diffIndex1IsWheel = true, diffIndex2 = 2, diffIndex2IsWheel = true },
            },
        })
        assert.are.equal("unknown", dt.status)
        assert.are.equal("bad_wheel_index", dt.reason)
    end)

    it("índice de diferencial fora do intervalo dá unknown/bad_diff_index", function()
        local dt = drivetrainOf({
            schema = 1,
            wheels = { {}, {}, {}, {} },
            differentials = {
                { diffIndex1 = 1, diffIndex1IsWheel = true, diffIndex2 = 5, diffIndex2IsWheel = false },
            },
        })
        assert.are.equal("unknown", dt.status)
        assert.are.equal("bad_diff_index", dt.reason)
    end)

    it("sem diferenciais dá unknown/no_differentials", function()
        local dt = drivetrainOf({ schema = 1, wheels = { {}, {}, {}, {} }, differentials = {} })
        assert.are.equal("unknown", dt.status)
        assert.are.equal("no_differentials", dt.reason)
    end)
end)
