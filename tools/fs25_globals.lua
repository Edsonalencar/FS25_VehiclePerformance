-- Lista somente-leitura dos globais do FS25 usados pelos adapters e por main.lua.
-- Cresce conforme novos adapters usarem novas APIs do jogo (F3+).
return {
    "g_shopConfigScreen", "ShopConfigScreen", "g_i18n", "g_modIsLoaded", "g_modManager", "g_brandManager",
    "g_storeManager", "g_dedicatedServer", "g_currentModDirectory", "g_currentModName", "g_modSettingsDirectory",
    "WheelsUtil", "Utils", "XMLFile", "Logging", "addModEventListener", "addConsoleCommand",
    "removeConsoleCommand", "source", "getTimeSec", "createFolder", "getfenv",
}
