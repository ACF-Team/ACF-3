local Racks = ACF.Classes.Racks

Racks.Register("40mm7xPOD", {
	Name		= "7x 40mm FFAR Pod",
	Description	= "A lightweight pod for small rockets which is vulnerable to shots and explosions.",
	Model		= "models/missiles/launcher7_40mm.mdl",
	EntType		= "Pod",
	Caliber		= 40,
	Mass		= 10,
	Year		= 1940,
	Armor		= 5,
	Preview = {
		FOV = 77,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector() },
		{ Name = "missile2", Position = Vector(0, -2, 0) },
		{ Name = "missile3", Position = Vector(0, -1, -1.73) },
		{ Name = "missile4", Position = Vector(0, 1, -1.73) },
		{ Name = "missile5", Position = Vector(0, 2, 0) },
		{ Name = "missile6", Position = Vector(0, 1, 1.74) },
		{ Name = "missile7", Position = Vector(0, -1, 1.74) }
	}
})

Racks.Register("57mm16xPOD", {
	Name		= "16x 57mm FFAR Pod",
	Description	= "A lightweight pod for small rockets which is vulnerable to shots and explosions.",
	Model		= "models/failz/ub_16.mdl",
	EntType		= "Pod",
	Caliber		= 57,
	Mass		= 30,
	Year		= 1956,
	Armor		= 5,
	Spread		= 1.37,
	Preview = {
		FOV = 60,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(3.5, 2.61, 0.96) },
		{ Name = "missile2", Position = Vector(3.5, 1.65, -2.34) },
		{ Name = "missile3", Position = Vector(3.5, -1.65, -2.34) },
		{ Name = "missile4", Position = Vector(3.5, -2.61, 0.96) },
		{ Name = "missile5", Position = Vector(3.5, 0, 2.55) },
		{ Name = "missile6", Position = Vector(3.5, -2.86, -5) },
		{ Name = "missile7", Position = Vector(3.5, -5.3, -2.6) },
		{ Name = "missile8", Position = Vector(3.5, -5.9, 0.65) },
		{ Name = "missile9", Position = Vector(3.5, -4.6, 3.5) },
		{ Name = "missile10", Position = Vector(3.5, -1.9, 5.5) },
		{ Name = "missile11", Position = Vector(3.5, 1.9, 5.5) },
		{ Name = "missile12", Position = Vector(3.5, 4.6, 3.5) },
		{ Name = "missile13", Position = Vector(3.5, 5.9, 0.65) },
		{ Name = "missile14", Position = Vector(3.5, 5.3, -2.6) },
		{ Name = "missile15", Position = Vector(3.5, 2.86, -5) },
		{ Name = "missile16", Position = Vector(3.5, 0, -5.8) },
	}
})

