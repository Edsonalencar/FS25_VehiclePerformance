-- Fixture manual: Valtra BH180 (Valtra_BH180.xml:471-527). Variante
-- "145_michelin": torqueScale=0.601, declared 145 cv, 4x4 (mesmos
-- diferenciais do Ford). Curva igual à do Ford (maxRpm=2200). Marchas
-- 14.1/15.2/17.2/20/33/40 km/h, grupos 1/{0.337,0.515,0.738,1}. Valores
-- calculados fora e gravados já resolvidos (spec Fase 2, linhas 460-470).
return {
    schema = 1,
    identity = {
        xmlFilename = "Valtra_BH180.xml",
        name = "Valtra BH180",
        brand = "VALTRA",
        category = "tractorsMedium",
        typeName = "tractor",
    },
    configuration = { motorConfiguration = 1, wheelConfiguration = 1 },
    declared = { powerHp = 145 },
    mass = { totalT = 10.207 },
    motor = {
        maxRpm = 2200,
        maxForwardSpeedMs = 40 / 3.6,
        torqueCurve = {
            { rpm = 990.0, torque = 0.5409 },
            { rpm = 1100.0, torque = 0.58297 },
            { rpm = 1298.0, torque = 0.601 },
            { rpm = 1584.0, torque = 0.601 },
            { rpm = 1892.0, torque = 0.52888 },
            { rpm = 2200, torque = 0.43272 },
        },
        forwardGears = {
            { ratio = 58.82130925870251 }, -- 14.1 km/h
            { ratio = 54.56450398340167 }, -- 15.2 km/h
            { ratio = 48.21979421788985 }, -- 17.2 km/h
            { ratio = 41.46902302738527 }, -- 20 km/h
            { ratio = 25.132741228718345 }, -- 33 km/h
            { ratio = 20.734511513692635 }, -- 40 km/h
        },
        gearGroups = {
            { ratio = 2.9673590504451037 }, -- 1/0.337
            { ratio = 1.941747572815534 }, -- 1/0.515
            { ratio = 1.3550135501355014 }, -- 1/0.738
            { ratio = 1.0 }, -- 1/1
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
        { restLoad = 2.2, fieldFriction = 0.95, frictionScale = 1.6 },
        { restLoad = 2.2, fieldFriction = 0.95, frictionScale = 1.6 },
    },
}
