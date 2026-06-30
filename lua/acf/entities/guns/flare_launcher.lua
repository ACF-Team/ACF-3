local ACF     = ACF

ACF.Classes.DefineClass("ACF.Guns.FlareLauncher", "ACF.Guns.BaseGun", function()
	CLASS.Name        	= "Flare Launcher"
	CLASS.ID          	= "FGL"
	CLASS.IsWeapon		= true
	CLASS.Model       	= "models/missiles/blackjellypod.mdl"
	CLASS.Description 	= "Flare Launchers can fire flares much more rapidly than other launchers, but can't load any other ammo types."
	CLASS.MuzzleFlash 	= "gl_muzzleflash_noscale"
	CLASS.ROFMod      	= 0.6
	CLASS.Spread      	= 1.5
	CLASS.CaliberLimits	= {
		Base = 40,
		Min  = 40,
		Max  = 40,
	}
	CLASS.Sound       	= "acf_missiles/missiles/flare_launch.mp3"
	CLASS.Cleanup     	= "acf_flarelauncher"
	CLASS.Blacklist   	= {
		["ACF.Ammunition.AP"] = true,
		["ACF.Ammunition.APHE"] = true,
		["ACF.Ammunition.FL"] = true,
		["ACF.Ammunition.HE"] = true,
		["ACF.Ammunition.HEAT"] = true,
		["ACF.Ammunition.HP"] = true,
		["ACF.Ammunition.SM"] = true
	}
	CLASS.DefaultAmmo 	= "ACF.Ammunition.FLR"
	CLASS.LimitConVar 	= {
		Name = "_acf_flarelauncher",
		Amount = 4,
		Text = "Maximum amount of ACF Flare Launchers a player can create."
	}
end)

ACF.Classes.DefineClass("ACF.Guns.40mmFlareLauncher", "ACF.Guns.FlareLauncher", function()
	CLASS.Name				= "40mm Flare Launcher"
	CLASS.ID				= "40mmFGL"
	CLASS.IsWeaponOption	= true
	CLASS.Description		= "Put on an all-American fireworks show with this flare launcher: high fire rate, low distraction rate. Fill the air with flare. Careful of your reload time."
	CLASS.Model				= "models/missiles/blackjellypod.mdl"
	CLASS.Caliber			= 40
	CLASS.Mass				= 75
	CLASS.Year				= 1970
	CLASS.MagSize			= 30
	CLASS.MagReload			= 10
	CLASS.Cyclic			= 300
	CLASS.Round 			= {
		MaxLength  				= 9,
		PropLength 				= 0.025,
	}
	CLASS.Preview 			= {
		FOV = 115,
	}
end)

ACF.SetCustomAttachment("models/missiles/blackjellypod.mdl", "muzzle", Vector(6, 0, 3.2))

cleanup.Register("acf_flarelauncher")

if SERVER then return end

language.Add("Cleanup_acf_flarelauncher", "ACF Flare Launchers")
language.Add("Cleaned_acf_flarelauncher", "Cleaned up all ACF Flare Launchers")
language.Add("SBoxLimit__acf_flarelauncher", "You've reached the ACF Flare Launcher limit!")