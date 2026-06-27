DEFINE_BASECLASS("acf_base_simple")

ENT.Author = "Polymorphic Turtle"

ACF.Entities.AutoRegisterV2(function()
	-- The component (computer) type this entity represents (ACF.Components.* guidance computers).
	MENU_FIELD("ACF.Components.BaseComponent", "Computer", {OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.Components.LaserGuidanceComputer"})

	function CLASS:VerifyData()
	end
end, "Computer", "Computers")

-- Returns the component instance backing this entity.
function ENT:GetComputer()
	return self:ACF_GetUserVar("Computer")
end
