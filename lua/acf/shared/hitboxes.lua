-- This is an automated system for pod hitboxes
if SERVER then util.AddNetworkString("ACF_SeatHitboxes") end

-- Critical is if the player should die faster from being hit there
-- if its false, should do less damage

local HitboxStorage = {
	["Passenger"] = { -- Passenger is any seat that the player is just sitting like a passenger
		HitBoxes = {
			Head = {
				Pos = Vector(2,0,28),
				Scale = Vector(9,9,9),
				Angle = Angle(0,0,0),
				Critical = true
			},
			Body = {
				Pos = Vector(-1,0,12),
				Scale = Vector(10,22,24), -- wider because the arms are in the lap
				Angle = Angle(0,0,0),
				Critical = true
			},
			UpperLegs = {
				Pos = Vector(8,0,1),
				Scale = Vector(24,18,6),
				Angle = Angle(0,0,0),
				Critical = false
			},
			LowerLegs = {
				Pos = Vector(20,0,-8),
				Scale = Vector(6,18,22),
				Angle = Angle(-12,0,0),
				Critical = false
			}
		}
	},
	["PodOverride"] = { -- This is a special override because prisoner/driver pods are THPESCIAL
		HitBoxes = {
			Head = {
				Pos = Vector(-8,0,68),
				Scale = Vector(9,9,9),
				Angle = Angle(0,0,0),
				Critical = true
			},
			Body = {
				Pos = Vector(-5,0,49),
				Scale = Vector(11,20,26),
				Angle = Angle(-5,0,0),
				Critical = true
			},
			UpperLegs = {
				Pos = Vector(-4.5,0,27),
				Scale = Vector(8,17,17),
				Angle = Angle(0,0,0),
				Critical = false
			},
			LowerLegs = {
				Pos = Vector(-6,0,8),
				Scale = Vector(8,13,20),
				Angle = Angle(0,0,0),
				Critical = false
			}
		}
	},
	["Jeep"] = { -- Jeep driver animation, has arms because they are seperate, reaching for the steering wheel
		HitBoxes = {
			Head = {
				Pos = Vector(5,0,34),
				Scale = Vector(9,9,9),
				Angle = Angle(0,0,0),
				Critical = true
			},
			Body = {
				Pos = Vector(7,0,16),
				Scale = Vector(10,18,24),
				Angle = Angle(-12,0,0),
				Critical = true
			},
			LArm = {
				Pos = Vector(18,8,22),
				Scale = Vector(28,5,5),
				Angle = Angle(5,0,0),
				Critical = false
			},
			RArm = {
				Pos = Vector(18,-8,22),
				Scale = Vector(28,5,5),
				Angle = Angle(5,0,0),
				Critical = false
			},
			UpperLegs = {
				Pos = Vector(18,0,7),
				Scale = Vector(24,18,6),
				Angle = Angle(-20,0,0),
				Critical = false
			},
			LowerLegs = {
				Pos = Vector(34,0,4),
				Scale = Vector(6,18,22),
				Angle = Angle(-45,0,0),
				Critical = false
			}
		}
	},
	["Airboat"] = { -- Like the jeep hitbox, this also has arms added reaching for the steering wheel
		HitBoxes = {
			Head = {
				Pos = Vector(4,0,31),
				Scale = Vector(9,9,9),
				Angle = Angle(0,0,0),
				Critical = true
			},
			Body = {
				Pos = Vector(3,0,14),
				Scale = Vector(10,18,24),
				Angle = Angle(-12,0,0),
				Critical = true
			},
			LArm = {
				Pos = Vector(13,9,19),
				Scale = Vector(28,5,5),
				Angle = Angle(0,0,0),
				Critical = false
			},
			RArm = {
				Pos = Vector(13,-9,19),
				Scale = Vector(28,5,5),
				Angle = Angle(0,0,0),
				Critical = false
			},
			UpperLegs = {
				Pos = Vector(12,0,3.5),
				Scale = Vector(24,18,6),
				Angle = Angle(-10,0,0),
				Critical = false
			},
			LowerLegs = {
				Pos = Vector(30,0,-1),
				Scale = Vector(6,18,22),
				Angle = Angle(-50,0,0),
				Critical = false
			}
		}
	}
}

