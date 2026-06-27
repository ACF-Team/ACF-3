local Classes = ACF.Classes

Classes.DefineClass("ACF.Racks.40mm7xPOD", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "7x 40mm FFAR Pod"
	CLASS.Description	= "A lightweight pod for small rockets which is vulnerable to shots and explosions."
	CLASS.Model		= "models/missiles/launcher7_40mm.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 40
	CLASS.Mass		= 10
	CLASS.Year		= 1940
	CLASS.Armor		= 5
	CLASS.Preview = {
		FOV = 77,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector() },
		{ Name = "missile2", Position = Vector(0, -2, 0) },
		{ Name = "missile3", Position = Vector(0, -1, -1.73) },
		{ Name = "missile4", Position = Vector(0, 1, -1.73) },
		{ Name = "missile5", Position = Vector(0, 2, 0) },
		{ Name = "missile6", Position = Vector(0, 1, 1.74) },
		{ Name = "missile7", Position = Vector(0, -1, 1.74) }
	}
end)

Classes.DefineClass("ACF.Racks.57mm16xPOD", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "16x 57mm FFAR Pod"
	CLASS.Description	= "A lightweight pod for small rockets which is vulnerable to shots and explosions."
	CLASS.Model		= "models/failz/ub_16.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 57
	CLASS.Mass		= 30
	CLASS.Year		= 1956
	CLASS.Armor		= 5
	CLASS.Spread		= 1.37
	CLASS.Preview = {
		FOV = 60,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
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
end)

Classes.DefineClass("ACF.Racks.57mm32xPOD", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "32x 57mm FFAR Pod"
	CLASS.Description	= "A lightweight pod for small rockets which is vulnerable to shots and explosions."
	CLASS.Model		= "models/failz/ub_32.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 57
	CLASS.Mass		= 130
	CLASS.Year		= 1956
	CLASS.Armor		= 5
	CLASS.Spread		= 1.37
	CLASS.Preview = {
		FOV = 85,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
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
end)

Classes.DefineClass("ACF.Racks.70mm7xPOD", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "7x 70mm FFAR Pod"
	CLASS.Description	= "A lightweight pod for rockets which is vulnerable to shots and explosions."
	CLASS.Model		= "models/missiles/launcher7_70mm.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 70
	CLASS.Mass		= 30
	CLASS.Year		= 1940
	CLASS.Armor		= 5
	CLASS.Spread		= 0.6
	CLASS.Preview = {
		FOV = 77,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector() },
		{ Name = "missile2", Position = Vector(0, -3.5) },
		{ Name = "missile3", Position = Vector(0, -1.75, -3.03) },
		{ Name = "missile4", Position = Vector(0, 1.75, -3.03) },
		{ Name = "missile5", Position = Vector(0, 3.5) },
		{ Name = "missile6", Position = Vector(0, 1.75, 3.04) },
		{ Name = "missile7", Position = Vector(0, -1.75, 3.04) }
	}
end)

Classes.DefineClass("ACF.Racks.70mm19xPOD", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "19x 70mm FFAR Pod"
	CLASS.Description	= "A lightweight pod for rockets which is vulnerable to shots and explosions."
	CLASS.Model		= "models/failz/lau_61.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 70
	CLASS.Mass		= 90
	CLASS.Year		= 1960
	CLASS.Armor		= 5
	CLASS.Spread		= 0.6
	CLASS.Preview = {
		FOV = 105,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
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
end)

Classes.DefineClass("ACF.Racks.80mm20xPOD", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "20x 80mm FFAR Pod"
	CLASS.Description	= "A lightweight pod for rockets which is vulnerable to shots and explosions."
	CLASS.Model		= "models/failz/b8.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 80
	CLASS.Mass		= 120
	CLASS.Year		= 1970
	CLASS.Armor		= 5
	CLASS.Spread		= 1.3
	CLASS.Preview = {
		FOV = 105,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
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
end)

Classes.DefineClass("ACF.Racks.1xBGM-71E", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "TOW Launch Tube"
	CLASS.Description	= "A single BGM-71E round."
	CLASS.Model		= "models/missiles/bgm_71e_round.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 152
	CLASS.Mass		= 11
	CLASS.Year		= 1970
	CLASS.Armor		= 2.5
	CLASS.Preview = {
		Height = 110,
		FOV    = 60,
	}

	CLASS.ProtectMissile = true
	CLASS.HideMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(15.76, 0, 0) }
	}
end)

Classes.DefineClass("ACF.Racks.2xBGM-71E", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Dual TOW Launch Tube"
	CLASS.Description	= "A BGM-71E rack designed to carry 2 rounds."
	CLASS.Model		= "models/missiles/bgm_71e_2xrk.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 152
	CLASS.Mass		= 32
	CLASS.Year		= 1970
	CLASS.Armor		= 2.5
	CLASS.Preview = {
		Height = 95,
		FOV    = 60,
	}

	CLASS.ProtectMissile = true
	CLASS.HideMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(23.64, 4.73, 0) },
		{ Name = "missile2", Position = Vector(23.64, -4.73, 0) }
	}
