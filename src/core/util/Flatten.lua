-- Achata/reconstrói tabelas Lua para o dump/loader de fixtures (Fase 3 usa
-- flatten para escrever XML; os testes usam unflatten para reconstruir
-- Snapshots). Faz roundtrip perfeito para tabelas cujas folhas são number,
-- string ou boolean. Uma subtabela vazia (ex.: "declared = {}", presente mas
-- sem campos) é preservada com o marcador de tipo "e" (empty); sem isso ela
-- desapareceria no roundtrip (nenhuma folha sob o prefixo dela).
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.util = NS.core.util or {}

local Flatten = {}

--- Chaves de t, em ordem determinística: numérica se todas as chaves forem
--- números (caso array), senão lexicográfica pela representação em string.
local function sortedKeys(t)
    local keys = {}
    local allNumeric = true
    for k in pairs(t) do
        keys[#keys + 1] = k
        if type(k) ~= "number" then
            allNumeric = false
        end
    end
    if allNumeric then
        table.sort(keys)
    else
        table.sort(keys, function(a, b)
            return tostring(a) < tostring(b)
        end)
    end
    return keys
end

local function typeTag(v)
    local t = type(v)
    if t == "number" then
        return "n"
    elseif t == "string" then
        return "s"
    elseif t == "boolean" then
        return "b"
    end
    return nil
end

local function isEmpty(t)
    return next(t) == nil
end

local function walk(t, prefix, out)
    for _, k in ipairs(sortedKeys(t)) do
        local v = t[k]
        local path = prefix and (prefix .. "." .. tostring(k)) or tostring(k)
        if type(v) == "table" then
            if isEmpty(v) then
                out[#out + 1] = { k = path, t = "e", v = true }
            else
                walk(v, path, out)
            end
        else
            local tag = typeTag(v)
            if tag then
                out[#out + 1] = { k = path, t = tag, v = v }
            end
        end
    end
end

--- flatten(tbl) -> { {k="motor.maxRpm", t="n", v=2200}, ... }, chaves ordenadas.
function Flatten.flatten(tbl)
    local out = {}
    if type(tbl) == "table" then
        walk(tbl, nil, out)
    end
    return out
end

--- unflatten(list) -> tbl, reconstruindo arrays quando os componentes da
--- chave, num mesmo nível, forem os inteiros sequenciais 1..N.
function Flatten.unflatten(list)
    local root = {}
    for _, item in ipairs(list) do
        local segments = {}
        for seg in item.k:gmatch("[^.]+") do
            segments[#segments + 1] = seg
        end
        local node = root
        for i = 1, #segments - 1 do
            local seg = segments[i]
            local key = seg:match("^%d+$") and tonumber(seg) or seg
            if node[key] == nil then
                node[key] = {}
            end
            node = node[key]
        end
        local lastSeg = segments[#segments]
        local lastKey = lastSeg:match("^%d+$") and tonumber(lastSeg) or lastSeg
        node[lastKey] = (item.t == "e") and {} or item.v
    end
    return root
end

NS.core.util.Flatten = Flatten
