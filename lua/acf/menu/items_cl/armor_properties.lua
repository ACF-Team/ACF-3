local ACF = ACF
local MinimumArmor = ACF.MinimumArmor
local MaximumArmor = ACF.MaxThickness

hook.Add("ACF_OnUpdateServerData", "ACF_ArmorToolMenu_MaxThickness", function(_, Key, Value)
	if Key ~= "MaxThickness" then return end

	MaximumArmor = math.floor(ACF.CheckNumber(Value, ACF.MaxThickness))
end)

--- Generates the menu used in the Armor Properties tool.
--- @param Panel panel The base panel to build the menu off of.
function ACF.CreateArmorPropertiesMenu(Panel)
	local Menu = ACF.InitMenuBase(Panel, "ArmorPropertiesMenu", "acf_reload_armor_properties_menu")
	local Presets = Menu:AddPanel("ControlPresets")
	Presets:AddConVar("acfarmorprop_thickness")
	Presets:AddConVar("acfarmorprop_ductility")
	Presets:SetPreset("acfarmorprop")

	local ThicknessSlider = Menu:AddSlider("#tool.acfarmorprop.thickness", MinimumArmor, MaximumArmor, 2)
	ThicknessSlider:SetConVar("acfarmorprop_thickness")
	Menu:AddHelp("#tool.acfarmorprop.thickness_desc")

	local DuctilitySlider = Menu:AddSlider("#tool.acfarmorprop.ductility", ACF.MinDuctility, ACF.MaxDuctility, 2)
	DuctilitySlider:SetConVar("acfarmorprop_ductility")
	Menu:AddHelp("#tool.acfarmorprop.ductility_desc")

	local SphereCheck = Menu:AddCheckBox("#tool.acfarmorprop.sphere_search", "acfarmorprop_sphere_search")
	Menu:AddHelp("#tool.acfarmorprop.sphere_search_desc")

	local SphereRadius = Menu:AddSlider("#tool.acfarmorprop.sphere_search_radius", 0, 2000, 0)
	SphereRadius:SetConVar("acfarmorprop_sphere_radius")
	Menu:AddHelp("#tool.acfarmorprop.sphere_search_radius_desc")

	function SphereCheck:OnChange(Bool)
		SphereRadius:SetEnabled(Bool)
	end

	SphereRadius:SetEnabled(SphereCheck:GetChecked())
end