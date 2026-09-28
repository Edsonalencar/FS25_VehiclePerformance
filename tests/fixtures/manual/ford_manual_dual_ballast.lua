-- Fixture manual: Ford (7630.xml). Variante "manual_dual_ballast": marchas
-- manuais, rodas duplas traseiras e lastro. Marchas: ratio = maxRpm*pi /
-- ((kmh/3.6)*30) para 10/20/30/40 km/h (maxRpm=2500); grupos {1/0.5, 1/1.0}.
-- Valores calculados fora e gravados já resolvidos (spec Fase 2, linhas 454-459).
return {
    schema = 1,
    identity = {
        xmlFilename = "7630.xml",
        name = "Ford 7630",
        brand = "FORD",
        category = "tractorsMedium",
        typeName = "tractor",
    },
    configuration = { motorConfiguration = 2, wheelConfiguration = 2 },
    declared = { powerHp = 250 },
    mass = { totalT = 9.497 },
    motor = {
        maxRpm = 2500,
        maxForwardSpeedMs = 40 / 3.6,
        torqueCurve = {
            { rpm = 1125.0, torque = 0.855 },
            { rpm = 1250.0, torque = 0.9215 },
            { rpm = 1475.0, torque = 0.95 },
            { rpm = 1800.0, torque = 0.95 },
            { rpm = 2150.0, torque = 0.836 },
            { rpm = 2500, torque = 0.684 },
        },
        forwardGears = {
            { ratio = 94.2477796076938 }, -- 10 km/h
            { ratio = 47.1238898038469 }, -- 20 km/h
            { ratio = 31.415926535897928 }, -- 30 km/h
            { ratio = 23.56194490192345 }, -- 40 km/h
        },
        gearGroups = {
            { ratio = 2.0 }, -- 1/0.5
            { ratio = 1.0 }, -- 1/1.0
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
        { restLoad = 4.043, fieldFriction = 0.95, frictionScale = 1.6, additionalCount = 1 },
        { restLoad = 4.043, fieldFriction = 0.95, frictionScale = 1.6, additionalCount = 1 },
    },
}
