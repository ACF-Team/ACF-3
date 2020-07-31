--define the class
ACF_defineGunClass("GL", {
	spread = 0.28,
	name = "Grenade Launcher",
	desc = "Grenade Launchers can fire shells with relatively large payloads at a fast rate, but with very limited velocities and poor accuracy.",
	muzzleflash = "gl_muzzleflash_noscale",
	rofmod = 1,
	sound = "acf_base/weapons/grenadelauncher.mp3",
	soundDistance = " ",
	soundNormal = " "
} )

--add a gun to the class
ACF_defineGun("40mmGL", { --id
	name = "40mm Grenade Launcher",
	desc = "The 40mm chews up infantry but is about as useful as tits on a nun for fighting armor.  Often found on 4x4s rolling through the third world.",
	model = "models/launcher/40mmgl.mdl",
	gunclass = "GL",
	caliber = 4.0,
	weight = 55,
	magsize = 30,
	magreload = 7.5,
	year = 1970,
	Cyclic = 200,
	round = {
		maxlength = 7.5,
		propweight = 0.01
	}
} )
