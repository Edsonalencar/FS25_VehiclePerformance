-- Fixture manual: Volvo FH (VolvoFH.xml:358-400). Variante "6x2_ferro": só o
-- primeiro eixo traseiro é motriz, rodas de ferro dianteiras (fieldFriction
-- offRoad=1.0). Curva de torque: normRpm/torque 0.45/0.5, 0.5/0.6, 0.59/0.7,
-- 0.72/1, 0.86/0.88, 1/0.7; rpm = normRpm*2200, torque = t*1.789. CVT 150.
-- Wheels: 1,2=dianteiras; 3,4=1º eixo traseiro (motriz); 5,6=2º eixo traseiro
-- (não motriz neste variante). Spec Fase 2, linhas 472-483.
return {
    schema = 1,
    identity = {
        xmlFilename = "VolvoFH.xml",
        name = "Volvo FH",
        brand = "VOLVO",
        category = "trucks",
        typeName = "truck",
    },
    configuration = { wheelConfiguration = 1 },
    declared = {},
    mass = { totalT = 13.311 },
    motor = {
        maxRpm = 2200,
        maxForwardGearRatio = 150,
        maxForwardSpeedMs = 85 / 3.6,
        torqueCurve = {
            { rpm = 990.0, torque = 0.8945 },
            { rpm = 1100.0, torque = 1.0734 },
            { rpm = 1298.0, torque = 1.2523 },
            { rpm = 1584.0, torque = 1.789 },
            { rpm = 1892.0, torque = 1.57432 },
            { rpm = 2200, torque = 1.2523 },
        },
    },
    differentials = {
        { diffIndex1 = 3, diffIndex1IsWheel = true, diffIndex2 = 4, diffIndex2IsWheel = true },
    },
    wheels = {
        { restLoad = 2.3, fieldFriction = 1.0, frictionScale = 2.1 },
        { restLoad = 2.3, fieldFriction = 1.0, frictionScale = 2.1 },
        { restLoad = 1.27, fieldFriction = 0.9, frictionScale = 5.6 },
        { restLoad = 1.27, fieldFriction = 0.9, frictionScale = 5.6 },
        { restLoad = 1.27, fieldFriction = 0.9, frictionScale = 5.6 },
        { restLoad = 1.27, fieldFriction = 0.9, frictionScale = 5.6 },
    },
}