end)

Classes.DefineClass("ACF.Racks.4xBGM-71E", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Quad TOW Launch Tube"
	CLASS.Description	= "A BGM-71E rack designed to carry 4 rounds."
	CLASS.Model		= "models/missiles/bgm_71e_4xrk.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 152
	CLASS.Mass		= 65
	CLASS.Year		= 1970
	CLASS.Armor		= 2.5
	CLASS.Preview = {
		FOV = 85,
	}

	CLASS.ProtectMissile = true
	CLASS.HideMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(23.64, 4.73, 0) },
		{ Name = "missile2", Position = Vector(23.64, -4.73, 0) },
		{ Name = "missile3", Position = Vector(23.64, 4.73, -11.43) },
		{ Name = "missile4", Position = Vector(23.64, -4.73, -11.43) }
	}
end)

Classes.DefineClass("ACF.Racks.380mmRW61", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "380mm Rocket Mortar"
	CLASS.Description	= "A lightweight pod for rocket-asisted mortars which is vulnerable to shots and explosions."
	CLASS.Model		= "models/launcher/rw61.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 380
	CLASS.Mass		= 429
	CLASS.Year		= 1945
	CLASS.Armor		= 25
	CLASS.Spread		= 0.01

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(8.39, -0.01, 0) },
	}
end)

Classes.DefineClass("ACF.Racks.3xUARRK", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Triple Launch Tube"
	CLASS.Description	= "A lightweight rack for bombs which is vulnerable to shots and explosions."
	CLASS.Model		= "models/missiles/rk3uar.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Mass		= 61
	CLASS.Year		= 1941
	CLASS.Armor		= 5
	CLASS.Spread		= 0.04
	CLASS.Preview = {
		Height = 115,
		FOV    = 60,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(-4.5, 0, 9.09) },
		{ Name = "missile2", Position = Vector(-4.5, 3.19, 3.48) },
		{ Name = "missile3", Position = Vector(-4.5, -3.21, 3.48) },
	}
end)

Classes.DefineClass("ACF.Racks.6xUARRK", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "6x Launch Tube"
	CLASS.Description	= "6-pack of death, used to efficiently carry artillery rockets"
	CLASS.Model		= "models/missiles/6pod_rk.mdl"
	CLASS.RackModel	= "models/missiles/6pod_cover.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Mass		= 213
	CLASS.Year		= 1980
	CLASS.Armor		= 5
	CLASS.Spread		= 0.04
	CLASS.Preview = {
		FOV = 60,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(0.035, -11.26, 5.58) },
		{ Name = "missile2", Position = Vector(0.025, 0.03, 5.58) },
		{ Name = "missile3", Position = Vector(0.025, 11.18, 5.58) },
		{ Name = "missile4", Position = Vector(0.025, -11.26, -5.51) },
		{ Name = "missile5", Position = Vector(0.025, 0.03, -5.51) },
		{ Name = "missile6", Position = Vector(0.025, 11.18, -5.51) },
	}
end)

Classes.DefineClass("ACF.Racks.1xFIM-92", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Stinger Launch Tube"
	CLASS.Description	= "An FIM-92 rack designed to carry 1 missile."
	CLASS.Model		= "models/missiles/fim_92_1xrk.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 70
	CLASS.Mass		= 11
	CLASS.Year		= 1984
	CLASS.Armor		= 2.5
	CLASS.Preview = {
		Height = 70,
		FOV    = 60,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector() }
	}
end)

Classes.DefineClass("ACF.Racks.2xFIM-92", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Dual Stinger Launch Tube"
	CLASS.Description	= "An FIM-92 rack designed to carry 2 missiles."
	CLASS.Model		= "models/missiles/fim_92_2xrk.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 70
	CLASS.Mass		= 16
	CLASS.Year		= 1984
	CLASS.Armor		= 16
	CLASS.Preview = {
		Height = 90,
		FOV    = 60,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(0, 3.35, 0.45) },
		{ Name = "missile2", Position = Vector(0, -3.35, 0.45) }
	}
end)

Classes.DefineClass("ACF.Racks.4xFIM-92", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Quad Stinger Launch Tube"
	CLASS.Description	= "An FIM-92 rack designed to carry 4 missiles."
	CLASS.Model		= "models/missiles/fim_92_4xrk.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 70
	CLASS.Mass		= 42
	CLASS.Year		= 1984
	CLASS.Armor		= 5
	CLASS.Preview = {
		FOV = 65,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(0, 2.6, 2.65) },
		{ Name = "missile2", Position = Vector(0, -2.6, 2.65) },
		{ Name = "missile3", Position = Vector(0, 2.6, -3.6) },
		{ Name = "missile4", Position = Vector(0, -2.6, -3.6) }
	}
