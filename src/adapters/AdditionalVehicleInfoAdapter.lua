-- Detecta a presença do Additional Vehicle Info (AVI) só para diagnóstico
-- (`vpStatus`). Não instala hooks, não lê o ambiente interno do AVI e não
-- depende dele: a integração é só coexistência (ADR-0006 e requisitos §11).
-- Um erro aqui nunca afeta o resto do mod (requisitos §11.4).
local NS = VehiclePerformance
local AdditionalVehicleInfoAdapter = {}

local MOD_NAME = "FS25_additionalVehicleInfo" -- nome exato (minúsculo) — PRD §AVI

--- Detecta o AVI e devolve {present, version, integration}.
--- `integration` é sempre "coexist", exceto "error" se a própria detecção
--- falhar (ex.: `g_modManager` inconsistente entre patches do jogo).
---@param logger table  porta Logger (error/warning/info/debug)
function AdditionalVehicleInfoAdapter.detect(logger)
    local status = { present = false, version = nil, integration = "coexist" }
    local ok = pcall(function()
        status.present = type(g_modIsLoaded) == "table" and g_modIsLoaded[MOD_NAME] == true
        if status.present and g_modManager and type(g_modManager.getModByName) == "function" then
            local mod = g_modManager:getModByName(MOD_NAME)
            status.version = mod and mod.version
        end
    end)
    if not ok then
        status.integration = "error"
    end
    logger:info(
        "avi",
        "Additional Vehicle Info: %s (v%s, %s)",
        status.present and "presente" or "ausente",
        tostring(status.version),
        status.integration
    )
    return status
end

NS.adapters.AdditionalVehicleInfoAdapter = AdditionalVehicleInfoAdapter
