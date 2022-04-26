local Turret = ACF.RegisterTurretType("Vertical")

function Turret:OnLoaded()
    self.Name        = "Vertical Drive"
    self.Description = "A vertical turret drive."
    self.Model       = "models/sprops/cylinders/size_3/cylinder_6x66.mdl"
    self.minSize     = 1
    self.maxSize     = 25
end

function Turret:SetupInputs(List)
    List[#List + 1 ] = "Elevation"
end