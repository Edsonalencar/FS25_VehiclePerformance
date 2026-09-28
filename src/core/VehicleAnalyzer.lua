-- VehicleAnalyzer.analyze(snapshot, opts) -> PerformanceData.
-- Roda os analyzers/metrics numa ordem fixa; cada passo só lê métricas de
-- passos anteriores. Nunca deixa um erro Lua escapar: cada passo roda
-- protegido por pcall, e um passo que falhar simplesmente não preenche suas
-- métricas (ficam ausentes, tratadas como unknown pelos passos seguintes).
local NS = VehiclePerformance
NS.core = NS.core or {}

local PerformanceData = NS.core.model.PerformanceData
local Snapshot = NS.core.model.Snapshot

local VehicleAnalyzer = {}

local STEPS = {
    NS.core.analyzers.MotorAnalyzer,
    NS.core.analyzers.MassAnalyzer,
    NS.core.analyzers.TransmissionAnalyzer,
    NS.core.analyzers.DifferentialAnalyzer,
    NS.core.analyzers.WheelAnalyzer,
    NS.core.analyzers.TractionAnalyzer,
    NS.core.metrics.PowerToWeightMetric,
    NS.core.metrics.TractionMetric,
    NS.core.metrics.LoadPerformanceMetric,
    NS.core.metrics.PullingPerformanceMetric,
}

--- @param snapshot table Snapshot schema 1
--- @param opts {loadRefWeightFraction:number, pullingRefKN:number}|nil
--- @return table PerformanceData
function VehicleAnalyzer.analyze(snapshot, opts)
    opts = opts or {}
    local data = PerformanceData.new(snapshot)
    local _, missing = Snapshot.validate(snapshot)
    data.availability.missing = missing

    for _, step in ipairs(STEPS) do
        -- Passo individual que falhar simplesmente deixa suas métricas
        -- ausentes (equivalente a unknown); analyze nunca propaga o erro.
        pcall(step.analyze, snapshot, data, opts)
    end

    return data
end

NS.core.VehicleAnalyzer = VehicleAnalyzer
