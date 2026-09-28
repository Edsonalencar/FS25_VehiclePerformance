-- Carrega um dump XML gerado por SnapshotXmlWriter (produção) usando o parser
-- de teste tests/support/xml.lua (não é o mesmo parser do jogo: XMLFile só
-- existe dentro do FS25). Monta a lista {k,t,v} a partir dos elementos
-- vpSnapshot.v(N) e aplica NS.core.Flatten.unflatten (Fase 2) para devolver o
-- Snapshot reconstruído. Só usado pelos testes golden (tests/golden/), nunca
-- em produção.
local xml = require("tests.support.xml")

local M = {}

--- "n" -> number, "b" -> boolean, senão string como está (t == "s" ou
--- qualquer outro rótulo usado pelo Flatten).
local function decodeValue(t, raw)
    if t == "n" then
        return tonumber(raw)
    elseif t == "b" then
        return raw == "true"
    end
    return raw
end

--- Lê path (XML de dump) e devolve o Snapshot reconstruído.
---@param path string caminho do arquivo .xml (tests/fixtures/dumps/<id>.xml)
---@param NS table namespace já carregado (tests/support/load.lua), com
---           NS.core.Flatten.unflatten disponível
function M.load(path, NS)
    local root = xml.load(path)
    if not root then
        error("dump_loader: não foi possível ler '" .. tostring(path) .. "'")
    end

    local entries = {}
    for _, v in ipairs(xml.children(root, "v")) do
        entries[#entries + 1] = {
            k = v.attrs.k,
            t = v.attrs.t,
            v = decodeValue(v.attrs.t, v.attrs.v),
        }
    end

    if not (NS and NS.core and NS.core.Flatten and NS.core.Flatten.unflatten) then
        error("dump_loader: NS.core.Flatten.unflatten indisponível (core da Fase 2 ainda não carregado)")
    end

    return NS.core.Flatten.unflatten(entries)
end

return M
