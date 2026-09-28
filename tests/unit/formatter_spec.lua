-- Testa RowFormatter.rows com uma porta `text` FALSA (get devolve a própria
-- chave, number devolve tostring(v), speed devolve kmh, "km/h"), o que deixa
-- o texto resultante == chave de tradução quando o padrão não tem "%s"/"%d"
-- (facilita as asserções de profile/ordem sem depender do texto final).
require("tests.support.load").load()
local NS = VehiclePerformance

local function makeText(overrides)
    local t = {
        get = function(key)
            return key
        end,
        number = function(v)
            return tostring(v)
        end,
        speed = function(kmh)
            return kmh, "km/h"
        end,
    }
    for k, v in pairs(overrides or {}) do
        t[k] = v
    end
    return t
end

-- Contrato assumido de PerformanceData (ver comentário de topo de
-- src/app/RowFormatter.lua): data:get(id) -> Value{value, status, ...}.
local function value(v, status)
    return { value = v, status = status or "ok" }
end

local function makeData(overrides)
    local metrics = {
        drivetrain = value({ label = "4x4", drivenAxles = 2 }),
        peakPowerCv = value(201),
        peakPowerKw = value(148),
        peakTorqueKnm = value(0.85),
        torqueReservePct = value(39),
        powerToWeightKgPerCv = value(25.1),
        tractionForceKn = value(75),
        tractionLimit = value("adhesion"),
        loadRefWeightFraction = value(0.5),
        loadSpeedKmh = value(21),
        pullingIndex = value(60),
    }
    for k, v in pairs(overrides or {}) do
        metrics[k] = v
    end
    return {
        metrics = metrics,
        get = function(self, id)
            return self.metrics[id]
        end,
    }
end

describe("RowFormatter", function()
    it("ordem e profiles das 6 linhas com PerformanceData totalmente ok e showPullingIndex", function()
        local rows = NS.app.RowFormatter.rows(makeData(), makeText(), { showPullingIndex = true })

        assert.are.equal(6, #rows)
        assert.are.equal("WHEELS", rows[1].profile)
        assert.are.equal("vp_row_drivetrain", rows[1].text)
        assert.are.equal("POWER", rows[2].profile)
        assert.are.equal("vp_row_power_calc", rows[2].text)
        assert.are.equal("WEIGHT", rows[3].profile)
        assert.are.equal("vp_row_power_weight", rows[3].text)
        assert.are.equal("TRANSMISSION", rows[4].profile)
        assert.are.equal("vp_row_traction", rows[4].text)
        assert.are.equal("MAX_SPEED", rows[5].profile)
        assert.are.equal("vp_row_load", rows[5].text)
        assert.are.equal("POWER", rows[6].profile)
        assert.are.equal("vp_row_pulling_index", rows[6].text)
    end)

    it("sem reserva de torque usa vp_row_power_calc_noreserve", function()
        local rows = NS.app.RowFormatter.rows(makeData({ torqueReservePct = value(nil, "unknown") }), makeText(), {})
        local power = rows[2]
        assert.are.equal("POWER", power.profile)
        assert.are.equal("vp_row_power_calc_noreserve", power.text)
    end)

    it("drivetrain sempre aparece, mesmo unknown (vp_drivetrain_unknown)", function()
        local rows = NS.app.RowFormatter.rows(makeData({ drivetrain = value(nil, "unknown") }), makeText(), {})
        assert.are.equal("WHEELS", rows[1].profile)
        assert.are.equal("vp_drivetrain_unknown", rows[1].text)
    end)

    it("omite POWER/WEIGHT/TRANSMISSION/MAX_SPEED quando a métrica principal é unknown", function()
        local rows = NS.app.RowFormatter.rows(
            makeData({
                peakPowerCv = value(nil, "unknown"),
                powerToWeightKgPerCv = value(nil, "unknown"),
                tractionForceKn = value(nil, "unknown"),
                loadSpeedKmh = value(nil, "unknown"),
            }),
            makeText(),
            {}
        )

        -- só a linha de drivetrain (sempre presente) sobra.
        assert.are.equal(1, #rows)
        assert.are.equal("WHEELS", rows[1].profile)
    end)

    it("status insufficient no load mostra vp_row_load_insufficient sem argumentos", function()
        local rows = NS.app.RowFormatter.rows(makeData({ loadSpeedKmh = value(nil, "insufficient") }), makeText(), {})
        local maxSpeed
        for _, row in ipairs(rows) do
            if row.profile == "MAX_SPEED" then
                maxSpeed = row
            end
        end
        assert.is_not_nil(maxSpeed)
        assert.are.equal("vp_row_load_insufficient", maxSpeed.text)
    end)

    it("índice de puxada só aparece com showPullingIndex=true", function()
        local withoutFlag = NS.app.RowFormatter.rows(makeData(), makeText(), { showPullingIndex = false })
        local withFlag = NS.app.RowFormatter.rows(makeData(), makeText(), { showPullingIndex = true })

        assert.are.equal(5, #withoutFlag)
        assert.are.equal(6, #withFlag)
    end)

    it("índice de puxada não aparece com showPullingIndex=true se status não for ok", function()
        local rows = NS.app.RowFormatter.rows(
            makeData({ pullingIndex = value(nil, "unknown") }),
            makeText(),
            { showPullingIndex = true }
        )
        assert.are.equal(5, #rows)
    end)

    it("formato quebrado (menos argumentos do que %s pede) omite a linha sem lançar erro", function()
        local text = makeText({
            get = function(key)
                if key == "vp_row_traction" then
                    return "%s %s %s %s" -- pede 4 argumentos; RowFormatter só passa 2
                end
                return key
            end,
        })

        local rows
        assert.has_no.errors(function()
            rows = NS.app.RowFormatter.rows(makeData(), text, {})
        end)

        local hasTransmission = false
        for _, row in ipairs(rows) do
            if row.profile == "TRANSMISSION" then
                hasTransmission = true
            end
        end
        assert.is_false(hasTransmission)
        -- as outras linhas continuam presentes normalmente.
        assert.are.equal("WHEELS", rows[1].profile)
    end)
end)
