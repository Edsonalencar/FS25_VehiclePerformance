-- Fixture manual: Valtra BH180 (Valtra_BH180.xml:471-527). Variante
-- "205_michelin": torqueScale=0.92, declared 205 cv, 4x4 (mesmos
-- diferenciais/marchas de valtra_145_michelin, só muda a curva de torque e
-- o hp declarado). Spec Fase 2, linhas 460-470.
return {
    schema = 1,
    identity = {
        xmlFilename = "Valtra_BH180.xml",
        name = "Valtra BH180",
        brand = "VALTRA",
        category = "tractorsMedium",
        typeName = "tractor",
    },
    configuration = { motorConfiguration = 2, wheelConfiguration = 1 },
    declared = { powerHp = 205 },
    mass = { totalT = 10.207 },
    motor = {
        maxRpm = 2200,
        maxForwardSpeedMs = 40 / 3.6,
        torqueCurve = {
            { rpm = 990.0, torque = 0.8280000000000001 },
            { rpm = 1100.0, torque = 0.8924 },
            { rpm = 1298.0, torque = 0.92 },
            { rpm = 1584.0, torque = 0.92 },
            { rpm = 1892.0, torque = 0.8096 },
            { rpm = 2200, torque = 0.6624 },
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
