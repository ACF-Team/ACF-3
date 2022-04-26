local Turret = ACF.RegisterTurretType("Horizontal")

function Turret:OnLoaded()
    self.Name        = "Horizontal Drive"
    self.Description = "A horizontal turret drive."
    self.Model       = "models/props_phx/construct/metal_plate_curve360.mdl"
    self.minSize     = 5
    self.maxSize     = 144
end

function Turret:SetupInputs(List)
    List[#List + 1 ] = "Bearing"
end