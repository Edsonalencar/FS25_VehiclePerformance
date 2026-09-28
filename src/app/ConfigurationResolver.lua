-- Identidade técnica de uma configuração de veículo (requisitos §5): a chave
-- de cache e de nome de arquivo do dump. Só usa o Snapshot (tabela pura), sem
-- tocar o jogo: xmlFilename + configurações (nome=índice) ordenadas
-- alfabeticamente pelo nome, para ser determinístico independente da ordem de
-- iteração de `pairs`.
local NS = VehiclePerformance
local ConfigurationResolver = {}

--- snapshot.identity.xmlFilename .. "|" .. "name=idx;name2=idx2;..." com os
--- nomes das configurações ordenados alfabeticamente.
function ConfigurationResolver.key(snapshot)
    local xmlFilename = (snapshot and snapshot.identity and snapshot.identity.xmlFilename) or "unknown"
    local configuration = (snapshot and snapshot.configuration) or {}

    local names = {}
    for name in pairs(configuration) do
        names[#names + 1] = name
    end
    table.sort(names)

    local parts = {}
    for _, name in ipairs(names) do
        parts[#parts + 1] = string.format("%s=%s", name, tostring(configuration[name]))
    end

    return xmlFilename .. "|" .. table.concat(parts, ";")
end

NS.app.ConfigurationResolver = ConfigurationResolver
