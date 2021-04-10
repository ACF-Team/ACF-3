-- Entity validation for ACF

-- Local Vars -----------------------------------
local ACF         = ACF
local StringFind  = string.find
local TimerSimple = timer.Simple
local Baddies	  = ACF.GlobalFilter

-- TODO: Add Ray-Cylinder intersection test
local function RayIntersectHitBoxes(Ent, Start, Ray)
	for _, V in pairs(Ent.HitBoxes) do
		local Hit, _, Frac = util.IntersectRayWithOBB(Start, Ray, Ent:LocalToWorld(V.Pos), Ent:LocalToWorldAngles(V.Angle), V.Scale * -0.5, V.Scale * 0.5)

		if Hit then
			debugoverlay.BoxAngles(Ent:LocalToWorld(V.Pos), V.Scale * -0.5, V.Scale * 0.5, Ent:LocalToWorldAngles(V.Angle), 5, Color(255, 50, 50, 75))
			return true
		end
	end
end

local function CheckHitBoxes(Entity)
	local Keys = table.GetKeys(Entity.HitBoxes)

	-- Pick a random hitbox
	local Key  = Keys[math.random(1, #Keys)]
	local Box  = Entity.HitBoxes[Key]

	-- Check any entities along a random ray from one end to the other of the selected box/cylinder
	local Scale    = Box.Scale
	local Pos, Ang = LocalToWorld(Box.Pos, Box.Angle, Entity:GetPos(), Entity:GetAngles())
	local Start, End

	if Box.Cylinder then
		Start = Vector(1, 0, 1)
			Start:Rotate(Angle(0, 0, math.Rand(0, 360)))
			Start = Start * Vector(Scale.x, Scale.y, Scale.y) * 0.5
			Start = LocalToWorld(Start, Angle(), Pos, Ang)

		End = Vector(-1, 0, 1)
			End:Rotate(Angle(0, 0, math.Rand(0, 360)))
			End = End * Vector(Scale.x, Scale.z, Scale.z) * 0.5
			End = LocalToWorld(End, Angle(), Pos, Ang)
	else
		Start = Vector(-Scale.x, Scale.y * math.Rand(-1, 1), Scale.z * math.Rand(-1, 1)) * Vector(0.5, 0.5, 0.5)
		Start = LocalToWorld(Start, Angle(), Pos, Ang)

		End = Vector(Scale.x, Scale.y * math.Rand(-1, 1), Scale.z * math.Rand(-1, 1)) * Vector(0.5, 0.5, 0.5)
		End = LocalToWorld(End, Angle(), Pos, Ang)
	end

	local Ents = ents.FindAlongRay(Start, End)

	debugoverlay.Line(Start, End, 1, Color(0, 255, 0), true)

	-- Check if any of the found entities are ACF ents
	if next(Ents) then
		local Owner = Entity:CPPIGetOwner()

		for _, V in ipairs(Ents) do
			if V == Entity then continue end

			if V.IsACFEntity and V:CPPIGetOwner() == Owner and RayIntersectHitBoxes(V, Start, End - Start) then
				return true, V
			end
		end
	end
end

--[[ ACF Legality Check
	ALL SENTS MUST HAVE:
	ENT.ACF.PhysObj defined when spawned
	ENT.ACF.LegalMass defined when spawned
	ENT.ACF.Model defined when spawned

	ACF_CheckLegal(entity) called when finished spawning

	function ENT:Enable()
		<code>
	end

	function ENT:Disable()
		<code>
	end
]]--
local function IsLegal(Entity)
	if ACF.Gamemode == 1 then return true end -- Gamemode is set to Sandbox, legal checks don't apply

	local Phys = Entity:GetPhysicsObject()

	if Entity.ACF.PhysObj ~= Phys then
		if Phys:GetVolume() then
			Entity.ACF.PhysObj = Phys -- Updated PhysObj
		else
			Entity:Remove() -- Remove spherical trash
			return false, "Invalid physics", ""
		end
	end
	if Entity.ClipData and next(Entity.ClipData) then return false, "Visual Clip", "Visual clip cannot be applied to ACF entities." end -- No visclip
	if Entity.IsWeapon and not ACF.GunsCanFire then return false, "Cannot fire", "Firing disabled by the servers ACF settings." end
	if Entity.IsRack and not ACF.RacksCanFire then return false, "Cannot fire", "Firing disabled by the servers ACF settings." end
	if Entity.HitBoxes then
		local Hit, Ent = CheckHitBoxes(Entity)

		if Hit then
			-- TODO: Disable the other entity too
			return false, "Clipping", "Intersecting another ACF entity."
		end
	end

	return true
end

local function CheckLegal(Entity)
	local Legal, Reason, Description = IsLegal(Entity)

	if not Legal then -- Not legal
		if Reason ~= Entity.DisableReason then -- Only complain if the reason has changed
			local Owner = Entity:CPPIGetOwner()

			Entity.Disabled		 = true
			Entity.DisableReason = Reason
			Entity.DisableDescription = Description

			Entity:Disable() -- Let the entity know it's disabled

			if Entity.UpdateOverlay then Entity:UpdateOverlay(true) end -- Update overlay if it has one (Passes true to update overlay instantly)
			if tobool(Owner:GetInfo("acf_legalhints")) then -- Notify the owner
				local Name = Entity.WireDebugName .. " [" .. Entity:EntIndex() .. "]"

				if Reason == "Not drawn" or Reason == "Not solid" then -- Thank you garry, very cool
					timer.Simple(1.1, function() -- Remover tool sets nodraw and removes 1 second later, causing annoying alerts
						if not IsValid(Entity) then return end

						ACF.SendNotify(Owner, false, Name .. " has been disabled: " .. Description)
					end)
				else
					ACF.SendNotify(Owner, false, Name .. " has been disabled: " .. Description)
				end
			end
		end

		TimerSimple(ACF.IllegalDisableTime, function() -- Check if it's legal again in ACF.IllegalDisableTime
			if IsValid(Entity) and CheckLegal(Entity) then
				Entity.Disabled	   	 = nil
				Entity.DisableReason = nil
				Entity.DisableDescription = nil

				Entity:Enable()

				if Entity.UpdateOverlay then Entity:UpdateOverlay(true) end
			end
		end)

		return false
	end

	if ACF.Gamemode ~= 1 then
		TimerSimple(math.Rand(1, 3), function() -- Entity is legal... test again in random 1 to 3 seconds
			if IsValid(Entity) then
				CheckLegal(Entity)
			end
		end)
	end

	return true
end
-- Global Funcs ---------------------------------
function ACF.Check(Entity, ForceUpdate) -- IsValid but for ACF
	if not IsValid(Entity) then return false end

	local Class = Entity:GetClass()
	if Baddies[Class] then return false end

	local PhysObj = Entity:GetPhysicsObject()
	if not IsValid(PhysObj) then return false end

	if not Entity.ACF then
		if Entity:IsWorld() or Entity:IsWeapon() or StringFind(Class, "func_") then
			Baddies[Class] = true

			return false
		end

		ACF.Activate(Entity)
	elseif ForceUpdate or Entity.ACF.Mass ~= PhysObj:GetMass() or Entity.ACF.PhysObj ~= PhysObj then
		ACF.Activate(Entity, true)
	end

	return Entity.ACF.Type
end

function ACF.Activate(Entity, Recalc)
	--Density of steel = 7.8g cm3 so 7.8kg for a 1mx1m plate 1m thick
	local PhysObj = Entity:GetPhysicsObject()

	if not IsValid(PhysObj) then return end

	Entity.ACF = Entity.ACF or {}
	Entity.ACF.PhysObj = PhysObj

	if Entity.ACF_Activate then
		Entity:ACF_Activate(Recalc)
		return
	end

	-- TODO: Figure out what are the 6.45 and 0.52505066107 multipliers for
	-- NOTE: Why are we applying multipliers to the stored surface area?
	local SurfaceArea = PhysObj:GetSurfaceArea()

	if SurfaceArea then -- Normal collisions
		Entity.ACF.Area = SurfaceArea * 6.45 * 0.52505066107
	elseif PhysObj:GetMesh() then -- Box collisions
		local Size = Entity:OBBMaxs() - Entity:OBBMins()

		Entity.ACF.Area = ((Size.x * Size.y) + (Size.x * Size.z) + (Size.y * Size.z)) * 6.45
	else -- Spherical collisions
		local Radius = Entity:BoundingRadius()

		Entity.ACF.Area = 4 * 3.1415 * Radius * Radius * 6.45
	end

	Entity.ACF.Ductility = Entity.ACF.Ductility or 0

	local Area = Entity.ACF.Area
	local Ductility = math.Clamp(Entity.ACF.Ductility, -0.8, 0.8)
	local Armour = ACF_CalcArmor(Area, Ductility, PhysObj:GetMass()) -- So we get the equivalent thickness of that prop in mm if all its weight was a steel plate
	local Health = (Area / ACF.Threshold) * (1 + Ductility) -- Setting the threshold of the prop Area gone
	local Percent = 1

	if Recalc and Entity.ACF.Health and Entity.ACF.MaxHealth then
		Percent = Entity.ACF.Health / Entity.ACF.MaxHealth
	end

	Entity.ACF.Health = Health * Percent
	Entity.ACF.MaxHealth = Health
	Entity.ACF.Armour = Armour * (0.5 + Percent / 2)
	Entity.ACF.MaxArmour = Armour * ACF.ArmorMod
	Entity.ACF.Mass = PhysObj:GetMass()

	if Entity:IsPlayer() or Entity:IsNPC() then
		Entity.ACF.Type = "Squishy"
	elseif Entity:IsVehicle() then
		Entity.ACF.Type = "Vehicle"
	else
		Entity.ACF.Type = "Prop"
	end
end

-- Globalize ------------------------------------
ACF_IsLegal    = IsLegal
ACF_CheckLegal = CheckLegal
ACF_Check      = ACF.Check
ACF_Activate   = ACF.Activate
