-- Fixture manual (sintética): mesma base de valtra_145_michelin, mas só com
-- o diferencial traseiro ({3,4 rodas}) — tração 4x2. Usada para o invariante
-- relativo "valtra_145 (4x4) > valtra_145_4x2 em F_tração" (spec Fase 2,
-- linhas 471 e 142).
return {
    schema = 1,
    identity = {
        xmlFilename = "Valtra_BH180.xml",
        name = "Valtra BH180 (4x2 sintético)",
        brand = "VALTRA",
        category = "tractorsMedium",
        typeName = "tractor",
    },
    configuration = { motorConfiguration = 1, wheelConfiguration = 2 },
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
            { ratio = 58.82130925870251 },
            { ratio = 54.56450398340167 },
            { ratio = 48.21979421788985 },
            { ratio = 41.46902302738527 },
            { ratio = 25.132741228718345 },
            { ratio = 20.734511513692635 },
        },
        gearGroups = {
            { ratio = 2.9673590504451037 },
            { ratio = 1.941747572815534 },
            { ratio = 1.3550135501355014 },
            { ratio = 1.0 },
        },
    },
    differentials = {
        { diffIndex1 = 3, diffIndex1IsWheel = true, diffIndex2 = 4, diffIndex2IsWheel = true },
    },
    wheels = {
        { restLoad = 2.8, fieldFriction = 0.95, frictionScale = 1.6 },
        { restLoad = 2.8, fieldFriction = 0.95, frictionScale = 1.6 },
        { restLoad = 2.2, fieldFriction = 0.95, frictionScale = 1.6 },
        { restLoad = 2.2, fieldFriction = 0.95, frictionScale = 1.6 },
    },
}