Racks.Register("57mm32xPOD", {
	Name		= "32x 57mm FFAR Pod",
	Description	= "A lightweight pod for small rockets which is vulnerable to shots and explosions.",
	Model		= "models/failz/ub_32.mdl",
	EntType		= "Pod",
	Caliber		= 57,
	Mass		= 130,
	Year		= 1956,
	Armor		= 5,
	Spread		= 1.37,
	Preview = {
		FOV = 85,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(-8, 0, 3.3) },
		{ Name = "missile2", Position = Vector(-8, 3.1, 0.8) },
		{ Name = "missile3", Position = Vector(-8, 1.8, -2.8) },
		{ Name = "missile4", Position = Vector(-8, -1.8, -2.8) },
		{ Name = "missile5", Position = Vector(-8, -3.1, 0.8) },
		{ Name = "missile6", Position = Vector(-8, 2.9, 6.2) },
		{ Name = "missile7", Position = Vector(-8, 5.8, 3.8) },
		{ Name = "missile8", Position = Vector(-8, 6.9, 0.2) },
		{ Name = "missile9", Position = Vector(-8, 6.1, -3.4) },
		{ Name = "missile10", Position = Vector(-8, 3.6, -6.1) },
		{ Name = "missile11", Position = Vector(-8, 0, -7.2) },
		{ Name = "missile12", Position = Vector(-8, -3.6, -6.1) },
		{ Name = "missile13", Position = Vector(-8, -6.1, -3.4) },
		{ Name = "missile14", Position = Vector(-8, -6.9, 0.2) },
		{ Name = "missile15", Position = Vector(-8, -5.8, 3.8) },
		{ Name = "missile16", Position = Vector(-8, -2.9, 6.2) },
		{ Name = "missile17", Position = Vector(-8, 5.3, 9.1) },
		{ Name = "missile18", Position = Vector(-8, 8.2, 6.75) },
		{ Name = "missile19", Position = Vector(-8, 10.2, 3.7) },
		{ Name = "missile20", Position = Vector(-8, 10.7, -0.1) },
		{ Name = "missile21", Position = Vector(-8, 10.1, -3.9) },
		{ Name = "missile22", Position = Vector(-8, 8.1, -7.1) },
		{ Name = "missile23", Position = Vector(-8, 5.3, -9.6) },
		{ Name = "missile24", Position = Vector(-8, 1.9, -10.7) },
		{ Name = "missile25", Position = Vector(-8, -1.9, -10.7) },
		{ Name = "missile26", Position = Vector(-8, -5.3, -9.6) },
		{ Name = "missile27", Position = Vector(-8, -8.1, -7.1) },
		{ Name = "missile28", Position = Vector(-8, -10.1, -3.9) },
		{ Name = "missile29", Position = Vector(-8, -10.7, -0.1) },
		{ Name = "missile30", Position = Vector(-8, -10.2, 3.7) },
		{ Name = "missile31", Position = Vector(-8, -8.2, 6.75) },
		{ Name = "missile32", Position = Vector(-8, -5.3, 9.1) },
	}
})

Racks.Register("70mm7xPOD", {
	Name		= "7x 70mm FFAR Pod",
	Description	= "A lightweight pod for rockets which is vulnerable to shots and explosions.",
	Model		= "models/missiles/launcher7_70mm.mdl",
	EntType		= "Pod",
	Caliber		= 70,
	Mass		= 30,
	Year		= 1940,
	Armor		= 5,
	Spread		= 0.6,
	Preview = {
		FOV = 77,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector() },
		{ Name = "missile2", Position = Vector(0, -3.5) },
		{ Name = "missile3", Position = Vector(0, -1.75, -3.03) },
		{ Name = "missile4", Position = Vector(0, 1.75, -3.03) },
		{ Name = "missile5", Position = Vector(0, 3.5) },
		{ Name = "missile6", Position = Vector(0, 1.75, 3.04) },
		{ Name = "missile7", Position = Vector(0, -1.75, 3.04) }
	}
})

Racks.Register("70mm19xPOD", {
	Name		= "19x 70mm FFAR Pod",
	Description	= "A lightweight pod for rockets which is vulnerable to shots and explosions.",
	Model		= "models/failz/lau_61.mdl",
	EntType		= "Pod",
	Caliber		= 70,
	Mass		= 90,
	Year		= 1960,
	Armor		= 5,
	Spread		= 0.6,
	Preview = {
		FOV = 105,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(5, -3.9, 7) },
		{ Name = "missile2", Position = Vector(5, 0, 7) },
		{ Name = "missile3", Position = Vector(5, 3.9, 7) },
		{ Name = "missile4", Position = Vector(5, -6.1, 3.4) },
		{ Name = "missile5", Position = Vector(5, -2.1, 3.4) },
		{ Name = "missile6", Position = Vector(5, 2.1, 3.4) },
		{ Name = "missile7", Position = Vector(5, 6.1, 3.4) },
		{ Name = "missile8", Position = Vector(5, -8) },
		{ Name = "missile9", Position = Vector(5, -4) },
		{ Name = "missile10", Position = Vector(5) },
		{ Name = "missile11", Position = Vector(5, 4) },
		{ Name = "missile12", Position = Vector(5, 8) },
		{ Name = "missile13", Position = Vector(5, -6.1, -3.6) },
		{ Name = "missile14", Position = Vector(5, -2.1, -3.6) },
		{ Name = "missile15", Position = Vector(5, 2.1, -3.6) },
		{ Name = "missile16", Position = Vector(5, 6.1, -3.6) },
		{ Name = "missile17", Position = Vector(5, -3.9, -7.2) },
		{ Name = "missile18", Position = Vector(5, 0, -7.2) },
		{ Name = "missile19", Position = Vector(5, 3.9, -7.2) },
	}
})

