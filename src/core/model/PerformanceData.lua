-- PerformanceData: resultado da análise de um Snapshot. Cada métrica é um
-- Value: { value=number|string|table|nil, unit=string,
--          kind="declared"|"calculated"|"estimated"|"heuristic",
--          status="ok"|"unknown"|"insufficient"|"partial", reason=string|nil }
-- (drivetrain, F6, guarda um value composto {label, drivenWheels, drivenAxles}
-- porque é consumido por outros analyzers, não só exibido).
local NS = VehiclePerformance
NS.core = NS.core or {}
NS.core.model = NS.core.model or {}

local PerformanceData = {}
PerformanceData.__index = PerformanceData

--- Value com status="ok".
function PerformanceData.value(v, unit, kind)
    return { value = v, unit = unit, kind = kind, status = "ok" }
end

--- Value com status="unknown", value=nil.
function PerformanceData.unknown(unit, kind, reason)
    return { value = nil, unit = unit, kind = kind, status = "unknown", reason = reason }
end

--- new(snapshot) -> { identity, configuration, metrics={}, availability={missing={}} }
function PerformanceData.new(snapshot)
    local identity, configuration
    if type(snapshot) == "table" then
        identity = snapshot.identity
        configuration = snapshot.configuration
    end
    return setmetatable({
        identity = identity,
        configuration = configuration,
        metrics = {},
        availability = { missing = {} },
    }, PerformanceData)
end

function PerformanceData:set(id, value)
    self.metrics[id] = value
end

function PerformanceData:get(id)
    return self.metrics[id]
end

NS.core.model.PerformanceData = PerformanceData
