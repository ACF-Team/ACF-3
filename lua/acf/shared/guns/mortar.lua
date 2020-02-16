--define the class
ACF_defineGunClass("MO", {
	spread = 0.64,
	name = "Mortar",
	desc = "Mortars are able to fire shells with usefull payloads from a light weight gun, at the price of limited velocities.",
	muzzleflash = "mortar_muzzleflash_noscale",
	rofmod = 2.5,
	sound = "weapons/ACF_Gun/mortar_new.mp3",
	soundDistance = "Mortar.Fire",
	soundNormal = " "
})

--add a gun to the class
--id
ACF_defineGun("60mmM", {
	name = "60mm Mortar",
	desc = "The 60mm is a common light infantry support weapon, with a high rate of fire but a puny payload.",
	model = "models/mortar/mortar_60mm.mdl",
	gunclass = "MO",
	caliber = 6.0,
	weight = 60,
	rofmod = 1.25,
	year = 1930,
	round = {
		maxlength = 20,
		propweight = 0.037
	}
})

ACF_defineGun("80mmM", {
	name = "80mm Mortar",
	desc = "The 80mm is a common infantry support weapon, with a good bit more boom than its little cousin.",
	model = "models/mortar/mortar_80mm.mdl",
	gunclass = "MO",
	caliber = 8.0,
	weight = 120,
	year = 1930,
	round = {
		maxlength = 28,
		propweight = 0.055
	}
})

ACF_defineGun("120mmM", {
	name = "120mm Mortar",
	desc = "The versatile 120 is sometimes vehicle-mounted to provide quick boomsplat to support the infantry.  Carries more boom in its boomsplat, has good HEAT performance, and is more accurate in high-angle firing.",
	model = "models/mortar/mortar_120mm.mdl",
	gunclass = "MO",
	caliber = 12.0,
	weight = 640,
	year = 1935,
	round = {
		maxlength = 45,
		propweight = 0.175
	}
})

ACF_defineGun("150mmM", {
	name = "150mm Mortar",
	desc = "The perfect balance between the 120mm and the 200mm. Can prove a worthy main gun weapon, as well as a mighty good mortar emplacement",
	model = "models/mortar/mortar_150mm.mdl",
	gunclass = "MO",
	caliber = 15.0,
	weight = 1255,
	year = 1945,
	round = {
		maxlength = 58,
		propweight = 0.235
	}
})

ACF_defineGun("200mmM", {
	name = "200mm Mortar",
	desc = "The 200mm is a beast, often used against fortifications.  Though enormously powerful, feel free to take a nap while it reloads",
	model = "models/mortar/mortar_200mm.mdl",
	gunclass = "MO",
	caliber = 20.0,
	weight = 2850,
	year = 1940,
	round = {
		maxlength = 80,
		propweight = 0.330
	}
})
--[[
ACF_defineGun("280mmM", {
	name = "280mm Mortar",
	desc = "Massive payload, with a reload time to match. Found in rare WW2 siege artillery pieces. It's the perfect size for a jeep.",
	model = "models/mortar/mortar_280mm.mdl",
	gunclass = "MO",
	caliber = 28.0,
	weight = 9035,
	year = 1945,
	round = {
		maxlength = 138,
		propweight = 0.462 
	}
} )
]]
--

ACF.RegisterWeaponClass("MO", {
	Name		  = "Mortar",
	Description	  = "Mortars are able to fire shells with usefull payloads from a light weight gun, at the price of limited velocities.",
	MuzzleFlash	  = "mortar_muzzleflash_noscale",
	ROFMod		  = 2.5,
	Spread		  = 0.64,
	Sound		  = "weapons/ACF_Gun/mortar_new.mp3",
	soundDistance = "Mortar.Fire",
	soundNormal	  = " ",
})

ACF.RegisterWeapon("60mmM", "MO", {
	Name		= "60mm Mortar",
	Description	= "The 60mm is a common light infantry support weapon, with a high rate of fire but a puny payload.",
	Model		= "models/mortar/mortar_60mm.mdl",
	Caliber		= 60,
	Mass		= 60,
	Year		= 1930,
	ROFMod		= 1.25,
	Round = {
		MaxLength = 20,
		PropMass  = 0.037,
	}
})

ACF.RegisterWeapon("80mmM", "MO", {
	Name		= "80mm Mortar",
	Description	= "The 80mm is a common infantry support weapon, with a good bit more boom than its little cousin.",
	Model		= "models/mortar/mortar_80mm.mdl",
	Caliber		= 80,
	Mass		= 120,
	Year		= 1930,
	Round = {
		MaxLength = 28,
		PropMass  = 0.055,
	}
})

ACF.RegisterWeapon("120mmM", "MO", {
	Name		= "120mm Mortar",
	Description	= "The versatile 120 is sometimes vehicle-mounted to provide quick boomsplat to support the infantry. Carries more boom in its boomsplat, has good HEAT performance, and is more accurate in high-angle firing.",
	Model		= "models/mortar/mortar_120mm.mdl",
	Caliber		= 120,
	Mass		= 640,
	Year		= 1935,
	Round = {
		MaxLength = 45,
		PropMass  = 0.175,
	}
})

ACF.RegisterWeapon("150mmM", "MO", {
	Name		= "150mm Mortar",
	Description	= "The perfect balance between the 120mm and the 200mm. Can prove a worthy main gun weapon, as well as a mighty good mortar emplacement",
	Model		= "models/mortar/mortar_150mm.mdl",
	Caliber		= 150,
	Mass		= 1255,
	Year		= 1945,
	Round = {
		MaxLength = 58,
		PropMass  = 0.235,
	}
})

ACF.RegisterWeapon("200mmM", "MO", {
	Name		= "200mm Mortar",
	Description	= "The 200mm is a beast, often used against fortifications. Though enormously powerful, feel free to take a nap while it reloads",
	Model		= "models/mortar/mortar_200mm.mdl",
	Caliber		= 200,
	Mass		= 2850,
	Year		= 1940,
	Round = {
		MaxLength = 80,
		PropMass  = 0.330,
	}
})