local AnimLookup = { -- defaults to Passenger, catchall for any wierd fucking animations for seats, if they exist
	[ACT_DRIVE_JEEP] = "Jeep",
	[ACT_DRIVE_AIRBOAT] = "Airboat",
	["default"] = "Passenger"
}

local function switch(cases,arg) local Var = (cases[arg] or cases["default"]) return Var end
hook.Add("PlayerEnteredVehicle","ACF_HitboxUpdate",function(ply,ent)
	timer.Simple(3,function() -- 3 seconds is a safe amount of time for all of the seats (including those stupid fucking PHX ones that take 3 years to move the camera) to get the camera into position
		if IsValid(ply) and IsValid(ent) and ply:GetVehicle() == ent then
			local Model = ent:GetModel()
			local Type = ""
			if Model == "models/vehicles/prisoner_pod_inner.mdl" or Model == "models/vehicles/driver_pod.mdl" then
				Type = "PodOverride"
			else
				Type = (switch(AnimLookup,ply:GetSequenceActivity(ply:GetSequence())))
			end

			local HitBox = table.Copy(HitboxStorage[Type].HitBoxes)

			for k,v in pairs(HitBox) do
				HitBox[k].Pos = ent:WorldToLocal(ply:LocalToWorld(v.Pos))
				HitBox[k].Angle = ent:WorldToLocalAngles(ply:LocalToWorldAngles(v.Angle))
			end

			ent.HitBoxes = HitBox

			net.Start("ACF_SeatHitboxes")
				net.WriteEntity(ent)
				net.WriteString(Type)
			net.Broadcast()
		end
	end)
end)

hook.Add("PlayerLeaveVehicle","ACF_HitboxRemove",function(_,ent) -- theres no player, so why bother having hitboxes for a player?
	ent.HitBoxes = nil
	-- I intentionally left the client update out, so someone can use it to position their seat better
	-- They will have to sit in it first though
end)

if CLIENT then
	net.Receive("ACF_SeatHitboxes",function()
		local Seat = net.ReadEntity()
		local Type = net.ReadString()
		HitBox = table.Copy(HitboxStorage[Type].HitBoxes)
		local ply = Seat:GetDriver()

		for k,v in pairs(HitBox) do
			HitBox[k].Pos = Seat:WorldToLocal(ply:LocalToWorld(v.Pos))
			HitBox[k].Angle = Seat:WorldToLocalAngles(ply:LocalToWorldAngles(v.Angle))
		end

		Seat.HitBoxes = HitBox
	end)
end

-- All of the manually made hitboxes for various models
-- Current issues: smoothbores are using the same hitboxes as the new cannons
-- TODO: Engines, racks, fix smoothbores

ACF.HitBoxes = {}

local Box = ACF.HitBoxes

