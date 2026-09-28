-- Fixture degenerada: motor com curva de torque de um único ponto (sem
-- peakPowerKw/peakTorque explícitos). MotorAnalyzer.peakPowerFromCurve deve
-- usar rpm*torque*pi/30 (VehicleMotor.lua:199-201). Sem mass/differentials/
-- wheels: as demais métricas (massa, tração, drivetrain, etc.) devem virar
-- unknown sem lançar erro.
return {
    schema = 1,
    identity = { xmlFilename = "single_point_curve.xml", name = "Curva de 1 ponto" },
    configuration = {},
    motor = {
        maxRpm = 2000,
        torqueCurve = {
            { rpm = 2000, torque = 0.5 },
        },
    },
}
