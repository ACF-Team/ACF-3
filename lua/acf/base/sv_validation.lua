-- Entity validation for ACF

-- Local Vars -----------------------------------
local ACF         = ACF
local StringFind  = string.find
local TimerSimple = timer.Simple
local Baddies	  = ACF.GlobalFilter

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
			return false, "Invalid physics", "" -- This shouldn't even run
		end
	end
	if Entity:GetModel() ~= Entity.ACF.Model then return false, "Incorrect model", "ACF entities cannot have their models changed." end
	if not Entity:IsSolid() then return false, "Not solid", "ACF entities must be solid." end -- Entities must always be solid
	if Entity.ClipData and next(Entity.ClipData) then return false, "Visual Clip", "Visual clip cannot be applied to ACF entities." end -- No visclip

	if Entity:GetNoDraw() then
		Entity:SetNoDraw(false)

		return false, "Not drawn", "ACF entities must be drawn at all times."
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
