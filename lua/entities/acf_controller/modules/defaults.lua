do
    -- Values default to zero anyways so only specify nonzero here
    local Defaults = {
        SmokeFuse = 0.5,

        ZoomSpeed = 10,
        ZoomMin = 5,
        ZoomMax = 90,
        SlewMin = 1,
        SlewMax = 1,

        CamCount = 2,
        Cam1Offset = Vector(0, 0, 150),
        Cam1Orbit = 300,
        Cam2Offset = Vector(0, 0, 150),
        Cam2Orbit = 0,
        Cam3Offset = Vector(0, 0, 0),
        Cam3Orbit = 0,

        HUDType = 1,
        HUDScale = 1,
        HUDColor = Vector(1, 0.5, 0),
        HUDColor2 = Vector(1, 0.5, 0),

        BrakeStrength = 300,
        SpeedTop = 60,

        ShiftTime = 100,
    }
    return Defaults
end