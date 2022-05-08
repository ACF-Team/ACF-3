local Turret = ACF.RegisterTurretType("Horizontal")

function Turret:OnLoaded()
    self.Name        = "Horizontal Drive"
    self.Description = "A horizontal turret drive."
    self.Model       = "models/props_phx/construct/metal_plate_curve360.mdl"
    self.ModelSmall  = "models/holograms/hq_cylinder.mdl" -- Model used for diameters < 12in
    self.minSize     = 2
    self.maxSize     = 512
    self.defaultSize = 60
    self.RatioScale  = 0.1 -- Height modifier for total size, e.g. 12u diameter ring, RatioScale = 2, 24u tall ring

    self.BaseSpeed   = 56 -- deg/s at the size below, faster if smaller size, slower if larger size (post spawn)
    self.BaseAccel   = 2
    self.BaseScaleDiameter   = 60 -- Size to scale speed against
    self.minMass     = 50 -- Mass allowed at the minimum size
    self.maxMass     = 200000 -- Mass allowed at the maximum size

    -- Mass of the ring itself, scaling to size
    self.Mass = 200
end

function Turret:SetupInputs(List)
    List[#List + 1 ] = "Bearing (Local amount of degrees from center)"
end
