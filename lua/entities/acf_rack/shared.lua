DEFINE_BASECLASS("acf_base_simple")

ENT.Author      = "Bubbus"
ENT.IsACFWeapon = true

ACF.Entities.AutoRegister(2026091001, function(CLASS)
	-- The rack/launcher type this entity represents (ACF.Racks.*). The missiles it loads come from
	-- linked crates, not from a field here.
	MENU_FIELD("ACF.Racks.BaseRack", "Rack", {Title = "#acf.menu.fields.acf_rack.rack", OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.Racks.1xRK"})
	MENU_FIELD("Number", "BreechIndex", {Title = "#acf.menu.fields.acf_rack.breech_index", Min = 1, Default = 1, Decimals = 0})
	LINKED_ENTITY_FIELD("Radar", {AcceptableClasses = {acf_radar = true}})
	LINKED_ENTITY_FIELD("Computer", {AcceptableClasses = {acf_computer = true}})
	LINKED_ENTITY_ARRAY_FIELD("Crates", {AcceptableClasses = {acf_ammo = true}})

	function CLASS:VerifyData()
	end
end, "Rack", "Racks")

-- Returns the rack/launcher instance backing this entity.
function ENT:GetRack()
	return self:ACF_GetUserVar("Rack")
end