Racks.Register("80mm20xPOD", {
	Name		= "20x 80mm FFAR Pod",
	Description	= "A lightweight pod for rockets which is vulnerable to shots and explosions.",
	Model		= "models/failz/b8.mdl",
	EntType		= "Pod",
	Caliber		= 80,
	Mass		= 120,
	Year		= 1970,
	Armor		= 5,
	Spread		= 1.3,
	Preview = {
		FOV = 105,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(4, 2.8, 4.8) },
		{ Name = "missile2", Position = Vector(4, 5.6, 0.8) },
		{ Name = "missile3", Position = Vector(4, 4.2, -3.94) },
		{ Name = "missile4", Position = Vector(4, 0, -5.8) },
		{ Name = "missile5", Position = Vector(4, -4.2, -3.94) },
		{ Name = "missile6", Position = Vector(4, -5.6, 0.8) },
		{ Name = "missile7", Position = Vector(4, -2.8, 4.8) },
		{ Name = "missile8", Position = Vector(4, 3.8, 10) },
		{ Name = "missile9", Position = Vector(4, 8.0, 6.8) },
		{ Name = "missile10", Position = Vector(4, 10.1, 2.7) },
		{ Name = "missile11", Position = Vector(4, 10.23, -2.1) },
		{ Name = "missile12", Position = Vector(4, 8.20, -6.4) },
		{ Name = "missile13", Position = Vector(4, 4.55, -9.46) },
		{ Name = "missile14", Position = Vector(4, 0, -10.8) },
		{ Name = "missile15", Position = Vector(4, -4.55, -9.46) },
		{ Name = "missile16", Position = Vector(4, -8.20, -6.4) },
		{ Name = "missile17", Position = Vector(4, -10.23, -2.1) },
		{ Name = "missile18", Position = Vector(4, -10.1, 2.7) },
		{ Name = "missile19", Position = Vector(4, -8.0, 6.8) },
		{ Name = "missile20", Position = Vector(4, -3.8, 10) },
	}
})

Racks.Register("1x BGM-71E", {
	Name		= "TOW Launch Tube",
	Description	= "A single BGM-71E round.",
	Model		= "models/missiles/bgm_71e_round.mdl",
	EntType		= "Pod",
	Caliber		= 152,
	Mass		= 11,
	Year		= 1970,
	Armor		= 2.5,
	Preview = {
		Height = 110,
		FOV    = 60,
	},

	ProtectMissile = true,
	HideMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(15.76, 0, 0) }
	}
})

Racks.Register("2x BGM-71E", {
	Name		= "Dual TOW Launch Tube",
	Description	= "A BGM-71E rack designed to carry 2 rounds.",
	Model		= "models/missiles/bgm_71e_2xrk.mdl",
	EntType		= "Pod",
	Caliber		= 152,
	Mass		= 32,
	Year		= 1970,
	Armor		= 2.5,
	Preview = {
		Height = 95,
		FOV    = 60,
	},

	ProtectMissile = true,
	HideMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(23.64, 4.73, 0) },
		{ Name = "missile2", Position = Vector(23.64, -4.73, 0) }
	}
})

Racks.Register("4x BGM-71E", {
	Name		= "Quad TOW Launch Tube",
	Description	= "A BGM-71E rack designed to carry 4 rounds.",
	Model		= "models/missiles/bgm_71e_4xrk.mdl",
	EntType		= "Pod",
	Caliber		= 152,
	Mass		= 65,
	Year		= 1970,
	Armor		= 2.5,
	Preview = {
		FOV = 85,
	},

	ProtectMissile = true,
	HideMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(23.64, 4.73, 0) },
		{ Name = "missile2", Position = Vector(23.64, -4.73, 0) },
		{ Name = "missile3", Position = Vector(23.64, 4.73, -11.43) },
		{ Name = "missile4", Position = Vector(23.64, -4.73, -11.43) }
	}
})

