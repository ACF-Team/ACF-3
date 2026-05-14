local ACF     = ACF
local Weapons = ACF.Classes.Weapons

Weapons.Register("FGL", {
	Name        = "Flare Launcher",
	Model       = "models/missiles/blackjellypod.mdl",
	Description = "Flare Launchers can fire flares much more rapidly than other launchers, but can't load any other ammo types.",
	MuzzleFlash = "gl_muzzleflash_noscale",
	ROFMod      = 0.6,
	Spread      = 1.5,
	Caliber	= {
		Base = 40,
		Min  = 40,
		Max  = 40,
	},
	Sound       = "acf_missiles/missiles/flare_launch.mp3",
	Cleanup     = "acf_flarelauncher",
	Blacklist   = { "AP", "APHE", "FL", "HE", "HEAT", "HP", "SM" },
	DefaultAmmo = "FLR",
	LimitConVar = {
		Name = "_acf_flarelauncher",
		Amount = 4,
		Text = "Maximum amount of ACF Flare Launchers a player can create."
	},
})

Weapons.RegisterItem("40mmFGL", "FGL", {
	Name		= "40mm Flare Launcher",
	Description	= "Put on an all-American fireworks show with this flare launcher: high fire rate, low distraction rate. Fill the air with flare. Careful of your reload time.",
	Model		= "models/missiles/blackjellypod.mdl",
	Caliber		= 40,
	Mass		= 75,
	Year		= 1970,
	MagSize		= 30,
	MagReload	= 10,
	Cyclic		= 300,
	Round = {
		MaxLength  = 9,
		PropLength = 0.025,
	},
	Preview = {
		FOV = 115,
	},
})

ACF.SetCustomAttachment("models/missiles/blackjellypod.mdl", "muzzle", Vector(6, 0, 3.2))

cleanup.Register("acf_flarelauncher")

if SERVER then return end

language.Add("Cleanup_acf_flarelauncher", "ACF Flare Launchers")
language.Add("Cleaned_acf_flarelauncher", "Cleaned up all ACF Flare Launchers")
language.Add("SBoxLimit__acf_flarelauncher", "You've reached the ACF Flare Launcher limit!")
