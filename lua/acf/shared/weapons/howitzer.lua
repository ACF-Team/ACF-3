ACF.RegisterWeaponClass("HW", {
	Name        = "Howitzer",
	Description = "Howitzers are limited to rather mediocre muzzle velocities, but can fire extremely heavy projectiles with large useful payload capacities.",
	Sound       = "acf_base/weapons/howitzer_new2.mp3",
	Model       = "models/howitzer/howitzer_105mm.mdl",
	MuzzleFlash = "howie_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 1480,
	Spread      = 0.1,
	Caliber	= {
		Base = 105,
		Min  = 75,
		Max  = 203,
	},
	Round = {
		MaxLength = 86,
		PropMass  = 3.75,
	},
	Preview = {
		Height = 55,
		FOV    = 65,
	},
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
	Description	= "The 155 is a classic heavy artillery round, with good reason. A versatile weapon, it's found on most modern SPGs.",
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

ACF.SetCustomAttachment("models/howitzer/howitzer_105mm.mdl", "muzzle", Vector(101.08, 0, -1.08))

ACF.AddHitboxes("models/howitzer/howitzer_105mm.mdl", {
	Breech = {
		Pos       = Vector(-8, 0, -0.8),
		Scale     = Vector(47, 11.25, 9.5),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(58.5, 0, -0.7),
		Scale = Vector(86, 6, 6)
	}
})