end)

Classes.DefineClass("ACF.Racks.1xStrela-1", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Strela Launch Tube"
	CLASS.Description	= "An 9M31 rack designed to carry 1 missile."
	CLASS.Model		= "models/missiles/9m31_rk1.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 120
	CLASS.Mass		= 75
	CLASS.Year		= 1968
	CLASS.Armor		= 5
	CLASS.Preview = {
		FOV = 60,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(44.12, 2.65, 0.13) }
	}
end)

Classes.DefineClass("ACF.Racks.2xStrela-1", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Dual Strela Launch Tube"
	CLASS.Description	= "An 9M31 rack designed to carry 2 missiles."
	CLASS.Model		= "models/missiles/9m31_rk2.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 120
	CLASS.Mass		= 177
	CLASS.Year		= 1968
	CLASS.Armor		= 5
	CLASS.Preview = {
		FOV = 65,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(44.12, -5.59, 0.13) },
		{ Name = "missile2", Position = Vector(44.12, 10.97, 0.13) }
	}
end)

Classes.DefineClass("ACF.Racks.4xStrela-1", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Quad Strela Launch Tube"
	CLASS.Description	= "An 9m31 rack designed to carry 4 missiles."
	CLASS.Model		= "models/missiles/9m31_rk4.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 120
	CLASS.Mass		= 482
	CLASS.Year		= 1968
	CLASS.Armor		= 5
	CLASS.Preview = {
		FOV = 60,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(44.17, -42.66, 3.74) },
		{ Name = "missile2", Position = Vector(44.17, -26.1, 3.74) },
		{ Name = "missile3", Position = Vector(44.17, 25.98, 3.74) },
		{ Name = "missile4", Position = Vector(44.17, 42.54, 3.74) }
	}
end)

Classes.DefineClass("ACF.Racks.1xAtaka", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Ataka Launch Tube"
	CLASS.Description	= "An 9M120 rack designed to carry 1 missile."
	CLASS.Model		= "models/missiles/9m120_rk1.mdl"
	CLASS.RackModel	= "models/missiles/9m120.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 130
	CLASS.Mass		= 13
	CLASS.Year		= 1968
	CLASS.Armor		= 2.5
	CLASS.Preview = {
		Height = 60,
		FOV    = 60,
	}

	CLASS.ProtectMissile = true
	CLASS.HideMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(0, 0, 3) }
	}
end)

Classes.DefineClass("ACF.Racks.1xSPG9", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "SPG-9 Launch Tube"
	CLASS.Description	= "Launch tube for SPG-9 recoilless rocket."
	CLASS.Model		= "models/spg9/spg9.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 73
	CLASS.Mass		= 26
	CLASS.Year		= 1968
	CLASS.Armor		= 5
	CLASS.Spread		= 0.03
	CLASS.Preview = {
		Height = 80,
		FOV    = 60,
	}

	CLASS.ProtectMissile = true
	CLASS.HideMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector() }
	}
end)

Classes.DefineClass("ACF.Racks.1xKornet", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Kornet Launch Tube"
	CLASS.Description	= "Launch tube for Kornet antitank missile."
	CLASS.Model		= "models/kali/weapons/kornet/parts/9m133 kornet tube.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 152
	CLASS.Mass		= 16
	CLASS.Year		= 1994
	CLASS.Armor		= 2.5
	CLASS.Preview = {
		FOV = 60,
	}

	CLASS.ProtectMissile = true
	CLASS.HideMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector() }
	}
end)

Classes.DefineClass("ACF.Racks.127mm4xPOD", "ACF.Racks.BaseRack", function()
	CLASS.Name		= "Quad Zuni Rocket Pod"
	CLASS.Description	= "LAU-10/A Pod for the Zuni rocket."
	CLASS.Model		= "models/ghosteh/lau10.mdl"
	CLASS.EntType		= "Pod"
	CLASS.Caliber		= 127
	CLASS.Mass		= 68
	CLASS.Year		= 1957
	CLASS.Armor		= 5
	CLASS.Spread		= 0.02
	CLASS.Preview = {
		Height = 100,
		FOV    = 60,
	}

	CLASS.ProtectMissile = true

	CLASS.MountPoints = {
		{ Name = "missile1", Position = Vector(5.2, 2.75, 2.65) },
		{ Name = "missile2", Position = Vector(5.2, -2.75, 2.65) },
		{ Name = "missile3", Position = Vector(5.2, 2.75, -2.83) },
		{ Name = "missile4", Position = Vector(5.2, -2.75, -2.83) }
	}
end)
