local Turret = ACF.RegisterTurretType("Vertical")

function Turret:OnLoaded()
    self.Name        = "Vertical Drive"
    self.Description = "A vertical turret drive."
    self.Model       = "models/holograms/hq_cylinder.mdl"

    self.minSize     = 1
    self.maxSize     = 36
    self.defaultSize = 12
    self.RatioScale  = 2 -- Height modifier for total size, e.g. 12u diameter ring, RatioScale = 2, 24u tall ring

    self.BaseSpeed   = 8 -- deg/s at the size below, faster if smaller size, slower if larger size (post spawn)
    self.BaseAccel   = 0.5
    self.BaseScaleDiameter   = 60 -- Size to scale speed against
    self.minMass     = 30 -- Mass allowed at the minimum size
    self.maxMass     = 40000 -- Mass allowed at the maximum size

    -- Mass of the ring itself, scaling to size
    self.Mass = 100
end

function Turret:SetupInputs(List)
    List[#List + 1 ] = "Elevation (Local amount of degrees from center)"
end
