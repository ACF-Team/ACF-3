--[[
	-- Commented out for now until this gets implemented to reduce confusion

-- This will check a vector against all of the hitboxes stored on an entity
-- If the vector is inside a box, it will return true, the box name (organization I guess, can do an E2 function with all of this), and the hitbox itself
-- If the entity in question does not have hitboxes, it returns false
-- Finally, if it never hits a hitbox in its check, it also returns false
function ACF_CheckInsideHitbox(Ent, Vec)
	if not Ent.HitBoxes then return false end -- If theres no hitboxes, then don't worry about them

	for k,v in pairs(Ent.HitBoxes) do
		-- v is the box table

		-- Need to make sure the vector is local and LEVEL with the box, otherwise WithinAABox will be wildly wrong
		local LocalPos = WorldToLocal(Vec,Angle(0,0,0),Ent:LocalToWorld(v.Pos),Ent:LocalToWorldAngles(v.Angle))
		local CheckHitbox = LocalPos:WithinAABox(-v.Scale / 2,v.Scale / 2)

		if CheckHitbox == true then return Check,k,v end
	end

	return false
end

-- This performs ray-OBB intersection with all of the hitboxes on an entity
-- Ray is the TOTAL ray to check with, so vec(500,0,0) to check all 500u forward
-- It will return false if there are no hitboxes or it didn't hit anything
-- If it hits any hitboxes, it will put them all together and return (true,HitBoxes)
function ACF_CheckHitbox(Ent,RayStart,Ray)
	if not Ent.HitBoxes then return false end -- Once again, cancel if there are no hitboxes

	local AllHit = {}

	for k,v in pairs(Ent.HitBoxes) do

		local _,_,Frac = util.IntersectRayWithOBB(RayStart, Ray, Ent:LocalToWorld(v.Pos), Ent:LocalToWorldAngles(v.Angle), -v.Scale / 2, v.Scale / 2)

		if Frac ~= nil then
			AllHit[k] = v
		end
	end

	return next(AllHit) and true or false, AllHit
end

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
		if not IsValid(Seat) then return end -- out of PVS?
		local Type = net.ReadString()
		HitBox = table.Copy(HitboxStorage[Type].HitBoxes)
		local ply = Seat:GetDriver()
		if not IsValid(ply) then return end -- eeeee someone got out

		for k,v in pairs(HitBox) do
			HitBox[k].Pos = Seat:WorldToLocal(ply:LocalToWorld(v.Pos))
			HitBox[k].Angle = Seat:WorldToLocalAngles(ply:LocalToWorldAngles(v.Angle))
		end

		Seat.HitBoxes = HitBox
	end)
end
]]--

-- I couldn't delete this work of art, it's just perfect

--[[
-- People hate this really simple trick!
-- Lets decide NOT to make Rotate return anything!
-- AKA how to piss off people
local function RealRotate(Vec,Ang)
	local GottaSaveThisStupidFuckingVectorBecauseItDoesntReturnOtherwise = Vec
	GottaSaveThisStupidFuckingVectorBecauseItDoesntReturnOtherwise:Rotate(Ang)
	return GottaSaveThisStupidFuckingVectorBecauseItDoesntReturnOtherwise
end
]]--
