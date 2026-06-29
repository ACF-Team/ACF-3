local Racks = ACF.Classes.Racks

Racks.Register("1xRK", {
	Name		= "Single Munition Rack",
	Description	= "A rather long but light rack that can hold a single missile or bomb.",
	Model		= "models/missiles/rkx1.mdl",
	Mass		= 79,
	Year		= 1915,
	Armor		= 10,
	Preview = {
		Height = 50,
		FOV    = 60,
	},

	CanDropMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(0, 0, 2.5), Direction = Vector(0, 0, -1) }
	},
})

Racks.Register("1xRK_small", {
	Name		= "Small Single Munition Rack",
	Description	= "A shorter version of the regular single munition rack, tends to be limited to smaller munitions.",
	Model		= "models/missiles/rkx1_sml.mdl",
	Mass		= 31,
	Year		= 1915,
	Armor		= 10,
	Preview = {
		Height = 100,
		FOV    = 60,
	},

	CanDropMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(0, 0, 2.5), Direction = Vector(0, 0, -1) }
	}
})

Racks.Register("2xRK", {
	Name		= "Dual Munitions Rack",
	Description	= "A rather lightweight rack with two mounting points separated horizontally.",
	Model		= "models/missiles/rack_double.mdl",
	Mass		= 160,
	Year		= 1915,
	Armor		= 10,
	Preview = {
		FOV = 85,
	},

	CanDropMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(4, -14, -1.7), Direction = Vector(0, -1, 0), Angle = Angle(0, 0, -90) },
		{ Name = "missile2", Position = Vector(4, 14, -1.7), Direction = Vector(0, 1, 0), Angle = Angle(0, 0, 90) }
	}
})

Racks.Register("3xRK", {
	Name		= "Triple Munitions Rack",
	Description	= "Based on the BRU-42 Triple Ejector Rack, it can hold up to three bombs.",
	Model		= "models/missiles/bomb_3xrk.mdl",
	Mass		= 61,
	Year		= 1936,
	Armor		= 10,
	Preview = {
		FOV = 75,
	},

	CanDropMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(-4, 0, -8.8), Direction = Vector(0, 0, -1) },
		{ Name = "missile2", Position = Vector(-4, 3.7, -0.2), Direction = Vector(0, 0.75, -0.75), Angle = Angle(0, 0, 45) },
		{ Name = "missile3", Position = Vector(-4, -3.7, -0.2), Direction = Vector(0, -0.75, -0.75), Angle = Angle(0, 0, -45) },
	}
})

Racks.Register("4xRK", {
	Name		= "Quad Munitions Rack",
	Description	= "Despite its rather small size, it can hold up to 4 different munitions.",
	Model		= "models/missiles/rack_quad.mdl",
	Mass		= 92,
	Year		= 1936,
	Armor		= 10,
	Preview = {
		FOV = 115,
	},

	CanDropMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(0, -12.5, -4.5), Direction = Vector(0, 0, -1) },
		{ Name = "missile2", Position = Vector(0, 12.5, -4.5), Direction = Vector(0, 0, -1) },
		{ Name = "missile3", Position = Vector(0, 13, 9), Direction = Vector(0, 1, 0), Angle = Angle(0, 0, 90) },
		{ Name = "missile4", Position = Vector(0, -13, 9), Direction = Vector(0, -1, 0), Angle = Angle(0, 0, -90) },
	}
})

Racks.Register("2x AGM-114", {
	Name		= "Dual Hellfire Rack",
	Description	= "Based on the upper section of the M299 Launcher, can load up to two missiles.",
	Model		= "models/missiles/agm_114_2xrk.mdl",
	Mass		= 60,
	Year		= 1984,
	Armor		= 5,
	Preview = {
		Height = 90,
		FOV    = 60,
	},

	CanDropMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(0, -7.85, 4.9), Direction = Vector(0, 0, -1) },
		{ Name = "missile2", Position = Vector(0, 8.05, 4.9), Direction = Vector(0, 0, -1) },
	}
})

Racks.Register("4x AGM-114", {
	Name		= "Quad Hellfire Rack",
	Description	= "Based on the M299 Launcher, it's capable of loading up to four missiles.",
	Model		= "models/missiles/agm_114_4xrk.mdl",
	Mass		= 162,
	Year		= 1984,
	Armor		= 5,
	Preview = {
		FOV = 100,
	},

	CanDropMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(0, -7.85, 4.9), Direction = Vector(0, 0, -1) },
		{ Name = "missile2", Position = Vector(0, 8.05, 4.9), Direction = Vector(0, 0, -1) },
		{ Name = "missile3", Position = Vector(0, -7.85, -13), Direction = Vector(0, 0, -1) },
		{ Name = "missile4", Position = Vector(0, 8.05, -13), Direction = Vector(0, 0, -1) }
	}
})

Racks.Register("1xAT3RK", {
	Name		= "Single 9M14 Rack",
	Description	= "Based on the 9P111 Portable Launcher, it can load a single 9M14 missile.",
	Model		= "models/missiles/at3rk.mdl",
	Mass		= 17,
	Year		= 1969,
	Armor		= 2.5,
	Preview = {
		FOV = 110,
	},

	MountPoints = {
		{ Name = "missile1", Position = Vector(3.4, -0.2, 0.95) }
	}
})

Racks.Register("1xAT3RKS", {
	Name		= "Single 9M14 Rail",
	Description	= "Consisting of only the launch rail, it can be used to carry a single 9M14 missile on any kind of vehicle.",
	Model		= "models/missiles/at3rs.mdl",
	Mass		= 8,
	Year		= 1972,
	Armor		= 2.5,
	Preview = {
		FOV = 80,
	},

	MountPoints = {
		{ Name = "missile1", Position = Vector(21, -0.2, 6.1) }
	}
})
