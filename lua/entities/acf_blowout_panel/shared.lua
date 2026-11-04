DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName      = "ACF Blow-out Panel"
ENT.WireDebugName  = "ACF Blow-out Panel"
ENT.PluralName     = "ACF Blow-out Panels"
ENT.ACF_Limit      = 4
ENT.ConvexMaterial = "RHA"

--- @return boolean # Whether the panel has blown out and is waiting to be refitted.
function ENT:IsBlownOut()
	return self:GetNW2Bool("ACF_BlownOut", false)
end

ACF.Entities.AutoRegister(2026091001, function()
	MENU_FIELD("Number", "PanelLength",    { Min = ACF.ContainerMinSize, Max = ACF.ContainerMaxSize, Default = 24, Decimals = 2 })
	MENU_FIELD("Number", "PanelWidth",     { Min = ACF.ContainerMinSize, Max = ACF.ContainerMaxSize, Default = 24, Decimals = 2 })
	MENU_FIELD("Number", "PanelThickness", { Min = 5, Max = ACF.BlowoutPanelMaxThickness, Default = 20, Decimals = 0 }) -- mm
	LINKED_ENTITY_ARRAY_FIELD("AmmoCrates", { AcceptableClasses = { acf_ammo = true } })
end, "Blow-out Panel")
