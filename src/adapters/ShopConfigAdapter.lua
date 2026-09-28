-- Acopla PerformanceService/RowFormatter à tela de configuração da loja via
-- HookRegistry (ADR-03). `registerCustomSpecValues` é chamado só a partir de
-- `onVehiclesLoaded`, com o preview já carregado (ShopConfigScreen.lua:907);
-- não roda por frame. Qualquer erro é contido pelo pcall do HookRegistry, que
-- desativa o hook após 3 falhas; como o hook é "append", as linhas vanilla já
-- foram inseridas e continuam intactas mesmo se este código falhar.
local NS = VehiclePerformance
local ShopConfigAdapter = {}
ShopConfigAdapter.__index = ShopConfigAdapter

--- @param deps {reader, service, formatter, text, settings, logger, state}
function ShopConfigAdapter.new(deps)
    return setmetatable({
        reader = deps.reader,
        service = deps.service,
        formatter = deps.formatter,
        text = deps.text,
        settings = deps.settings,
        logger = deps.logger,
        state = deps.state,
    }, ShopConfigAdapter)
end

function ShopConfigAdapter:install()
    return NS.adapters.HookRegistry.add({
        id = "ShopConfigScreen.registerCustomSpecValues",
        target = ShopConfigScreen,
        method = "registerCustomSpecValues",
        kind = "append",
        fn = function(screen, values, storeItems, vehicle, saleItem) -- luacheck: ignore 212
            self:onCustomSpecValues(screen, values, vehicle)
        end,
    })
end

function ShopConfigAdapter:onCustomSpecValues(screen, values, vehicle)
    if not self.settings:get("ui#enabled") or type(values) ~= "table" then
        return
    end
    if self.settings:get("debug#enabled") and self.settings:get("debug#simulateFailure") == "hook" then
        error("falha simulada (debug#simulateFailure=hook)")
    end
    if vehicle == nil or vehicle.spec_motorized == nil then
        return -- não motorizado (ex.: reboque): nada a fazer
    end
    local storeItem = screen and screen.storeItem
    if storeItem == nil then
        return
    end
    local snapshot = self.reader.read(vehicle, storeItem, self.logger)
    local data = self.service:get(snapshot)
    local rows = self.formatter.rows(data, self.text, {
        showPullingIndex = self.settings:get("ui#showPullingIndex"),
        loadRefWeightFraction = self.settings:get("metrics#loadRefWeightFraction"),
        logger = self.logger,
    })
    for _, row in ipairs(rows) do
        local profile = ShopConfigScreen.GUI_PROFILE and ShopConfigScreen.GUI_PROFILE[row.profile]
        if profile then
            table.insert(values, { profile = profile, value = row.text })
        end
    end
end

NS.adapters.ShopConfigAdapter = ShopConfigAdapter
