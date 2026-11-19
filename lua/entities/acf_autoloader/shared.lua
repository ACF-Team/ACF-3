DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName      = "ACF Autoloader"
ENT.WireDebugName  = "ACF Autoloader"
ENT.PluralName     = "ACF Autoloaders"
ENT.ACF_Limit      = 2
ENT.ACF_PreventArmoring = true

ENT.IsACFAutoloader = true

ACF.Entities.AutoRegister(2026091001, function()
	MENU_FIELD("Number", "AutoloaderCaliber", { Title = "#acf.menu.fields.acf_autoloader.autoloader_caliber", Min = ACF.MinAutoloaderCaliber, Max = ACF.MaxAutoloaderCaliber, Default = ACF.MinAutoloaderCaliber, Decimals = 2 })
	MENU_FIELD("Number", "AutoloaderLength",  { Title = "#acf.menu.fields.acf_autoloader.autoloader_length", Min = ACF.MinAutoloaderLength,  Max = ACF.MaxAutoloaderLength,  Default = 1, Decimals = 2 })
	MENU_FIELD("String", "SoundPath",         { Title = "#acf.menu.fields.acf_autoloader.sound_path", Default = "" }) -- Silent by default, set with the ACF sound tool
	MENU_FIELD("Number", "SoundPitch",        { Title = "#acf.menu.fields.acf_autoloader.sound_pitch", Min = 0.1, Max = 2, Default = 1, Decimals = 2 })
	MENU_FIELD("Number", "SoundVolume",       { Title = "#acf.menu.fields.acf_autoloader.sound_volume", Min = 0.1, Max = 1, Default = 1, Decimals = 2 })
	LINKED_ENTITY_FIELD("Gun",        { AcceptableClasses = { acf_gun = true, acf_rack = true } })
	LINKED_ENTITY_ARRAY_FIELD("AmmoCrates", { AcceptableClasses = { acf_ammo = true } })
end)
