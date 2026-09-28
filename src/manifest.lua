-- Ordem de carga fixa. Lida por main.lua, tests/support/load.lua e tools/build.py.
VehiclePerformance.manifest = {
    "app/SafeCall.lua",
    "app/StateMachine.lua",
    -- Fase 4: PerformanceService/RowFormatter viriam depois de
    -- app/ConfigurationResolver.lua (Fase 3, ainda não mesclada neste
    -- worktree). Posição provisória; o orquestrador reordena ao mesclar as
    -- fases.
    "app/PerformanceService.lua",
    "app/RowFormatter.lua",
    "adapters/GameLogger.lua",
    "adapters/HookRegistry.lua",
    "adapters/SettingsStore.lua",
    "adapters/GameText.lua",
    "adapters/ShopConfigAdapter.lua",
    "adapters/GameBootstrap.lua",
}