Racks.Register("380mmRW61", {
	Name		= "380mm Rocket Mortar",
	Description	= "A lightweight pod for rocket-asisted mortars which is vulnerable to shots and explosions.",
	Model		= "models/launcher/rw61.mdl",
	EntType		= "Pod",
	Caliber		= 380,
	Mass		= 429,
	Year		= 1945,
	Armor		= 25,
	Spread		= 0.01,

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(8.39, -0.01, 0) },
	}
})

Racks.Register("3xUARRK", {
	Name		= "Triple Launch Tube",
	Description	= "A lightweight rack for bombs which is vulnerable to shots and explosions.",
	Model		= "models/missiles/rk3uar.mdl",
	EntType		= "Pod",
	Mass		= 61,
	Year		= 1941,
	Armor		= 5,
	Spread		= 0.04,
	Preview = {
		Height = 115,
		FOV    = 60,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(-4.5, 0, 9.09) },
		{ Name = "missile2", Position = Vector(-4.5, 3.19, 3.48) },
		{ Name = "missile3", Position = Vector(-4.5, -3.21, 3.48) },
	}
})

Racks.Register("6xUARRK", {
	Name		= "6x Launch Tube",
	Description	= "6-pack of death, used to efficiently carry artillery rockets",
	Model		= "models/missiles/6pod_rk.mdl",
	RackModel	= "models/missiles/6pod_cover.mdl",
	EntType		= "Pod",
	Mass		= 213,
	Year		= 1980,
	Armor		= 5,
	Spread		= 0.04,
	Preview = {
		FOV = 60,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(0.035, -11.26, 5.58) },
		{ Name = "missile2", Position = Vector(0.025, 0.03, 5.58) },
		{ Name = "missile3", Position = Vector(0.025, 11.18, 5.58) },
		{ Name = "missile4", Position = Vector(0.025, -11.26, -5.51) },
		{ Name = "missile5", Position = Vector(0.025, 0.03, -5.51) },
		{ Name = "missile6", Position = Vector(0.025, 11.18, -5.51) },
	}
})

Racks.Register("1x FIM-92", {
	Name		= "Stinger Launch Tube",
	Description	= "An FIM-92 rack designed to carry 1 missile.",
	Model		= "models/missiles/fim_92_1xrk.mdl",
	EntType		= "Pod",
	Caliber		= 70,
	Mass		= 11,
	Year		= 1984,
	Armor		= 2.5,
	Preview = {
		Height = 70,
		FOV    = 60,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector() }
	}
})

Racks.Register("2x FIM-92", {
	Name		= "Dual Stinger Launch Tube",
	Description	= "An FIM-92 rack designed to carry 2 missiles.",
	Model		= "models/missiles/fim_92_2xrk.mdl",
	EntType		= "Pod",
	Caliber		= 70,
	Mass		= 16,
	Year		= 1984,
	Armor		= 16,
	Preview = {
		Height = 90,
		FOV    = 60,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(0, 3.35, 0.45) },
		{ Name = "missile2", Position = Vector(0, -3.35, 0.45) }
	}
})

Racks.Register("4x FIM-92", {
	Name		= "Quad Stinger Launch Tube",
	Description	= "An FIM-92 rack designed to carry 4 missiles.",
	Model		= "models/missiles/fim_92_4xrk.mdl",
	EntType		= "Pod",
	Caliber		= 70,
	Mass		= 42,
	Year		= 1984,
	Armor		= 5,
	Preview = {
		FOV = 65,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(0, 2.6, 2.65) },
		{ Name = "missile2", Position = Vector(0, -2.6, 2.65) },
		{ Name = "missile3", Position = Vector(0, 2.6, -3.6) },
		{ Name = "missile4", Position = Vector(0, -2.6, -3.6) }
	}
})

