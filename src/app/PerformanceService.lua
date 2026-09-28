-- Cache de PerformanceData por configuração, sem dependência do jogo. A
-- chave usa NS.app.ConfigurationResolver.key(snapshot) (Fase 3). Cache FIFO:
-- ao exceder maxEntries, remove a entrada mais antiga (por ordem de
-- inserção, não de último acesso). As settings de métricas entram na chave
-- por composição do snapshot; `vpSet` (Fase 3/5) chama `clear()` quando
-- métricas mudam.
local NS = VehiclePerformance
local PerformanceService = {}
PerformanceService.__index = PerformanceService

local DEFAULT_MAX_ENTRIES = 64

--- @param deps {analyze:function, settings:table, logger:table, maxEntries:number|nil}
function PerformanceService.new(deps)
    return setmetatable({
        analyze = deps.analyze,
        settings = deps.settings,
        logger = deps.logger,
        maxEntries = deps.maxEntries or DEFAULT_MAX_ENTRIES,
        cache = {},
        order = {},
        hits = 0,
    }, PerformanceService)
end

-- Insere/atualiza `key` no cache e aplica FIFO: remove a mais antiga da lista
-- `order` enquanto o total exceder `maxEntries`. Uma chave já presente não é
-- duplicada em `order` (evita reordenar em atualização).
function PerformanceService:store(key, data)
    if self.cache[key] == nil then
        self.order[#self.order + 1] = key
    end
    self.cache[key] = data
    while #self.order > self.maxEntries do
        local oldest = table.remove(self.order, 1)
        if oldest ~= key then
            self.cache[oldest] = nil
        end
    end
end

function PerformanceService:get(snapshot)
    local key = NS.app.ConfigurationResolver.key(snapshot)
    local hit = self.cache[key]
    if hit then
        self.hits = self.hits + 1
        return hit
    end
    local data = self.analyze(snapshot, {
        loadRefWeightFraction = self.settings:get("metrics#loadRefWeightFraction"),
        pullingRefKN = self.settings:get("metrics#pullingRefKN"),
    })
    self:store(key, data)
    local missing = (data.availability and data.availability.missing) or {}
    self.logger:debug("perf", "%s analisado; ausentes=%d", tostring(key), #missing)
    return data
end

function PerformanceService:clear()
    self.cache, self.order, self.hits = {}, {}, 0
end

NS.app.PerformanceService = PerformanceService
