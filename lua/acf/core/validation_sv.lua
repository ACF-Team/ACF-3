-- Entity validation for ACF

-- Local Vars -----------------------------------
local ACF          = ACF
local Contraption  = ACF.Contraption
local StringFind   = string.find
local TimerSimple  = timer.Simple
local Baddies	   = ACF.GlobalFilter
local MinimumArmor = ACF.MinimumArmor
local MaximumArmor = ACF.MaxThickness

--[[ ACF Legality Check
	ALL SENTS MUST HAVE:
	ENT.ACF.PhysObj defined when spawned
	ENT.ACF.LegalMass defined when spawned
	ENT.ACF.Model defined when spawned

	ACF.CheckLegal(entity) called when finished spawning

	function ENT:Enable()
		<code>
	end

	function ENT:Disable()
		<code>
	end
]]--
function ACF.IsLegal(Entity)
	if not ACF.LegalChecks then return true end -- Legal checks are disabled

	local Phys = Entity:GetPhysicsObject()

	if not IsValid(Entity.ACF.PhysObj) or Entity.ACF.PhysObj ~= Phys then
		if Phys:GetVolume() then
			Entity.ACF.PhysObj = Phys -- Updated PhysObj
		else
			ACF.Shame(Entity, "having a custom physics object (spherical).")
			return false, "Invalid Physics", "Custom physics objects cannot be applied to ACF entities."
		end
	end
	if not Entity:IsSolid() then ACF.Shame(Entity, "not being solid.") return false, "Not Solid", "The entity is invisible to projectiles." end
	if Entity.ClipData and next(Entity.ClipData) then ACF.Shame(Entity, "having visclips.") return false, "Visual Clip", "Visual clip cannot be applied to ACF entities." end -- No visclip
	if Entity.IsACFWeapon and not ACF.GunsCanFire then return false, "Cannot fire", "Firing disabled by the servers ACF settings." end
	if Entity.IsRack and not ACF.RacksCanFire then return false, "Cannot fire", "Firing disabled by the servers ACF settings." end

	local Legal, Reason, Message, Timeout
	if Entity.ACF_IsLegal then
		Legal, Reason, Message, Timeout = Entity:ACF_IsLegal()
	end

	-- Legal would only be false if ACF_IsLegal is present on the entity *and* it returned false
	-- If it returned true, the hook should be allowed to override that

	-- Additionally; add arguments to the hook from the entity check, in case whatever hooks into this
	-- wants to stop if the entity said its legal, add a reason onto the reason, etc?
	if Legal ~= false then
		Legal, Reason, Message, Timeout = hook.Run("ACF_OnCheckLegal", Entity, Legal, Reason, Message, Timeout)
	end

	if not Legal then return Legal, Reason, Message, Timeout end

	return true
end

function ACF.DisableEntity(Entity, Reason, Message, Timeout)
	local Owner = Entity:CPPIGetOwner()

	local Disabled = Entity.Disabled

	if not Disabled or Reason ~= Disabled.Reason then
		Entity.Disabled	= {
			Reason  = Reason,
			Message = Message
		}

		Entity:Disable() -- Let the entity know it's disabled
		if Entity.UpdateOverlay then Entity:UpdateOverlay(true) end -- Update overlay if it has one (Passes true to update overlay instantly)
		if IsValid(Owner) and tobool(Owner:GetInfo("acf_legalhints")) then -- Notify the owner
			local Name = Entity.WireDebugName .. " [" .. Entity:EntIndex() .. "]"

			if Reason == "Not Solid" then -- Thank you garry, very cool
				timer.Simple(1.1, function() -- Remover tool sets nodraw and removes 1 second later, causing annoying alerts
					if not IsValid(Entity) then return end

					ACF.SendNotify(Owner, false, Name .. " has been disabled: " .. Message)
				end)
			else
				ACF.SendNotify(Owner, false, Name .. " has been disabled: " .. Message)
			end
		end
	end

	if Timeout then Timeout = math.max(Timeout, 1) end
	TimerSimple(Timeout or ACF.IllegalDisableTime, function() -- Check if it's legal again in ACF.IllegalDisableTime
		if not IsValid(Entity) then return end
		if not ACF.CheckLegal(Entity) then return end

		Entity.Disabled = nil

		Entity:Enable()

		if Entity.UpdateOverlay then Entity:UpdateOverlay(true) end
	end)
end

function ACF.CheckLegal(Entity)
	local Legal, Reason, Message, Timeout = ACF.IsLegal(Entity)

	if not Legal then -- Not legal
		local Disabled = Entity.Disabled

		if not Disabled or Reason ~= Disabled.Reason then -- Only complain if the reason has changed
			ACF.DisableEntity(Entity, Reason, Message, Timeout)
		end

		return false
	end

	if ACF.LegalChecks then
		TimerSimple(math.Rand(1, 3), function() -- Entity is legal... test again in random 1 to 3 seconds
			if not IsValid(Entity) then return end

			ACF.CheckLegal(Entity)
		end)
	end

	return true
end

--- Determines the type of damage that should be dealt to the given entity.
--- @param Entity entity The entity to be checked
--- @return string # The type of damage that ACF should deal to the entity
function ACF.GetEntityType(Entity)
	if Entity:IsPlayer() or Entity:IsNPC() or Entity:IsNextBot() then return "Squishy" end

	-- Explicitly handle support for LVS/simfphys/WAC/Glide
	local EntTbl = Entity:GetTable()
	if EntTbl.LVS or EntTbl.IsSimfphyscar or EntTbl.isWacAircraft or EntTbl.IsGlideVehicle then return "Squishy" end

	if Entity:IsVehicle() then return "Vehicle" end

	return "Prop"
