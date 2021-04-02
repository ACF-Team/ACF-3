local Turret = ACF.RegisterTurretType("Horizontal")

function Turret:OnLoaded()
    self.Name        = "Horizontal Drive"
    self.Description = "A horizontal turret drive."
    self.Model       = "models/sprops/geometry/fring_48.mdl"
end

function Turret:SetupInputs(List)
    List[#List + 1 ] = "Bearing"
end