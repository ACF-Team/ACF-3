-- TODO: Rest of the guns, engines, transmissions.

ACF.HitBoxes = {}

local Box = ACF.HitBoxes

do -- Guns --------------------------------------
	do -- Cannons -------------------------------
		Box["models/tankgun/tankgun_37mm.mdl"] = {
			Breech = { -- Name doesn't matter, its just for convenience
				Pos = Vector(-5.25, 0, 0),
				Scale = Vector(10.5, 4.75, 4.75),
				Angle = Angle(0, 0, 0),
				Sensitive = true -- Whether or not this hitbox is set off by *any* entity and not just ACF
			},
			Barrel = {
				Pos = Vector(28, 0, 0),
				Scale = Vector(56, 2, 2),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/tankgun/tankgun_50mm.mdl"] = {
			Breech = {
				Pos = Vector(-6.75, 0, 0),
				Scale = Vector(13.5, 6,6),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(75 * 0.5, 0, 0),
				Scale = Vector(75, 3, 3),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/tankgun/tankgun_75mm.mdl"] = {
			Breech = {
				Pos = Vector(-10.25, 0, 0),
				Scale = Vector(20.5, 9.5, 9.5),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(113 * 0.5, 0, 0),
				Scale = Vector(113, 4, 4),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/tankgun/tankgun_100mm.mdl"] = {
			Breech = {
				Pos = Vector(-14.25, 0, 0),
				Scale = Vector(28.5, 12.5, 12.5),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(150 * 0.5, 0, 0),
				Scale = Vector(150, 5, 5),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/tankgun/tankgun_120mm.mdl"] = {
			Breech = {
				Pos = Vector(-33.5 * 0.5, 0, 0),
				Scale = Vector(33.5, 15, 15),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(180 * 0.5, 0, 0),
				Scale = Vector(180, 6, 6),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/tankgun/tankgun_140mm.mdl"] = {
			Breech = {
				Pos = Vector(-39.5 * 0.5, 0, 0),
				Scale = Vector(39.5, 17.5, 17.5),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(211 * 0.5, 0, 0),
				Scale = Vector(211, 7, 7),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
	end

	do -- Machineguns ---------------------------
		Box["models/machinegun/machinegun_762mm.mdl"] = {
			Base = {
				Pos = Vector(10, 0.1, -0.8),
				Scale = Vector(34, 1, 3),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/machinegun/machinegun_127mm.mdl"] = {
			Base = {
				Pos = Vector(14.1, 0.2, -1.1),
				Scale = Vector(47, 1, 4),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/machinegun/machinegun_145mm.mdl"] = {
			Base = {
				Pos = Vector(15.1, 0.2, -1.2),
				Scale = Vector(51, 2, 4),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/machinegun/machinegun_20mm.mdl"] = {
			Base = {
				Pos = Vector(20.1, 0.2, -1.5),
				Scale = Vector(68, 2, 6),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/machinegun/machinegun_20mm_compact.mdl"] = {
			Base = {
				Pos = Vector(10.5, 0, 0),
				Scale = Vector(41, 3, 6),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/machinegun/machinegun_30mm_compact.mdl"] = {
			Base = {
				Pos = Vector(14, 0, 0),
				Scale = Vector(55, 4, 8),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/machinegun/machinegun_40mm_compact.mdl"] = {
			Base = {
				Pos = Vector(17.5, 0, 0),
				Scale = Vector(68, 5, 10),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
	end

	do -- Autocannons ---------------------------
		Box["models/autocannon/autocannon_20mm.mdl"] = {
			Breech = {
				Pos = Vector(-1.25, 0, -0.9),
				Scale = Vector(29, 8, 10),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(36, 0, 0),
				Scale = Vector(46, 3, 3),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/autocannon/autocannon_30mm.mdl"] = {
			Breech = {
				Pos = Vector(-2, 0, -1.3),
				Scale = Vector(36, 11, 13),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(45, 0, 0),
				Scale = Vector(60, 4, 4),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/autocannon/autocannon_40mm.mdl"] = {
			Breech = {
				Pos = Vector(-2.5, 0, -1.2),
				Scale = Vector(42, 11, 13),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(52, 0, 0),
				Scale = Vector(68, 4.5, 4.5),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/autocannon/autocannon_50mm.mdl"] = {
			Breech = {
				Pos = Vector(-3, 0, -1.6),
				Scale = Vector(52, 15, 19),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(65, 0, 0),
				Scale = Vector(83, 5, 5),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
	end

	do -- Howitzers -----------------------------
		Box["models/howitzer/howitzer_75mm.mdl"] = {
			Breech = {
				Pos = Vector(-6, 0, -0.6),
				Scale = Vector(33, 10, 8),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(40, 0, -0.6),
				Scale = Vector(65, 5, 5),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
	end

	do -- Mortars -------------------------------
		Box["models/mortar/mortar_60mm.mdl"] = {
			Base = {
				Pos = Vector(-7.7, 0.2, 0),
				Scale = Vector(34, 5, 4),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/mortar/mortar_80mm.mdl"] = {
			Base = {
				Pos = Vector(-10.3, 0.2, 0),
				Scale = Vector(46, 6, 6),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/mortar/mortar_120mm.mdl"] = {
			Base = {
				Pos = Vector(-15.4, 0.3, 0),
				Scale = Vector(69, 10, 9),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/mortar/mortar_150mm.mdl"] = {
			Base = {
				Pos = Vector(-19.2, 0.4, 0),
				Scale = Vector(86, 12, 11),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/mortar/mortar_200mm.mdl"] = {
			Base = {
				Pos = Vector(-25.6, 0.6, 0),
				Scale = Vector(114, 16, 15),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
	end

	do -- Rotary Autocannons --------------------
		Box["models/rotarycannon/kw/14_5mmrac.mdl"] = {
			Breech = {
				Pos = Vector(1.2, 0, 0.1),
				Scale = Vector(12, 6, 6),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(7.3, 0, 0.1) + Vector(18, 0, 0),
				Scale = Vector(36, 3, 3),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/rotarycannon/kw/20mmrac.mdl"] = {
			Breech = {
				Pos = Vector(1.7, 0, 0.1),
				Scale = Vector(16, 9, 8),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(10, 0, 0) + Vector(25, 0, 0),
				Scale = Vector(50, 4, 4),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/rotarycannon/kw/30mmrac.mdl"] = {
			Breech = {
				Pos = Vector(2.6, 0, 0.2),
				Scale = Vector(25, 14, 12),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(15, 0, 0) + Vector(74 * 0.5, 0, 0),
				Scale = Vector(74, 7, 7),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
	end

	do -- Grenade Launchers ---------------------
		Box["models/launcher/40mmgl.mdl"] = {
			Breech = {
				Pos = Vector(0, 0, -1.25),
				Scale = Vector(20, 5, 6),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(8, 0, 0.1) + Vector(6, 0, 0),
				Scale = Vector(12, 2, 2),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/launcher/40mmsl.mdl"] = {
			Base = {
				Pos = Vector(0.7, 0, -0.1),
				Scale = Vector(8, 3, 2),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
	end
end ---------------------------------------------