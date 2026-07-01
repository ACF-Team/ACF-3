DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName      = "ACF Autoloader"
ENT.WireDebugName  = "ACF Autoloader"
ENT.PluralName     = "ACF Autoloaders"
ENT.ACF_Limit      = 2
ENT.ACF_PreventArmoring = true

ENT.IsACFAutoloader = true

ACF.Entities.AutoRegisterV2(function()
	MENU_FIELD("Number", "AutoloaderCaliber", { Min = ACF.MinAutoloaderCaliber, Max = ACF.MaxAutoloaderCaliber, Default = 1, Decimals = 2 })
	MENU_FIELD("Number", "AutoloaderLength",  { Min = ACF.MinAutoloaderLength,  Max = ACF.MaxAutoloaderLength,  Default = 1, Decimals = 2 })
	LINKED_ENTITY_FIELD("Gun",        { AcceptableClasses = { acf_gun = true, acf_rack = true } })
	LINKED_ENTITY_ARRAY_FIELD("AmmoCrates", { AcceptableClasses = { acf_ammo = true } })
end)
