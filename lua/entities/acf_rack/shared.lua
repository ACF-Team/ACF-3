DEFINE_BASECLASS("acf_base_simple")

ENT.Author      = "Bubbus"
ENT.IsACFWeapon = true

ACF.Entities.AutoRegisterV2(function()
	-- The rack/launcher type this entity represents (ACF.Racks.*). The missiles it loads come from
	-- linked crates, not from a field here.
	MENU_FIELD("ACF.Racks.BaseRack", "Rack", {OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.Racks.1xRK"})
	MENU_FIELD("Number", "BreechIndex", {Min = 1, Default = 1, Decimals = 0})

	function CLASS:VerifyData()
	end
end, "Rack", "Racks")

-- Returns the rack/launcher instance backing this entity.
function ENT:GetRack()
	return self:ACF_GetUserVar("Rack")
end
