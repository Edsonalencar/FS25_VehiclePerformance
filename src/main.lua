-- FS25_VehiclePerformance — ponto de entrada único (extraSourceFiles)
local MOD_DIR = g_currentModDirectory
local MOD_NAME = g_currentModName

VehiclePerformance = {
    MOD_DIR = MOD_DIR,
    MOD_NAME = MOD_NAME,
    VERSION = "1.0.0",
    core = {},
    app = {},
    adapters = {},
    api = {},
}

source(MOD_DIR .. "manifest.lua")
for _, rel in ipairs(VehiclePerformance.manifest) do
    source(MOD_DIR .. rel)
end

VehiclePerformance.adapters.GameBootstrap.install(VehiclePerformance)
