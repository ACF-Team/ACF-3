local Turret = ACF.RegisterTurretType("Vertical")

function Turret:OnLoaded()
    self.Name        = "Vertical Drive"
    self.Description = "A vertical turret drive."
    self.Model       = "models/sprops/misc/tubes/size_5/tube_96x24.mdl"
end

function Turret:SetupInputs(List)
    List[#List + 1 ] = "Elevation"
end