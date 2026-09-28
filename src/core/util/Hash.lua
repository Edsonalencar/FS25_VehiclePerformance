-- Hash djb2 clássico, usado para nomear arquivos de dump (Fase 3).
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.util = NS.core.util or {}

local Hash = {}

local MOD32 = 4294967296 -- 2^32

--- djb2(str) -> string hex de 8 dígitos minúsculos.
function Hash.djb2(str)
    local hash = 5381
    for i = 1, #str do
        hash = (hash * 33 + str:byte(i)) % MOD32
    end
    return string.format("%08x", hash)
end

NS.core.util.Hash = Hash
