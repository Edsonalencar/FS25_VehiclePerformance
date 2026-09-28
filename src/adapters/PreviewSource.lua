-- Porta que expõe os veículos de preview da tela de configuração da loja
-- (g_shopConfigScreen.previewVehicles), com guardas de tipo em cada passo.
-- É o único lugar em que Console.lua (app/, sem acesso a g_*) toca o estado
-- da ShopConfigScreen: app/ recebe PreviewSource injetado via deps.
local NS = VehiclePerformance
local PreviewSource = {}

--- Devolve {{vehicle=v, storeItem=si}, ...} para cada veículo de preview
--- atual. Lista vazia se a tela de configuração não estiver aberta ou não
--- tiver preview algum (nunca lança erro).
--- [A VALIDAR na Fase 3]: para bundles (múltiplos storeItems), assume-se um
--- array paralelo g_shopConfigScreen.storeItems[i]; sem ele, cai para o
--- storeItem único da tela.
function PreviewSource.list()
    local screen = g_shopConfigScreen
    if type(screen) ~= "table" then
        return {}
    end
    local previews = screen.previewVehicles
    if type(previews) ~= "table" then
        return {}
    end

    local out = {}
    for i, vehicle in ipairs(previews) do
        if type(vehicle) == "table" then
            local storeItem = (type(screen.storeItems) == "table" and screen.storeItems[i]) or screen.storeItem
            out[#out + 1] = { vehicle = vehicle, storeItem = storeItem }
        end
    end
    return out
end

NS.adapters.PreviewSource = PreviewSource
