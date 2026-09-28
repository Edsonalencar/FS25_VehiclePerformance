-- Fixture manual: Volvo FH (VolvoFH.xml:358-400). Variante "6x4_alcoa": os
-- dois eixos traseiros são motrizes (diff central conectando os dois eixos),
-- rodas de liga dianteiras (fieldFriction street=0.9). Mesma curva/motor de
-- volvo_6x2_ferro. Spec Fase 2, linhas 472-483.
return {
    schema = 1,
    identity = {
        xmlFilename = "VolvoFH.xml",
        name = "Volvo FH",
        brand = "VOLVO",
        category = "trucks",
        typeName = "truck",
    },
    configuration = { wheelConfiguration = 2 },
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
        { diffIndex1 = 5, diffIndex1IsWheel = true, diffIndex2 = 6, diffIndex2IsWheel = true },
        { diffIndex1 = 3, diffIndex1IsWheel = true, diffIndex2 = 4, diffIndex2IsWheel = true },
        { diffIndex1 = 0, diffIndex1IsWheel = false, diffIndex2 = 1, diffIndex2IsWheel = false },
    },
    wheels = {
        { restLoad = 2.3, fieldFriction = 0.9, frictionScale = 2.1 },
        { restLoad = 2.3, fieldFriction = 0.9, frictionScale = 2.1 },
        { restLoad = 1.27, fieldFriction = 0.9, frictionScale = 5.6 },
        { restLoad = 1.27, fieldFriction = 0.9, frictionScale = 5.6 },
        { restLoad = 1.27, fieldFriction = 0.9, frictionScale = 5.6 },
        { restLoad = 1.27, fieldFriction = 0.9, frictionScale = 5.6 },
    },
}
