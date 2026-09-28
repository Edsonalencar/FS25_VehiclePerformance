-- Fixture degenerada: veículo sem motor (motor=nil). Todos os F1-F4, F7, F8
-- devem virar unknown sem lançar erro; F5/F6/F9 (independentes do motor)
-- continuam calculáveis.
return {
    schema = 1,
    identity = { xmlFilename = "no_motor.xml", name = "Sem motor" },
    configuration = {},
    declared = { powerHp = 100 },
    mass = { totalT = 5.0 },
    motor = nil,
    differentials = {
        { diffIndex1 = 1, diffIndex1IsWheel = true, diffIndex2 = 2, diffIndex2IsWheel = true },
    },
    wheels = {
        { restLoad = 2.5, fieldFriction = 0.9, frictionScale = 1.5 },
        { restLoad = 2.5, fieldFriction = 0.9, frictionScale = 1.5 },
    },
}
