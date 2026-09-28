-- Fixture degenerada: veículo de 4 rodas com um diferencial referenciando o
-- índice de roda 9 (fora do intervalo 1..4). DifferentialAnalyzer deve
-- devolver unknown/"bad_wheel_index", e as métricas que dependem de F6 (F9,
-- F10 parcial via F8, F11, F12) devem degradar sem lançar erro.
return {
    schema = 1,
    identity = { xmlFilename = "bad_diff.xml", name = "Diferencial inválido" },
    configuration = {},
    declared = { powerHp = 150 },
    mass = { totalT = 6.0 },
    motor = {
        maxRpm = 2200,
        maxForwardGearRatio = 200,
        maxForwardSpeedMs = 40 / 3.6,
        torqueCurve = {
            { rpm = 990.0, torque = 0.6 },
            { rpm = 2200, torque = 0.5 },
        },
    },
    differentials = {
        { diffIndex1 = 9, diffIndex1IsWheel = true, diffIndex2 = 2, diffIndex2IsWheel = true },
    },
    wheels = {
        { restLoad = 2.5, fieldFriction = 0.9, frictionScale = 1.5 },
        { restLoad = 2.5, fieldFriction = 0.9, frictionScale = 1.5 },
        { restLoad = 2.5, fieldFriction = 0.9, frictionScale = 1.5 },
        { restLoad = 2.5, fieldFriction = 0.9, frictionScale = 1.5 },
    },
}