Racks.Register("1x Strela-1", {
	Name		= "Strela Launch Tube",
	Description	= "An 9M31 rack designed to carry 1 missile.",
	Model		= "models/missiles/9m31_rk1.mdl",
	EntType		= "Pod",
	Caliber		= 120,
	Mass		= 75,
	Year		= 1968,
	Armor		= 5,
	Preview = {
		FOV = 60,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(44.12, 2.65, 0.13) }
	}
})

Racks.Register("2x Strela-1", {
	Name		= "Dual Strela Launch Tube",
	Description	= "An 9M31 rack designed to carry 2 missiles.",
	Model		= "models/missiles/9m31_rk2.mdl",
	EntType		= "Pod",
	Caliber		= 120,
	Mass		= 177,
	Year		= 1968,
	Armor		= 5,
	Preview = {
		FOV = 65,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(44.12, -5.59, 0.13) },
		{ Name = "missile2", Position = Vector(44.12, 10.97, 0.13) }
	}
})

Racks.Register("4x Strela-1", {
	Name		= "Quad Strela Launch Tube",
	Description	= "An 9m31 rack designed to carry 4 missiles.",
	Model		= "models/missiles/9m31_rk4.mdl",
	EntType		= "Pod",
	Caliber		= 120,
	Mass		= 482,
	Year		= 1968,
	Armor		= 5,
	Preview = {
		FOV = 60,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(44.17, -42.66, 3.74) },
		{ Name = "missile2", Position = Vector(44.17, -26.1, 3.74) },
		{ Name = "missile3", Position = Vector(44.17, 25.98, 3.74) },
		{ Name = "missile4", Position = Vector(44.17, 42.54, 3.74) }
	}
})

Racks.Register("1x Ataka", {
	Name		= "Ataka Launch Tube",
	Description	= "An 9M120 rack designed to carry 1 missile.",
	Model		= "models/missiles/9m120_rk1.mdl",
	RackModel	= "models/missiles/9m120.mdl",
	EntType		= "Pod",
	Caliber		= 130,
	Mass		= 13,
	Year		= 1968,
	Armor		= 2.5,
	Preview = {
		Height = 60,
		FOV    = 60,
	},

	ProtectMissile = true,
	HideMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(0, 0, 3) }
	}
})

Racks.Register("1x SPG9", {
	Name		= "SPG-9 Launch Tube",
	Description	= "Launch tube for SPG-9 recoilless rocket.",
	Model		= "models/spg9/spg9.mdl",
	EntType		= "Pod",
	Caliber		= 73,
	Mass		= 26,
	Year		= 1968,
	Armor		= 5,
	Spread		= 0.03,
	Preview = {
		Height = 80,
		FOV    = 60,
	},

	ProtectMissile = true,
	HideMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector() }
	}
})

Racks.Register("1x Kornet", {
	Name		= "Kornet Launch Tube",
	Description	= "Launch tube for Kornet antitank missile.",
	Model		= "models/kali/weapons/kornet/parts/9m133 kornet tube.mdl",
	EntType		= "Pod",
	Caliber		= 152,
	Mass		= 16,
	Year		= 1994,
	Armor		= 2.5,
	Preview = {
		FOV = 60,
	},

	ProtectMissile = true,
	HideMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector() }
	}
})

Racks.Register("127mm4xPOD", {
	Name		= "Quad Zuni Rocket Pod",
	Description	= "LAU-10/A Pod for the Zuni rocket.",
	Model		= "models/ghosteh/lau10.mdl",
	EntType		= "Pod",
	Caliber		= 127,
	Mass		= 68,
	Year		= 1957,
	Armor		= 5,
	Spread		= 0.02,
	Preview = {
		Height = 100,
		FOV    = 60,
	},

	ProtectMissile = true,

	MountPoints = {
		{ Name = "missile1", Position = Vector(5.2, 2.75, 2.65) },
		{ Name = "missile2", Position = Vector(5.2, -2.75, 2.65) },
		{ Name = "missile3", Position = Vector(5.2, 2.75, -2.83) },
		{ Name = "missile4", Position = Vector(5.2, -2.75, -2.83) }
	}
})
