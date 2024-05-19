--[[
This is the main server side file for the ammo entity.

Notes on Structure of Data:
- Data.Weapon (string) = Weapon class (e.g. "AC", "MO", "HW", "C")
- Data.Destiny (string) = Weapon group (e.g. "Weapons"/"Missiles")
- Data.Caliber (number) = Weapon caliber in mm (e.g. 10)
- Data.Size (vector) = Dimensions of crate (e.g. Vector(24,24,24))
- Data.AmmoType (string) = Weapon ammotype (e.g. "AP")
- Data.Offset (Vector) = Offset to use for backwards compatability with old crates

Methods exposed to the user for use with other files:
- ENT:CanConsume()
- ENT:Consume(Num)
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Local Vars -----------------------------------

local ACF          = ACF
local Contraption  = ACF.Contraption
local ActiveCrates = ACF.AmmoCrates
local Utilities    = ACF.Utilities
local TimerCreate  = timer.Create
local TimerExists  = timer.Exists
local HookRun      = hook.Run

do -- Spawning and Updating --------------------
	local Classes   = ACF.Classes
	local WireIO    = Utilities.WireIO
	local Crates    = Classes.Crates
	local Entities  = Classes.Entities
	local AmmoTypes = Classes.AmmoTypes
	local Weapons   = Classes.Weapons

	local Inputs = {
		"Load (If set to a non-zero value, it'll allow weapons to use rounds from this ammo crate.)",
	}
	local Outputs = {
		"Loading (Whether or not weapons can use rounds from this crate.)",
		"Ammo (Rounds left in this ammo crate.)",
		"Entity (The ammo crate itself.) [ENTITY]",
	}

	local function VerifyData(Data)
		if Data.Id then -- Deprecated ammo data formats
			local Crate = Crates.Get(Data.Id) -- Id is the crate model type, Crate holds its offset, size and id.

			if Crate then -- Pre scalable crate remnants (ACF2?)
				Data.Offset = Vector(Crate.Offset)
				Data.Size   = Vector(Crate.Size)
			else -- Initial scaleables remnants (Early ACF3?)
				local X = ACF.CheckNumber(Data.RoundData11, 24)
				local Y = ACF.CheckNumber(Data.RoundData12, 24)
				local Z = ACF.CheckNumber(Data.RoundData13, 24)

				Data.Size = Vector(X, Y, Z)
			end

			Data.Weapon   = Data.RoundId -- Note that RoundId is of the old weapon id form, e.g. "14.5mmMG", 
			Data.AmmoType = Data.RoundType
		elseif not isvector(Data.Size) then -- This could just be an else statement? Not sure though.
			-- Current ammo data format
			local X = ACF.CheckNumber(Data.CrateSizeX, 24)
			local Y = ACF.CheckNumber(Data.CrateSizeY, 24)
			local Z = ACF.CheckNumber(Data.CrateSizeZ, 24)

			Data.Size = Vector(X, Y, Z)
		end

		do -- The rest under applies to all ammo data formats
			-- Clamping size
			local Min  = ACF.AmmoMinSize
			local Max  = ACF.AmmoMaxSize
			local Size = Data.Size

			Size.x = math.Clamp(math.Round(Size.x), Min, Max)
			Size.y = math.Clamp(math.Round(Size.y), Min, Max)
			Size.z = math.Clamp(math.Round(Size.z), Min, Max)

			-- Destiny (string) may be already defined as "Weapons"/"Missiles", otherwise find the weapony source/"Weapons" 
			if not isstring(Data.Destiny) then
				Data.Destiny = ACF.FindWeaponrySource(Data.Weapon) or "Weapons"
			end

			-- Source (table) is a group representing weapons or missiles
			local Source = Classes[Data.Destiny]

			-- Class (table) is the specific class within the missile/weapon groups (example IDs: "AAM", "AC", "MG")
			local Class  = Classes.GetGroup(Source, Data.Weapon)

			-- E.g. happens if spawning a dupe that has a flare launcher on a server without acf missiles
			-- Can also happen if Data.Weapon wasn't specified (e.g. creating ammo via ACF function)
			if not Class then
				Class = Weapons.Get("C") -- Use 50mmC as a replacement

				Data.Destiny = "Weapons"
				Data.Weapon  = "C"
				Data.Caliber = Data.caliber or 50 -- If they somehow managed to specify caliber without specifying Weapon, otherwise use 50mm
			elseif Source.IsAlias(Data.Weapon) then -- This happens on certain weapons like smoothbores which are aliases of cannons
				Data.Weapon = Class.ID -- E.g. "SB"
			end

			-- TODO: FIX
			do -- Verifying and clamping caliber value
				local Weapon = Source.GetItem(Class.ID, Data.Weapon)

				if Weapon then -- Happens on pre scaleable guns (e.g. Data.Weapon="14.5mmMG", Class.ID="MG")
					if Class.IsScalable then -- If the class is scalable, set the weapon to the class' ID and bound its caliber
						local Bounds  = Class.Caliber
						local Caliber = ACF.CheckNumber(Weapon.Caliber, Bounds.Base)

						Data.Weapon  = Class.ID -- E.g. "MG"
						Data.Caliber = math.Clamp(Caliber, Bounds.Min, Bounds.Max)
					else
						-- If the class isn't scalable then this weapon is a registered item (e.g. 14.mmMG) and we use its caliber
						Data.Caliber = ACF.CheckNumber(Weapon.Caliber, 50)
					end
				end
			end

			-- If our ammo type does not exist or is blacklisted by this weapon, use defaults
			local Ammo = AmmoTypes.Get(Data.AmmoType)

			if not Ammo or Ammo.Blacklist[Class.ID] then
				Data.AmmoType = Class.DefaultAmmo or "AP"

				Ammo = AmmoTypes.Get(Data.AmmoType)
			end

			do -- External verifications
				Ammo:VerifyData(Data, Class) -- Custom verification function defined by each ammo type class

				if Class.VerifyData then -- Custom verification function possibly defined by a weapon class
					Class.VerifyData(Data, Class, Ammo)
				end

				HookRun("ACF_VerifyData", "acf_ammo", Data, Class, Ammo)
			end
		end
	end

	local function UpdateCrate(Entity, Data, Class, Weapon, Ammo)
		local Name, ShortName, WireName = Ammo:GetCrateName()
		local Scalable    = Class.IsScalable
		local Caliber     = Scalable and Data.Caliber or Weapon.Caliber
		local WeaponName  = Scalable and Caliber .. "mm " .. Class.Name or Weapon.Name
		local WeaponShort = Scalable and Caliber .. "mm" .. Class.ID or Weapon.ID

		Entity:SetSize(Data.Size)

		do -- Updating round data
			local OldAmmo = Entity.RoundData

			if OldAmmo then
				if OldAmmo.OnLast then
					OldAmmo:OnLast(Entity)
				end

				HookRun("ACF_OnAmmoLast", OldAmmo, Entity)
			end

			Entity.RoundData  = Ammo
			Entity.BulletData = Ammo:ServerConvert(Data) -- This helps sanitize and initialize the bullet data
			Entity.BulletData.Crate = Entity:EntIndex()

			if Ammo.OnFirst then
				Ammo:OnFirst(Entity)
			end

			HookRun("ACF_OnAmmoFirst", Ammo, Entity, Data, Class, Weapon)

			Ammo:Network(Entity, Entity.BulletData)
		end

		-- Storing onto the entity's table, all the relevant information that the entity saves when duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		-- Initialize some of the entity properties
		Entity.Name       = Name or WeaponName .. " " .. Ammo.Name
		Entity.ShortName  = ShortName or WeaponShort .. " " .. Ammo.ID
		Entity.EntType    = "Ammo Crate"
		Entity.ClassData  = Class
		Entity.Class      = Class.ID -- Needed for custom killicons
		Entity.WeaponData = Weapon
		Entity.Caliber    = Caliber

		WireIO.SetupInputs(Entity, Inputs, Data, Class, Weapon, Ammo)
		WireIO.SetupOutputs(Entity, Outputs, Data, Class, Weapon, Ammo)

		Entity:SetNWString("WireName", "ACF " .. (WireName or WeaponName .. " Ammo Crate"))

		do -- Ammo count calculation
			local Size       = Entity:GetSize()
			local BulletData = Entity.BulletData
			local Percentage = Entity.Capacity and Entity.Ammo / math.max(Entity.Capacity, 1) or 1
			local Rounds, ExtraData = ACF.GetAmmoCrateCapacity(Size, Class, Data, BulletData)

			Entity.Capacity = Rounds
			Entity.Ammo     = math.floor(Entity.Capacity * Percentage)

			WireLib.TriggerOutput(Entity, "Ammo", Entity.Ammo)

			Entity:SetNWInt("Ammo", Entity.Ammo) -- Sent to client for use in overlay

			if ExtraData then
				local MagSize = ACF.GetWeaponValue("MagSize", Caliber, Class, Weapon)

				-- for future use in reloading
				--Entity.IsBoxed = ExtraData.IsBoxed -- Ammunition is boxed
				--Entity.IsTwoPiece = ExtraData.IsTwoPiece -- Ammunition is broken down to two pieces

				ExtraData.MagSize = ExtraData.IsBoxed and MagSize or 0
				ExtraData.IsRound = not (ExtraData.IsBoxed or ExtraData.IsTwoPiece or ExtraData.IsRacked)
				ExtraData.Capacity = Entity.Capacity
				ExtraData.Enabled = true
			else
				ExtraData = { Enabled = false }
			end

			Entity.CrateData = util.TableToJSON(ExtraData)

			-- Send over the crate and ExtraData to the client to render the overlay
			net.Start("ACF_RequestAmmoData")
				net.WriteEntity(Entity)
				net.WriteString(Entity.CrateData)
			net.Broadcast()
		end

		-- Linked weapon unloading
		if next(Entity.Weapons) then -- Check if there are weapons linked to this entity
			local Unloaded

			for K in pairs(Entity.Weapons) do
				if K.CurrentCrate == Entity then
					Unloaded = true

					K:Unload()
				end
			end

			if Unloaded then
				ACF.SendNotify(Entity.Owner, false, "Crate updated while weapons were loaded with it's ammo. Weapons unloaded.")
			end
		end

		ACF.Activate(Entity, true) -- Makes Crate.ACF table

		Entity.ACF.Model = Entity:GetModel()

		Entity:UpdateMass(true)
	end

	util.PrecacheModel("models/holograms/hq_cylinder.mdl")
	util.AddNetworkString("ACF_RequestAmmoData")

	-- Whenever a player requests ammo data, we'll send it to them
	net.Receive("ACF_RequestAmmoData", function(_, Player)
		local Entity = net.ReadEntity()

		if IsValid(Entity) and Entity.CrateData then
			net.Start("ACF_RequestAmmoData")
				net.WriteEntity(Entity)
				net.WriteString(Entity.CrateData)
			net.Send(Player)
		end
	end)

	-- Called when checking if an entity can be spawned. 
	hook.Add("ACF_CanUpdateEntity", "ACF Crate Size Update", function(Entity, Data)
		if not Entity.IsACFAmmoCrate then return end
		if Data.Size then return end -- The menu won't send it like this

		Data.Size       = Entity:GetSize()
		Data.CrateSizeX = nil
		Data.CrateSizeY = nil
		Data.CrateSizeZ = nil
	end)

	-------------------------------------------------------------------------------

	function MakeACF_Ammo(Player, Pos, Ang, Data)
		if not Player:CheckLimit("_acf_ammo") then return end -- Check sbox limits

		VerifyData(Data)

		local Source = Classes[Data.Destiny] -- A group representing weapons or missiles
		local Class  = Classes.GetGroup(Source, Data.Weapon) -- The class representing a weapon type (example IDs: "AC", "HW", etc.)
		local Weapon = Source.GetItem(Class.ID, Data.Weapon) -- This is (unintentionally?) always nil due to Class.ID == Data.Weapon after verification
		local Ammo   = AmmoTypes.Get(Data.AmmoType) -- The class representing this ammo type
		local Model  = "models/holograms/rcube_thin.mdl"

		local CanSpawn = HookRun("ACF_PreEntitySpawn", "acf_ammo", Player, Data, Class, Weapon, Ammo)

		if CanSpawn == false then return false end

		local Crate = ents.Create("acf_ammo") -- Create the crate entity (still need to setup its properties below)

		if not IsValid(Crate) then return end

		Player:AddCleanup("acf_ammo", Crate)
		Player:AddCount("_acf_ammo", Crate)

		-- The entity's individual ACF table is used in things like storing the armor
		Crate.ACF       = Crate.ACF or {}
		Crate.ACF.Model = Model

		Crate:SetMaterial("phoenix_storms/Future_vents")
		Crate:SetPlayer(Player)
		Crate:SetScaledModel(Model)
		Crate:SetAngles(Ang)
		Crate:SetPos(Pos)
		Crate:Spawn()

		Crate.Owner       = Player -- MUST be stored on ent for PP
		Crate.IsExplosive = true
		Crate.Weapons     = {}
		Crate.DataStore	  = Entities.GetArguments("acf_ammo")

		UpdateCrate(Crate, Data, Class, Weapon, Ammo)

		WireLib.TriggerOutput(Crate, "Entity", Crate)

		if Class.OnSpawn then
			Class.OnSpawn(Crate, Data, Class, Weapon, Ammo)
		end

		HookRun("ACF_OnEntitySpawn", "acf_ammo", Crate, Data, Class, Weapon, Ammo)

		Crate:UpdateOverlay(true)

		-- Backwards compatibility with old crates
		if Data.Offset then
			local Position = Crate:LocalToWorld(Data.Offset)

			ACF.SaveEntity(Crate)

			Crate:SetPos(Position)

			ACF.RestoreEntity(Crate)

			-- Updating the dupe position
			if Data.BuildDupeInfo then
				Data.BuildDupeInfo.PosReset = Position
			end
		end

		-- Crates should be ready to load by default
		Crate:TriggerInput("Load", 1)

		ActiveCrates[Crate] = true -- ActiveCrates is a table stored globally that holds all the active crates

		ACF.CheckLegal(Crate)

		return Crate
	end

	Entities.Register("acf_ammo", MakeACF_Ammo, "Weapon", "Caliber", "AmmoType", "Size")

	ACF.RegisterLinkSource("acf_ammo", "Weapons")

	------------------- Updating ---------------------

	-- Entity method for ammo's specific behaviour when updating
	function ENT:Update(Data)
		VerifyData(Data)

		local Source = Classes[Data.Destiny] -- A group representing weapons or missiles
		local Class  = Classes.GetGroup(Source, Data.Weapon) -- The class representing a weapon type (example IDs: "AC", "HW", etc.)
		local Weapon = Source.GetItem(Class.ID, Data.Weapon) -- This is (unintentionally?) always nil due to Class.ID == Data.Weapon after verification
		local Caliber    = Weapon and Weapon.Caliber or Data.Caliber
		local OldClass   = self.ClassData -- (The same as "Class" above, just the previous weapon type)
		local OldWeapon  = self.Weapon
		local OldCaliber = self.Caliber
		local Ammo       = AmmoTypes.Get(Data.AmmoType) -- The class representing this ammo type
		local Blacklist  = Ammo.Blacklist
		local Extra      = ""

		local CanUpdate, Reason = HookRun("ACF_PreEntityUpdate", "acf_ammo", self, Data, Class, Weapon, Ammo)
		if CanUpdate == false then return CanUpdate, Reason end

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		HookRun("ACF_OnEntityLast", "acf_ammo", self, OldClass)

		ACF.SaveEntity(self)

		UpdateCrate(self, Data, Class, Weapon, Ammo)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, Weapon, Ammo)
		end

		HookRun("ACF_OnEntityUpdate", "acf_ammo", self, Data, Class, Weapon, Ammo)

		if Data.Weapon ~= OldWeapon or Caliber ~= OldCaliber or self.Unlinkable then
			-- Unlink if the weapon type or caliber has changed
			for Entity in pairs(self.Weapons) do
				self:Unlink(Entity)
			end

			Extra = " All weapons have been unlinked."
		else
			-- Unlink and unload all currently linked weapons that blacklist the new ammotype
			-- This will not do anything if all linked weapons accept the new ammotype
			local Count = 0
			for Entity in pairs(self.Weapons) do
				if Blacklist[Entity.Class] then
					self:Unlink(Entity)

					Entity:Unload()

					Count = Count + 1
				end
			end

			if Count > 0 then
				Extra = " Unlinked " .. Count .. " weapons from this crate."
			end
		end

		self:UpdateOverlay(true)

		-- Let the client know that we've updated this entity
		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		return true, "Crate updated successfully." .. Extra
	end
end ---------------------------------------------

do -- ACF Activation and Damage -----------------
	local Clock       = Utilities.Clock
	local Sounds      = Utilities.Sounds
	local Damage      = ACF.Damage
	local Objects     = Damage.Objects

	local function CookoffCrate(Entity)
		if Entity.Ammo < 1 or Entity.Damaged < Clock.CurTime then -- Detonate when time is up or crate is out of ammo
			timer.Remove("ACF Crate Cookoff " .. Entity:EntIndex())

			Entity.Damaged = nil

			Entity:Detonate()
		elseif Entity.BulletData.Type ~= "Refill" and Entity.RoundData then -- Spew bullets out everywhere
			local BulletData = Entity.BulletData
			local VolumeRoll = math.Rand(0, 150) > math.min(BulletData.RoundVolume ^ 0.5, 150 * 0.25) -- The larger the round volume, the less the chance of detonation (25% chance at minimum)
			local AmmoRoll   = math.Rand(0, 1) <= Entity.Ammo / math.max(Entity.Capacity, 1) -- The fuller the crate, the greater the chance of detonation

			if VolumeRoll and AmmoRoll then
				local Speed = ACF.MuzzleVelocity(BulletData.PropMass, BulletData.ProjMass * 0.5, BulletData.Efficiency) -- Half weight projectile?
				local Pitch = math.max(255 - BulletData.PropMass * 100,60) -- Pitch based on propellant mass

				Sounds.SendSound(Entity, "ambient/explosions/explode_4.wav", 140, Pitch, 1)

				BulletData.Pos    = Entity:LocalToWorld(Entity:OBBCenter() + VectorRand() * Entity:GetSize() * 0.5) -- Random position in the ammo crate
				BulletData.Flight = VectorRand():GetNormalized() * Speed * 39.37 + Contraption.GetAncestor(Entity):GetVelocity() -- Random direction including baseplate speed

				BulletData.Owner  = Entity.Inflictor or Entity.Owner
				BulletData.Gun    = Entity
				BulletData.Crate  = Entity:EntIndex()

				Entity.RoundData:Create(Entity, BulletData)

				Entity:Consume()
			end
		end
	end

	-------------------------------------------------------------------------------

	function ENT:ACF_Activate(Recalc)
		local PhysObj = self.ACF.PhysObj
		local Area    = PhysObj:GetSurfaceArea() * ACF.InchToCmSq
		local Armour  = ACF.AmmoArmor * ACF.ArmorMod
		local Health  = Area / ACF.Threshold
		local Percent = 1

		if Recalc and self.ACF.Health and self.ACF.MaxHealth then
			Percent = self.ACF.Health / self.ACF.MaxHealth
		end

		self.ACF.Area      = Area
		self.ACF.Health    = Health * Percent
		self.ACF.MaxHealth = Health
		self.ACF.Armour    = Armour * (0.5 + Percent * 0.5)
		self.ACF.MaxArmour = Armour
		self.ACF.Type      = "Prop"
	end

	function ENT:ACF_OnDamage(DmgResult, DmgInfo)
		local HitRes = Damage.doPropDamage(self, DmgResult, DmgInfo) -- Calling the standard prop damage function

		if self.Exploding or not self.IsExplosive then return HitRes end

		local Inflictor = DmgInfo:GetInflictor()

		if HitRes.Kill then
			if IsValid(Inflictor) and Inflictor:IsPlayer() then
				self.Inflictor = Inflictor
			end

			if self.Ammo > 0 then
				self:Detonate()
			end

			return HitRes
		end

		-- Cookoff chance
		if self.Damaged then return HitRes end -- Already cooking off

		local Ratio = (HitRes.Damage / self.BulletData.RoundVolume) ^ 0.2

		if (Ratio * self.Capacity / self.Ammo) > math.random() then
			self.Inflictor = Inflictor

			if HookRun("ACF_AmmoCanCookOff", self) ~= false then
				self.Damaged = Clock.CurTime + (5 - Ratio * 3) -- Time to cook off is 5 - (How filled it is * 3)

				local Interval = 0.01 + self.BulletData.RoundVolume ^ 0.5 / 100

				TimerCreate("ACF Crate Cookoff " .. self:EntIndex(), Interval, 0, function()
					if not IsValid(self) then return end

					CookoffCrate(self)
				end)
			else
				self:Detonate()
			end
		end

		return HitRes
	end

	function ENT:Detonate()
		if self.Exploding then return end
		if HookRun("ACF_AmmoExplode", self) == false then return end

		self.Exploding = true

		local Position   = self:LocalToWorld(self:OBBCenter() + VectorRand() * self:GetSize() * 0.5) -- Random position within the crate
		local BulletData = self.BulletData
		local Filler     = BulletData.FillerMass or 0
		local Propellant = BulletData.PropMass or 0
		local AmmoPower  = self.Ammo ^ 0.7 -- Arbitrary exponent to reduce ammo-based explosive power
		local Explosive  = (Filler + Propellant * (ACF.PropImpetus / ACF.HEPower)) * AmmoPower
		local FragMass   = BulletData.ProjMass or Explosive * 0.5
		local DmgInfo    = Objects.DamageInfo(self, self.Inflictor)

		ACF.KillChildProps(self, Position, Explosive)

		Damage.createExplosion(Position, Explosive, FragMass, { self }, DmgInfo)
		Damage.explosionEffect(Position, nil, Explosive)

		constraint.RemoveAll(self)

		self:Remove()
	end
end ---------------------------------------------

do -- Entity Inputs -----------------------------
	WireLib.AddInputAlias("Active", "Load")
	WireLib.AddOutputAlias("Munitions", "Ammo")

	ACF.AddInputAction("acf_ammo", "Load", function(Entity, Value)
		Entity.Load = tobool(Value)

		WireLib.TriggerOutput(Entity, "Loading", Entity:CanConsume() and 1 or 0)
	end)
end ---------------------------------------------

do -- Entity Overlay ----------------------------
	local Text = "%s\n\nSize: %sx%sx%s\n\nContents: %s ( %s / %s )%s%s%s"
	local BulletText = "\nCartridge Mass: %s kg\nProjectile Mass: %s kg\nPropellant Mass: %s kg"

	function ENT:UpdateOverlayText()
		local Tracer = self.BulletData.Tracer ~= 0 and "-T" or ""
		local AmmoType = self.BulletData.Type .. Tracer
		local X, Y, Z = self:GetSize():Unpack()
		local AmmoInfo = self.RoundData:GetCrateText(self.BulletData)
		local ExtraInfo = ACF.GetOverlayText(self)
		local BulletInfo = ""
		local Status

		if next(self.Weapons) or self.IsRefill then
			Status = self:CanConsume() and "Providing Ammo" or (self.Ammo ~= 0 and "Idle" or "Empty")
		else
			Status = "Not linked to a weapon!"
		end

		X = math.Round(X, 2)
		Y = math.Round(Y, 2)
		Z = math.Round(Z, 2)

		if self.BulletData.Type ~= "Refill" then
			local Projectile = math.Round(self.BulletData.ProjMass, 2)
			local Propellant = math.Round(self.BulletData.PropMass, 2)
			local Cartridge  = math.Round(self.BulletData.CartMass, 2)

			BulletInfo = BulletText:format(Cartridge, Projectile, Propellant)
		end

		if AmmoInfo and AmmoInfo ~= "" then
			AmmoInfo = "\n\n" .. AmmoInfo
		end

		return Text:format(Status, X, Y, Z, AmmoType, self.Ammo, self.Capacity, BulletInfo, AmmoInfo, ExtraInfo)
	end
end ---------------------------------------------

do -- Mass Update -------------------------------
	local function UpdateMass(Ent)
		local Mass = math.floor(Ent.EmptyMass + Ent.Ammo * Ent.BulletData.CartMass)

		Contraption.SetMass(Ent,Mass)
	end

	-------------------------------------------------------------------------------

	function ENT:UpdateMass(Instant)
		if Instant then
			return UpdateMass(self)
		end

		if TimerExists("ACF Mass Buffer" .. self:EntIndex()) then return end

		TimerCreate("ACF Mass Buffer" .. self:EntIndex(), 5, 1, function()
			if not IsValid(self) then return end

			UpdateMass(self)
		end)
	end
end ---------------------------------------------

do -- Ammo Consumption -------------------------
	function ENT:CanConsume()
		local SelfTbl = self:GetTable()

		if SelfTbl.Disabled then return false end
		if not SelfTbl.Load then return false end
		if SelfTbl.Damaged then return false end

		return SelfTbl.Ammo > 0
	end

	function ENT:Consume(Num)
		self.Ammo = math.Clamp(self.Ammo - (Num or 1), 0, self.Capacity)

		self:UpdateOverlay()
		self:UpdateMass()

		WireLib.TriggerOutput(self, "Ammo", self.Ammo)
		WireLib.TriggerOutput(self, "Loading", self:CanConsume() and 1 or 0)

		if TimerExists("ACF Network Ammo " .. self:EntIndex()) then return end

		TimerCreate("ACF Network Ammo " .. self:EntIndex(), 0.5, 1, function()
			if not IsValid(self) then return end

			self:SetNWInt("Ammo", self.Ammo)
		end)
	end
end ---------------------------------------------

do -- Misc --------------------------------------
	function ENT:Enable()
		WireLib.TriggerOutput(self, "Loading", self:CanConsume() and 1 or 0)

		self:UpdateMass(true)
	end

	function ENT:Disable()
		WireLib.TriggerOutput(self, "Loading", 0)

		self:UpdateMass(true)
	end

	function ENT:OnResized(Size)
		do -- Calculate new empty mass
			local A = ACF.AmmoArmor * 0.039 -- Millimeters to inches
			local ExteriorVolume = Size.x * Size.y * Size.z
			local InteriorVolume = (Size.x - A) * (Size.y - A) * (Size.z - A) -- Math degree

			local Volume = ExteriorVolume - InteriorVolume
			local Mass   = Volume * 0.13 -- Kg of steel per inch

			self.EmptyMass = Mass
		end

		self.HitBoxes = {
			Main = {
				Pos = self:OBBCenter(),
				Scale = Size,
			}
		}
	end

	function ENT:OnRemove()
		local Class = self.ClassData

		if Class.OnLast then
			Class.OnLast(self, Class)
		end

		HookRun("ACF_OnEntityLast", "acf_ammo", self, Class)

		ActiveCrates[self] = nil

		if self.RoundData.OnLast then
			self.RoundData:OnLast(self)
		end

		-- Detonate immediately if cooking off
		if self.Damaged then
			timer.Remove("ACF Crate Cookoff " .. self:EntIndex()) -- Prevent multiple explosions

			self:Detonate()
		end

		for K in pairs(self.Weapons) do -- Unlink weapons
			self:Unlink(K)
		end

		WireLib.Remove(self)
	end
end ---------------------------------------------
