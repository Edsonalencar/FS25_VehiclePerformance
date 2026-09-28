-- Fixture manual: Ford (7630.xml). Variante "auto_largo": CVT, pneus largos.
-- Curva de torque normalizada (normRpm/torque): 0.45/0.9, 0.5/0.97, 0.59/1,
-- 0.72/1, 0.86/0.88, 1/0.72; rpm = normRpm*maxRpm (2200), torque = t*torqueScale
-- (0.85). Valores calculados fora e gravados já resolvidos (spec Fase 2,
-- linhas 447-453).
return {
    schema = 1,
    identity = {
        xmlFilename = "7630.xml",
        name = "Ford 7630",
        brand = "FORD",
        category = "tractorsMedium",
        typeName = "tractor",
    },
    configuration = { motorConfiguration = 1, wheelConfiguration = 1 },
    declared = { powerHp = 200 },
    mass = { totalT = 5.062 },
    motor = {
        maxRpm = 2200,
        maxForwardGearRatio = 250,
        maxForwardSpeedMs = 40 / 3.6,
        torqueCurve = {
            { rpm = 990.0, torque = 0.765 },
            { rpm = 1100.0, torque = 0.8245 },
            { rpm = 1298.0, torque = 0.85 },
            { rpm = 1584.0, torque = 0.85 },
            { rpm = 1892.0, torque = 0.748 },
            { rpm = 2200, torque = 0.612 },
        },
    },
    differentials = {
        { diffIndex1 = 1, diffIndex1IsWheel = true, diffIndex2 = 2, diffIndex2IsWheel = true },
        { diffIndex1 = 3, diffIndex1IsWheel = true, diffIndex2 = 4, diffIndex2IsWheel = true },
        { diffIndex1 = 0, diffIndex1IsWheel = false, diffIndex2 = 1, diffIndex2IsWheel = false },
    },
    wheels = {
        { restLoad = 2.8, fieldFriction = 0.95, frictionScale = 1.6 },
        { restLoad = 2.8, fieldFriction = 0.95, frictionScale = 1.6 },
        { restLoad = 2.7, fieldFriction = 0.95, frictionScale = 1.6 },
        { restLoad = 2.7, fieldFriction = 0.95, frictionScale = 1.6 },
    },
}
