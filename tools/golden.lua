#!/usr/bin/env lua
-- Gera tests/golden/expected.lua a partir dos dumps reais em
-- tests/fixtures/dumps/*.xml. Roda com o Lua de desenvolvimento (hererocks):
--   .lua/bin/lua tools/golden.lua           -- dry-run: só relata
--   .lua/bin/lua tools/golden.lua --write   -- grava tests/golden/expected.lua
-- (equivalente a `make golden-update`, que já passa --write).
--
-- LIMITAÇÃO DESTE AMBIENTE DE DESENVOLVIMENTO: não há Farming Simulator 25
-- instalado aqui, então tests/fixtures/dumps/ não tem nenhum .xml real ainda
-- (só tests/fixtures/dumps/index.lua, com a estrutura de ids/invariantes já
-- pronta). Rodar este script aqui só confirma que ele termina sem erro e
-- avisa a ausência de dumps: nada é escrito nesse caso. Ver
-- docs/api-findings/2026-09-28-runtime.md.
--
-- Deve ser executado a partir da raiz do repositório (é isso que o Makefile
-- faz: `$(LUA) tools/golden.lua --write`).

package.path = "./?.lua;" .. package.path

local write = false
for _, a in ipairs(arg or {}) do
    if a == "--write" then
        write = true
    end
end

local function fileExists(path)
    local fh = io.open(path, "r")
    if fh then
        fh:close()
        return true
    end
    return false
end

local indexOk, index = pcall(dofile, "tests/fixtures/dumps/index.lua")
if not indexOk then
    print("golden: não foi possível ler tests/fixtures/dumps/index.lua: " .. tostring(index))
    os.exit(1)
end

local found = {}
for _, id in ipairs(index.ids or {}) do
    local path = "tests/fixtures/dumps/" .. id .. ".xml"
    if fileExists(path) then
        found[#found + 1] = { id = id, path = path }
    end
end

if #found == 0 then
    print("golden: nenhum dump encontrado em tests/fixtures/dumps/ (esperado neste ambiente sem o jogo instalado)")
    os.exit(0)
end

local NS = require("tests.support.load").load({ adapters = false })

if not (NS.core and NS.core.VehicleAnalyzer and NS.core.VehicleAnalyzer.analyze) then
    print("golden: NS.core.VehicleAnalyzer indisponível; o núcleo da Fase 2 ainda não está neste checkout")
    os.exit(0)
end
if not (NS.core.Flatten and NS.core.Flatten.unflatten) then
    print("golden: NS.core.Flatten indisponível; o núcleo da Fase 2 ainda não está neste checkout")
    os.exit(0)
end

local dumpLoader = require("tests.support.dump_loader")

local DEFAULT_OPTIONS = { loadRefWeightFraction = 0.5, pullingRefKN = 50 }

local function round6(n)
    if type(n) ~= "number" then
        return n
    end
    return math.floor(n * 1e6 + 0.5) / 1e6
end

local expected = {}
for _, entry in ipairs(found) do
    local okLoad, snapshotOrErr = pcall(dumpLoader.load, entry.path, NS)
    if not okLoad then
        print("golden: falha ao carregar " .. entry.path .. ": " .. tostring(snapshotOrErr))
        os.exit(1)
    end
    local okAnalyze, dataOrErr = pcall(NS.core.VehicleAnalyzer.analyze, snapshotOrErr, DEFAULT_OPTIONS)
    if not okAnalyze then
        print("golden: falha ao analisar " .. entry.id .. ": " .. tostring(dataOrErr))
        os.exit(1)
    end

    local metrics = {}
    for metricId, metric in pairs((dataOrErr and dataOrErr.metrics) or {}) do
        if type(metric) == "table" then
            metrics[metricId] = round6(metric.value)
        else
            metrics[metricId] = round6(metric)
        end
    end
    expected[entry.id] = metrics
end

if not write then
    print(string.format("golden: %d dump(s) analisados (dry-run; use --write para gravar expected.lua)", #found))
    os.exit(0)
end

local function serialize(value, indent)
    indent = indent or ""
    if type(value) == "table" then
        local keys = {}
        for k in pairs(value) do
            keys[#keys + 1] = k
        end
        table.sort(keys, function(a, b)
            return tostring(a) < tostring(b)
        end)
        local parts = { "{\n" }
        for _, k in ipairs(keys) do
            local keyLiteral = type(k) == "number" and ("[" .. k .. "]")
                or ("[" .. string.format("%q", tostring(k)) .. "]")
            parts[#parts + 1] = indent
                .. "    "
                .. keyLiteral
                .. " = "
                .. serialize(value[k], indent .. "    ")
                .. ",\n"
        end
        parts[#parts + 1] = indent .. "}"
        return table.concat(parts)
    elseif type(value) == "number" then
        return string.format("%.6f", value)
    elseif type(value) == "string" then
        return string.format("%q", value)
    else
        return tostring(value)
    end
end

local fh, openErr = io.open("tests/golden/expected.lua", "w")
if not fh then
    print("golden: não foi possível abrir tests/golden/expected.lua para escrita: " .. tostring(openErr))
    os.exit(1)
end
fh:write("-- Gerado por tools/golden.lua --write (make golden-update). Não editar à mão.\n")
fh:write("return ")
fh:write(serialize(expected))
fh:write("\n")
fh:close()
print(string.format("golden: gravado tests/golden/expected.lua com %d dump(s)", #found))
