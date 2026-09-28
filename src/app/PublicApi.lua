-- API pública estável (requisitos §15). Leitura sob demanda, sem cache
-- próprio; nunca lança erro para o chamador (o chamador pode ser outro
-- mod). Não toca em nada do jogo: só chama as portas injetadas em `deps`.
-- `deps = {reader, service, storeItemOf, logger}`; `storeItemOf` mora em
-- `adapters/PreviewSource.lua` (Fase 3) e resolve o storeItem do veículo.
local NS = VehiclePerformance
local PublicApi = {}

--- Instala `ns.api` usando as portas em `deps`.
---@param ns table  namespace do mod (VehiclePerformance)
---@param deps {reader:table, service:table, storeItemOf:function, logger:table}
function PublicApi.install(ns, deps)
    ns.api = ns.api or {}
    ns.api.VERSION = 1

    -- PerformanceData ou nil. Nunca lança erro: se qualquer etapa falhar
    -- (veículo sem storeItem, reader indisponível, leitura quebrada), o
    -- pcall devolve nil em vez de propagar.
    ns.api.getPerformance = function(vehicle)
        local ok, data = pcall(function()
            if vehicle == nil then
                return nil
            end
            local storeItem = deps.storeItemOf(vehicle)
            if storeItem == nil then
                return nil
            end
            return deps.service:get(deps.reader.read(vehicle, storeItem, deps.logger))
        end)
        if not ok then
            return nil
        end
        return data
    end

    -- Value de uma métrica específica, ou nil se a PerformanceData ou a
    -- métrica não existirem.
    ns.api.getMetric = function(vehicle, metricId)
        local data = ns.api.getPerformance(vehicle)
        return data and data:get(metricId)
    end

    -- Cópia rasa de `vehicle.configurations`. É sempre uma tabela nova:
    -- mutar o resultado nunca afeta o veículo original. Nos diferenciais,
    -- só existem dados completos no servidor: num cliente MP puro,
    -- métricas dependentes de `drivetrain` podem sair "unknown" (ver
    -- docs/FORMULAS.md e docs/compatibility-matrix.md).
    ns.api.getCurrentConfiguration = function(vehicle)
        local out = {}
        for k, v in pairs((vehicle and vehicle.configurations) or {}) do
            out[k] = v
        end
        return out
    end
end

NS.app.PublicApi = PublicApi
