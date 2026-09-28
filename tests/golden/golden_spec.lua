-- Testes golden (Fase 3): para cada dump real em tests/fixtures/dumps/*.xml,
-- valida (a) a análise não lança erro, (b) as métricas batem com
-- tests/golden/expected.lua (tolerância 1e-6), (c) os invariantes "greater" e
-- "drivetrain" de tests/fixtures/dumps/index.lua valem, e (d) peakPowerKw do
-- jogo e o F2 recalculado da curva diferem menos de 1%.
--
-- LIMITAÇÃO DESTE AMBIENTE DE DESENVOLVIMENTO: não há Farming Simulator 25
-- instalado aqui, então os arquivos .xml de dump (só podem ser gerados
-- rodando `vpDump` de verdade no jogo, ver specs/plans/... Fase 3 "Coleta
-- in-game") NÃO EXISTEM neste checkout. tests/fixtures/dumps/index.lua já tem
-- a estrutura de ids e invariantes pronta para quando alguém gerar os dumps
-- reais, copiá-los para tests/fixtures/dumps/<id>.xml e rodar
-- `make golden-update`. Por isso este spec DETECTA a ausência de dumps reais
-- e usa pending() em vez de falhar `make ci`. Ver
-- docs/api-findings/2026-09-28-runtime.md.
--
-- Também tolera o núcleo da Fase 2 (NS.core.Flatten/VehicleAnalyzer) ainda
-- não estar presente neste worktree (outro agente trabalha nela em paralelo,
-- em outro branch): nesse caso também usa pending(), nunca erro Lua.

local NS = require("tests.support.load").load({ adapters = false })

local indexOk, index = pcall(dofile, "tests/fixtures/dumps/index.lua")

local function fileExists(path)
    local fh = io.open(path, "r")
    if fh then
        fh:close()
        return true
    end
    return false
end

local function findDumps()
    if not indexOk then
        return {}
    end
    local found = {}
    for _, id in ipairs(index.ids or {}) do
        local path = "tests/fixtures/dumps/" .. id .. ".xml"
        if fileExists(path) then
            found[id] = path
        end
    end
    return found
end

local dumps = findDumps()
local dumpCount = 0
for _ in pairs(dumps) do
    dumpCount = dumpCount + 1
end

local coreReady = NS.core
    and NS.core.VehicleAnalyzer
    and NS.core.VehicleAnalyzer.analyze
    and NS.core.Flatten
    and NS.core.Flatten.unflatten

describe("golden", function()
    if dumpCount == 0 then
        it("sem dumps reais disponíveis neste ambiente de desenvolvimento", function()
            pending(
                "nenhum dump em tests/fixtures/dumps/*.xml neste ambiente (sem o jogo instalado); "
                    .. "rodar vpDump in-game e seguir o checklist de release. "
                    .. "Ver docs/api-findings/2026-09-28-runtime.md"
            )
        end)
        return
    end

    if not coreReady then
        it("núcleo (Fase 2) ainda não disponível neste checkout", function()
            pending(
                "NS.core.VehicleAnalyzer/Flatten ausentes; mesclar com a Fase 2 para rodar os testes golden de verdade"
            )
        end)
        return
    end

    local dumpLoader = require("tests.support.dump_loader")
    local expectedOk, expected = pcall(dofile, "tests/golden/expected.lua")

    local ANALYZE_OPTIONS = { loadRefWeightFraction = 0.5, pullingRefKN = 50 }

    local function loadSnapshot(id)
        return dumpLoader.load(dumps[id], NS)
    end

    local analyzedCache = {}
    local function analysisOf(id)
        if analyzedCache[id] == nil then
            local snapshot = loadSnapshot(id)
            analyzedCache[id] = NS.core.VehicleAnalyzer.analyze(snapshot, ANALYZE_OPTIONS)
        end
        return analyzedCache[id]
    end

    local function metricValue(id, metricId)
        local data = analysisOf(id)
        local metric = data.metrics and data.metrics[metricId]
        if type(metric) == "table" then
            return metric.value
        end
        return metric
    end

    -- (a) a análise não lança erro, para cada dump disponível.
    for id in pairs(dumps) do
        it(id .. ": a análise não lança erro", function()
            assert.has_no.errors(function()
                analysisOf(id)
            end)
        end)
    end

    -- (b) as métricas batem com expected.lua (tolerância 1e-6).
    if expectedOk then
        for id in pairs(dumps) do
            if expected[id] then
                it(id .. ": as métricas batem com expected.lua (tolerância 1e-6)", function()
                    for metricId, expectedValue in pairs(expected[id]) do
                        local actual = metricValue(id, metricId)
                        if type(expectedValue) == "number" then
                            local diff = math.abs((actual or 0) - expectedValue)
                            assert.is_true(
                                diff < 1e-6,
                                string.format(
                                    "%s.%s: esperado %s, obtido %s",
                                    id,
                                    metricId,
                                    tostring(expectedValue),
                                    tostring(actual)
                                )
                            )
                        else
                            assert.are.equal(expectedValue, actual)
                        end
                    end
                end)
            end
        end
    else
        it(
            "tests/golden/expected.lua ainda não existe (rodar make golden-update depois da revisão humana)",
            function()
                pending("tests/golden/expected.lua ausente; gerar com make golden-update após revisar os valores")
            end
        )
    end

    -- (c) invariantes "greater" e "drivetrain" de index.lua.
    it("invariantes 'greater' de index.lua valem", function()
        local checked = 0
        for _, triple in ipairs(index.greater or {}) do
            local metricId, greaterId, lesserId = triple[1], triple[2], triple[3]
            if dumps[greaterId] and dumps[lesserId] then
                checked = checked + 1
                local greaterValue = metricValue(greaterId, metricId)
                local lesserValue = metricValue(lesserId, metricId)
                assert.is_true(
                    (greaterValue or 0) > (lesserValue or 0),
                    string.format(
                        "%s: %s (%s) deveria ser > %s (%s)",
                        metricId,
                        greaterId,
                        tostring(greaterValue),
                        lesserId,
                        tostring(lesserValue)
                    )
                )
            end
        end
        if checked == 0 then
            pending("nenhum par de index.lua.greater tem os dois dumps disponíveis")
        end
    end)

    it("invariantes 'drivetrain' de index.lua valem", function()
        local checked = 0
        for id, expectedDrivetrain in pairs(index.drivetrain or {}) do
            if dumps[id] then
                checked = checked + 1
                assert.are.equal(expectedDrivetrain, metricValue(id, "drivetrain"))
            end
        end
        if checked == 0 then
            pending("nenhum id de index.lua.drivetrain tem dump disponível")
        end
    end)

    -- (d) peakPowerKw do jogo vs. F2 recalculado da curva: diferença < 1%.
    it("peakPowerKw do jogo e F2 recalculado da curva diferem menos de 1%", function()
        local checked = 0
        for id in pairs(dumps) do
            local snapshot = loadSnapshot(id)
            local declaredKw = snapshot.motor and snapshot.motor.peakPowerKw
            local recalculated = metricValue(id, "peakPowerKw")
            if type(declaredKw) == "number" and type(recalculated) == "number" and declaredKw ~= 0 then
                checked = checked + 1
                local diff = math.abs(recalculated - declaredKw) / declaredKw
                assert.is_true(
                    diff < 0.01,
                    string.format(
                        "%s: peakPowerKw jogo=%s recalculado=%s",
                        id,
                        tostring(declaredKw),
                        tostring(recalculated)
                    )
                )
            end
        end
        if checked == 0 then
            pending("nenhum dump disponível expõe motor.peakPowerKw e a métrica peakPowerKw recalculada")
        end
    end)
end)