do -- Transmissions
	do -- Transaxials
		Box["models/engines/transaxial_s.mdl"] = {
			Axle = {
				Pos = Vector(0, 0, 3.25),
				Scale = Vector(6.5,16,6.5),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			},
			In = {
				Pos = Vector(5.5, 0, 3.25),
				Scale = Vector(4.5, 6.5, 6.5),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/engines/transaxial_m.mdl"] = {
			Axle = {
				Pos = Vector(0, 0, 3.25) * 1.5,
				Scale = Vector(6.5,16,6.5) * 1.5,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			},
			In = {
				Pos = Vector(5.5, 0, 3.25) * 1.5,
				Scale = Vector(4.5, 6.5, 6.5) * 1.5,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/engines/transaxial_l.mdl"] = {
			Axle = {
				Pos = Vector(0, 0, 3.25) * 2.5,
				Scale = Vector(6.5,16,6.5) * 2.5,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			},
			In = {
				Pos = Vector(5.5, 0, 3.25) * 2.5,
				Scale = Vector(4.5, 6.5, 6.5) * 2.5,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
	end

	do	-- Linears
		Box["models/engines/linear_s.mdl"] = {
			Straight = {
				Pos = Vector(0, -0.5, 3.25),
				Scale = Vector(6.5,18,6.5),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			},
			In = {
				Pos = Vector(0, 4.75, 11),
				Scale = Vector(6.5, 7.5, 9),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/engines/linear_m.mdl"] = {
			Straight = {
				Pos = Vector(0, -0.5, 3.25) * 1.5,
				Scale = Vector(6.5,18,6.5) * 1.5,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			},
			In = {
				Pos = Vector(0, 4.75, 11) * 1.5,
				Scale = Vector(6.5, 7.5, 9) * 1.5,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/engines/linear_l.mdl"] = {
			Straight = {
				Pos = Vector(0, -0.5, 3.25) * 2.5,
				Scale = Vector(6.5,18,6.5) * 2.5,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			},
			In = {
				Pos = Vector(0, 4.75, 11) * 2.5,
				Scale = Vector(6.5, 7.5, 9) * 2.5,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
	end

	do -- Straights
		Box["models/engines/t5small.mdl"] = {
			Straight = {
				Pos = Vector(0, 12.5, -0.75),
				Scale = Vector(6.5,15,8),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			},
			Clutch = {
				Pos = Vector(0, 2.5, 0),
				Scale = Vector(11, 5, 11),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/engines/t5med.mdl"] = {
			Straight = {
				Pos = Vector(0, 12.5, -0.75) * 1.5,
				Scale = Vector(6.5,15,8) * 1.5,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			},
			Clutch = {
				Pos = Vector(0, 2.5, 0) * 1.5,
				Scale = Vector(11, 5, 11) * 1.5,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/engines/t5large.mdl"] = {
			Straight = {
				Pos = Vector(0, 12.5, -0.75) * 2,
				Scale = Vector(6.5,15,8) * 2,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			},
			Clutch = {
				Pos = Vector(0, 2.5, 0) * 2,
				Scale = Vector(11, 5, 11) * 2,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
	end

	do
		Box["models/engines/flywheelclutcht.mdl"] = {
			Clutch = {
				Pos = Vector(0,0.25,0),
				Scale = Vector(8, 4, 8),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/engines/flywheelclutchs.mdl"] = {
			Clutch = {
				Pos = Vector(0,0.25,0) * 1.5,
				Scale = Vector(8, 4, 8) * 1.5,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/engines/flywheelclutchm.mdl"] = {
			Clutch = {
				Pos = Vector(0,0.25,0) * 2,
				Scale = Vector(8, 4, 8) * 2,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/engines/flywheelclutchb.mdl"] = {
			Clutch = {
				Pos = Vector(0,0.25,0) * 3,
				Scale = Vector(8, 4, 8) * 3,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
	end
end

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

	--[[ for some fuckin reason Smoothbores are using regular cannon hitboxes, despite different model paths
	do
		Box["models/tankgun_old/tankgun_100mm.mdl"] = {
			Breech = {
				Pos = Vector(-20, 0, 0),
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
	end
	]]--

	do -- Short Barrel Cannons
		Box["models/tankgun/tankgun_short_37mm.mdl"] = {
			Breech = {
				Pos = Vector(-5.25, 0, 0),
				Scale = Vector(10.5, 4.75, 4.75),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(15.25, 0, 0),
				Scale = Vector(30.5, 2.5, 2.5),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/tankgun/tankgun_short_50mm.mdl"] = {
			Breech = {
				Pos = Vector(-5.25, 0, 0) * 1.351,
				Scale = Vector(10.5, 4.75, 4.75) * 1.351,
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(15.25, 0, 0) * 1.351,
				Scale = Vector(30.5, 2.5, 2.5) * 1.351,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/tankgun/tankgun_short_75mm.mdl"] = {
			Breech = {
				Pos = Vector(-5.25, 0, 0) * 2.072,
				Scale = Vector(10.5, 4.75, 4.75) * 2.072,
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(15.25, 0, 0) * 2.072,
				Scale = Vector(30.5, 2.5, 2.5) * 2.072,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/tankgun/tankgun_short_100mm.mdl"] = {
			Breech = {
				Pos = Vector(-5.25, 0, 0) * 2.702,
				Scale = Vector(10.5, 4.75, 4.75) * 2.702,
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(15.25, 0, 0) * 2.702,
				Scale = Vector(30.5, 2.5, 2.5) * 2.702,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/tankgun/tankgun_short_120mm.mdl"] = {
			Breech = {
				Pos = Vector(-5.25, 0, 0) * 3.243,
				Scale = Vector(10.5, 4.75, 4.75) * 3.243,
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(15.25, 0, 0) * 3.243,
				Scale = Vector(30.5, 2.5, 2.5) * 3.243,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/tankgun/tankgun_short_140mm.mdl"] = {
			Breech = {
				Pos = Vector(-5.25, 0, 0) * 3.783,
				Scale = Vector(10.5, 4.75, 4.75) * 3.783,
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(15.25, 0, 0) * 3.783,
				Scale = Vector(30.5, 2.5, 2.5) * 3.783,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
	end

	do -- Semiautomatic Cannons
		Box["models/autocannon/semiautocannon_25mm.mdl"] = {
			Breech = {
				Pos = Vector(-0.75, 0, 0.25),
				Scale = Vector(21, 7, 3.75),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(26.75, 0, 0),
				Scale = Vector(34.5, 2, 2),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/autocannon/semiautocannon_37mm.mdl"] = {
			Breech = {
				Pos = Vector(-0.75, 0, 0.25) * 1.48,
				Scale = Vector(21, 7, 3.75) * 1.48,
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(26.75, 0, 0) * 1.48,
				Scale = Vector(34.5, 2, 2) * 1.48,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/autocannon/semiautocannon_45mm.mdl"] = {
			Breech = {
				Pos = Vector(-0.75, 0, 0.25) * 1.8,
				Scale = Vector(21, 7, 3.75) * 1.8,
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(26.75, 0, 0) * 1.8,
				Scale = Vector(34.5, 2, 2) * 1.8,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/autocannon/semiautocannon_57mm.mdl"] = {
			Breech = {
				Pos = Vector(-0.75, 0, 0.25) * 2.45,
				Scale = Vector(21, 7, 3.75) * 2.45,
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(27, 0, 0) * 2.45,
				Scale = Vector(34.75, 2, 2) * 2.45,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/autocannon/semiautocannon_76mm.mdl"] = {
			Breech = {
				Pos = Vector(-0.75, 0, 0.25) * 3.8,
				Scale = Vector(21, 7, 3.75) * 3.8,
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(27, 0, 0) * 3.8,
				Scale = Vector(34.75, 2, 2) * 3.8,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
	end

	do -- Autoloading Cannons
		Box["models/tankgun/tankgun_al_75mm.mdl"] = {
			Breech = {
				Pos = Vector(-26.5, 0, 0),
				Scale = Vector(63, 12,9),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(57.5, 0, 0),
				Scale = Vector(105, 6, 6),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			},
			LeftDrum = {
				Pos = Vector(-43, 12, 2.25),
				Scale = Vector(30, 12, 12),
				Angle = Angle(0, 0, 0),
				Sensitive = false,
				Critical = true
			},
			RightDrum = {
				Pos = Vector(-43, -12, 2.25),
				Scale = Vector(30, 12, 12),
				Angle = Angle(0, 0, 0),
				Sensitive = false,
				Critical = true
			}
		}
		Box["models/tankgun/tankgun_al_100mm.mdl"] = {
			Breech = {
				Pos = Vector(-26.5, 0, 0) * 1.33,
				Scale = Vector(63, 12,9) * 1.33,
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(57.5, 0, 0) * 1.33,
				Scale = Vector(105, 6, 6) * 1.33,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			},
			LeftDrum = {
				Pos = Vector(-43, 12, 2.25) * 1.33,
				Scale = Vector(30, 12, 12) * 1.33,
				Angle = Angle(0, 0, 0),
				Sensitive = false,
				Critical = true
			},
			RightDrum = {
				Pos = Vector(-43, -12, 2.25) * 1.33,
				Scale = Vector(30, 12, 12) * 1.33,
				Angle = Angle(0, 0, 0),
				Sensitive = false,
				Critical = true
			}
		}
		Box["models/tankgun/tankgun_al_120mm.mdl"] = {
			Breech = {
				Pos = Vector(-26.5, 0, 0) * 1.6,
				Scale = Vector(63, 12,9) * 1.6,
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(57.5, 0, 0) * 1.6,
				Scale = Vector(105, 6, 6) * 1.6,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			},
			LeftDrum = {
				Pos = Vector(-43, 12, 2.25) * 1.6,
				Scale = Vector(30, 12, 12) * 1.6,
				Angle = Angle(0, 0, 0),
				Sensitive = false,
				Critical = true
			},
			RightDrum = {
				Pos = Vector(-43, -12, 2.25) * 1.6,
				Scale = Vector(30, 12, 12) * 1.6,
				Angle = Angle(0, 0, 0),
				Sensitive = false,
				Critical = true
			}
		}
		Box["models/tankgun/tankgun_al_140mm.mdl"] = {
			Breech = {
				Pos = Vector(-26.5, 0, 0) * 1.867,
				Scale = Vector(63, 12,9) * 1.867,
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(57.5, 0, 0) * 1.867,
				Scale = Vector(105, 6, 6) * 1.867,
				Angle = Angle(0, 0, 0),
				Sensitive = false
			},
			LeftDrum = {
				Pos = Vector(-43, 12, 2.25) * 1.867,
				Scale = Vector(30, 12, 12) * 1.867,
				Angle = Angle(0, 0, 0),
				Sensitive = false,
				Critical = true
			},
			RightDrum = {
				Pos = Vector(-43, -12, 2.25) * 1.867,
				Scale = Vector(30, 12, 12) * 1.867,
				Angle = Angle(0, 0, 0),
				Sensitive = false,
				Critical = true
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
				Scale = Vector(33, 8, 7),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(41, 0, -0.6),
				Scale = Vector(61.5, 4.5, 4.5),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/howitzer/howitzer_105mm.mdl"] = {
			Breech = {
				Pos = Vector(-8, 0, -0.8),
				Scale = Vector(47, 11.25, 9.5),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(58.5, 0, -0.7),
				Scale = Vector(86, 6, 6),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/howitzer/howitzer_122mm.mdl"] = {
			Breech = {
				Pos = Vector(-10, 0, -1),
				Scale = Vector(52, 13, 11),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(67, 0, -0.9),
				Scale = Vector(102, 7, 7),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/howitzer/howitzer_155mm.mdl"] = {
			Breech = {
				Pos = Vector(-13, 0, -1.2),
				Scale = Vector(68, 16.5, 14),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(85.5, 0, -1),
				Scale = Vector(129, 9, 9),
				Angle = Angle(0, 0, 0),
				Sensitive = false
			}
		}
		Box["models/howitzer/howitzer_203mm.mdl"] = {
			Breech = {
				Pos = Vector(-15, 0, -1.6),
				Scale = Vector(90, 22, 19),
				Angle = Angle(0, 0, 0),
				Sensitive = true
			},
			Barrel = {
				Pos = Vector(113, 0, -1.8),
				Scale = Vector(167, 12, 12),
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
