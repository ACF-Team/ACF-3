--define the class
ACF_defineGunClass("HW", {
	spread = 0.12,
	name = "Howitzer",
	desc = "Howitzers are limited to rather mediocre muzzle velocities, but can fire extremely heavy projectiles with large useful payload capacities.",
	muzzleflash = "howie_muzzleflash_noscale",
	rofmod = 1.8,
	sound = "weapons/ACF_Gun/howitzer_new2.mp3",
	soundDistance = "Howitzer.Fire",
	soundNormal = " "
})

--add a gun to the class
--id
ACF_defineGun("75mmHW", {
	name = "75mm Howitzer",
	desc = "Often found being towed by large smelly animals, the 75mm has a high rate of fire, and is surprisingly lethal against light armor.  Great for a sustained barrage against someone you really don't like.",
	model = "models/howitzer/howitzer_75mm.mdl",
	gunclass = "HW",
	caliber = 7.5,
	weight = 530,
	year = 1900,
	round = {
		maxlength = 60,
		propweight = 1.8
	}
})

ACF_defineGun("105mmHW", {
	name = "105mm Howitzer",
	desc = "The 105 lobs a big shell far, and its HEAT rounds can be extremely effective against even heavier armor.",
	model = "models/howitzer/howitzer_105mm.mdl",
	gunclass = "HW",
	caliber = 10.5,
	weight = 1480,
	year = 1900,
	round = {
		maxlength = 86,
		propweight = 3.75
	}
})

ACF_defineGun("122mmHW", {
	name = "122mm Howitzer",
	desc = "The 122mm bridges the gap between the 105 and the 155, providing a lethal round with a big splash radius.",
	model = "models/howitzer/howitzer_122mm.mdl",
	gunclass = "HW",
	caliber = 12.2,
	weight = 3420,
	year = 1900,
	round = {
		maxlength = 106,
		propweight = 7
	}
})

ACF_defineGun("155mmHW", {
	name = "155mm Howitzer",
	desc = "The 155 is a classic heavy artillery round, with good reason.  A versatile weapon, it's found on most modern SPGs.",
	model = "models/howitzer/howitzer_155mm.mdl",
	gunclass = "HW",
	caliber = 15.5,
	weight = 5340,
	year = 1900,
	round = {
		maxlength = 124,
		propweight = 13.5
	}
})

ACF_defineGun("203mmHW", {
	name = "203mm Howitzer",
	desc = "An 8-inch deck gun, found on siege artillery and cruisers.",
	model = "models/howitzer/howitzer_203mm.mdl",
	gunclass = "HW",
	caliber = 20.3,
	weight = 10280,
	year = 1900,
	round = {
		maxlength = 162.4,
		propweight = 28.5
	}
})
--[[
ACF_defineGun("240mmHW", {
	name = "240mm Howitzer",
	desc = "A 9.4-inch deck gun, found on heavy siege artillery and cruisers.",
	model = "models/howitzer/howitzer_240mm.mdl",
	gunclass = "HW",
	caliber = 24.0,
	weight = 12980,
	year = 1900,
	round = {
		maxlength = 192.0,
		propweight = 33.7
	}
} )

ACF_defineGun("290mmHW", {
	name = "290mm Howitzer",
	desc = " Mother of all howitzers. This 12in beast can be found on battleships. It WILL fuck your day up... when it reloads.",
	model = "models/howitzer/howitzer_406mm.mdl",
	gunclass = "HW",
	caliber = 29,
	weight = 24960,
	year = 1900,
	round = {
		maxlength = 325,
		propweight = 57.0
	}
} )
]]
--	

ACF.RegisterWeaponClass("HW", {
	Name		  = "Howitzer",
	Description	  = "Howitzers are limited to rather mediocre muzzle velocities, but can fire extremely heavy projectiles with large useful payload capacities.",
	MuzzleFlash	  = "howie_muzzleflash_noscale",
	ROFMod		  = 1.8,
	Spread		  = 0.12,
	Sound		  = "weapons/ACF_Gun/howitzer_new2.mp3",
	soundDistance = "Howitzer.Fire",
	soundNormal	  = " ",
})

ACF.RegisterWeapon("75mmHW", "HW", {
	Name		= "75mm Howitzer",
	Description	= "Often found being towed by large smelly animals, the 75mm has a high rate of fire, and is surprisingly lethal against light armor. Great for a sustained barrage against someone you really don't like.",
	Model		= "models/howitzer/howitzer_75mm.mdl",
	Caliber		= 75,
	Mass		= 530,
	Year		= 1900,
	Round = {
		MaxLength = 60,
		PropMass  = 1.8,
	}
})

ACF.RegisterWeapon("105mmHW", "HW", {
	Name		= "105mm Howitzer",
	Description	= "The 105 lobs a big shell far, and its HEAT rounds can be extremely effective against even heavier armor.",
	Model		= "models/howitzer/howitzer_105mm.mdl",
	Caliber		= 105,
	Mass		= 1480,
	Year		= 1900,
	Round = {
		MaxLength = 86,
		PropMass  = 3.75,
	}
})

ACF.RegisterWeapon("122mmHW", "HW", {
	Name		= "122mm Howitzer",
	Description	= "The 122mm bridges the gap between the 105 and the 155, providing a lethal round with a big splash radius.",
	Model		= "models/howitzer/howitzer_122mm.mdl",
	Caliber		= 122,
	Mass		= 3420,
	Year		= 1900,
	Round = {
		MaxLength = 106,
		PropMass  = 7,
	}
})

ACF.RegisterWeapon("155mmHW", "HW", {
	Name		= "155mm Howitzer",
	Description	= "The 155 is a classic heavy artillery round, with good reason.  A versatile weapon, it's found on most modern SPGs.",
	Model		= "models/howitzer/howitzer_155mm.mdl",
	Caliber		= 155,
	Mass		= 5340,
	Year		= 1900,
	Round = {
		MaxLength = 124,
		PropMass  = 13.5,
	}
})

ACF.RegisterWeapon("203mmHW", "HW", {
	Name		= "203mm Howitzer",
	Description	= "An 8-inch deck gun, found on siege artillery and cruisers.",
	Model		= "models/howitzer/howitzer_203mm.mdl",
	Caliber		= 203,
	Mass		= 10280,
	Year		= 1900,
	Round = {
		MaxLength = 162.4,
		PropMass  = 28.5,
	}
})