end

function ACF.UpdateArea(Entity, PhysObj)
	local Area = PhysObj:GetSurfaceArea()

	if Area then -- Normal collisions
		local AreaMult = 0.52505066107 -- This seems to be a conversion from cm to grid units on the architectural scale (approx. 1 / 1.905)
		Area = Area * ACF.InchToCmSq * AreaMult
	elseif PhysObj:GetMesh() then -- Box collisions
		local Size = Entity:OBBMaxs() - Entity:OBBMins()

		Area = ((Size.x * Size.y) + (Size.x * Size.z) + (Size.y * Size.z)) * ACF.InchToCmSq
	else -- Spherical collisions
		local Radius = Entity:BoundingRadius()

		Area = 4 * math.pi * Radius * Radius * ACF.InchToCmSq
	end

	Entity.ACF.Area = Area

	return Area
end

function ACF.UpdateThickness(Entity, PhysObj, Area, Ductility)
	local EntMods   = Entity.EntityMods
	local ArmorMod  = EntMods and EntMods.ACF_Armor
	local Thickness = ArmorMod and ArmorMod.Thickness
	local MassMod   = EntMods and EntMods.mass

	if Thickness then
		if not MassMod then
			local Mass = Area * (1 + Ductility) ^ 0.5 * Thickness * 0.00078

			if Mass ~= Entity.ACF.Mass then
				Contraption.SetMass(Entity, Mass)
			end

			return Thickness
		end

		duplicator.ClearEntityModifier(Entity, "ACF_Armor")
		duplicator.StoreEntityModifier(Entity, "ACF_Armor", { Thickness = Thickness, Ductility = Ductility * 100 })
	end

	local Mass  = MassMod and MassMod.Mass or PhysObj:GetMass()
	local Armor = ACF.CalcArmor(Area, Ductility, Mass)

	if Mass ~= Entity.ACF.Mass then
		Contraption.SetMass(Entity, Mass)

		duplicator.StoreEntityModifier(Entity, "mass", { Mass = Mass })
	end

	return math.Clamp(Armor, MinimumArmor, MaximumArmor)
end

hook.Add("ACF_OnUpdateServerData", "ACF_MaxThickness", function(_, Key, Value)
	if Key ~= "MaxThickness" then return end

	MaximumArmor = math.floor(ACF.CheckNumber(Value, ACF.MaxThickness))
end)

-- Global Funcs ---------------------------------

function ACF.Check(Entity, ForceUpdate) -- IsValid but for ACF
	if not IsValid(Entity) then return false end

	local Class = Entity:GetClass()
	if Baddies[Class] then return false end

	local PhysObj = Entity:GetPhysicsObject()
	if not IsValid(PhysObj) then return false end

	local EntACF = Entity.ACF

	if not EntACF then
		if Entity:IsWorld() or Entity:IsWeapon() or StringFind(Class, "func_") then
			Baddies[Class] = true

			return false
		end

		ACF.Activate(Entity)
		EntACF = Entity.ACF
	elseif ForceUpdate or EntACF.Mass ~= PhysObj:GetMass() or (not IsValid(EntACF.PhysObj) or EntACF.PhysObj ~= PhysObj) then
		ACF.Activate(Entity, true)
	end

	return EntACF.Type
end

--- Initializes the entity's armor properties. If ACF_Activate is defined by the entity, that method is called as well.
--- @param Recalc boolean Whether or not to recalculate the health
function ACF.Activate(Entity, Recalc)
	-- Density of steel = 7.8g cm3 so 7.8kg for a 1mx1m plate 1m thick
	local PhysObj = Entity:GetPhysicsObject()
	local EntTbl  = Entity:GetTable()

	if not IsValid(PhysObj) then return end
	if not EntTbl.ACF then EntTbl.ACF = {} end

	EntTbl.ACF.Type    = ACF.GetEntityType(Entity)
	EntTbl.ACF.PhysObj = PhysObj

	-- Note that if the entity has its own ENT:ACF_Activate(Recalc) function, the rest of the code after this block won't be ran (instead the function should specify the rest)
	if EntTbl.ACF_Activate then
		Entity:ACF_Activate(Recalc)
		return
	end

	local Area      = ACF.UpdateArea(Entity, PhysObj)
	local Ductility = math.Clamp(EntTbl.ACF.Ductility or 0, -0.8, 0.8)
	local Thickness = math.Clamp(ACF.UpdateThickness(Entity, PhysObj, Area, Ductility) * ACF.ArmorMod, ACF.MinimumArmor, ACF.MaxThickness)
	local Health    = (Area / ACF.Threshold) * (1 + Ductility) -- Setting the threshold of the prop Area gone
	local Percent   = 1

	if Recalc and EntTbl.ACF.Health and EntTbl.ACF.MaxHealth then
		Percent = EntTbl.ACF.Health / EntTbl.ACF.MaxHealth
	end

	EntTbl.ACF.Health    = Health * Percent
	EntTbl.ACF.MaxHealth = Health
	EntTbl.ACF.Armour    = Thickness * (0.5 + Percent * 0.5)
	EntTbl.ACF.MaxArmour = Thickness
	EntTbl.ACF.Ductility = Ductility
end