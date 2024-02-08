AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Local Vars -----------------------------------

local ACF         = ACF
local Contraption = ACF.Contraption
local Classes     = ACF.Classes
local AmmoTypes   = Classes.AmmoTypes
local Utilities   = ACF.Utilities
local Clock       = Utilities.Clock
local Sounds      = Utilities.Sounds
local TimerCreate = timer.Create
local HookRun     = hook.Run
local EMPTY       = { Type = "Empty", PropMass = 0, ProjMass = 0, Tracer = 0 }

-- TODO: Replace with CFrame as soon as it's available
local function UpdateTotalAmmo(Entity)
	local Total = 0

	for Crate in pairs(Entity.Crates) do
		if Crate:CanConsume() then
			Total = Total + Crate.Ammo
		end
	end

	Entity.TotalAmmo = Total

	WireLib.TriggerOutput(Entity, "Total Ammo", Total)
end

do -- Spawn and Update functions --------------------------------
	local ModelData = ACF.ModelData
	local WireIO    = Utilities.WireIO
	local Entities  = Classes.Entities
	local Weapons   = Classes.Weapons

	local Inputs = {
		"Fire (Attempts to fire the weapon.)",
		"Unload (Forces the weapon to empty itself)",
		"Reload (Forces the weapon to reload itself.)"
	}
	local Outputs = {
		"Ready (Returns 1 if the weapon can be fired.)",
		"Status (Returns the current state of the weapon.) [STRING]",
		"Ammo Type (Returns  the name of the currently loaded ammo type.) [STRING]",
		"Shots Left (Returns the amount of rounds left in the breech or magazine.)",
		"Total Ammo (Returns the amount of rounds available for this weapon.)",
		"Rate of Fire (Returns the amount of rounds per minute the weapon can fire.)",
		"Reload Time (Returns the amount of time in seconds it'll take to reload the weapon.)",
		"Projectile Mass (Returns the mass in grams of the currently loaded projectile.)",
		"Muzzle Velocity (Returns the speed in m/s of the currently loaded projectile.)",
		"Entity (The weapon itself.) [ENTITY]",
	}

	local function VerifyData(Data)
		if not isstring(Data.Weapon) then
			Data.Weapon = Data.Id
		end

		local Class = Classes.GetGroup(Weapons, Data.Weapon)

		if not Class then
			Class = Weapons.Get("C")

			Data.Destiny = "Weapons"
			Data.Weapon  = "C"
			Data.Caliber = 50
		elseif Weapons.IsAlias(Data.Weapon) then
			Data.Weapon = Class.ID
		end

		-- Verifying and clamping caliber value
		if Class.IsScalable then
			local Weapon = Weapons.GetItem(Class.ID, Data.Weapon)

			if Weapon then
				Data.Weapon  = Class.ID
				Data.Caliber = Weapon.Caliber
			end

			local Bounds  = Class.Caliber
			local Caliber = ACF.CheckNumber(Data.Caliber, Bounds.Base)

			Data.Caliber = math.Clamp(Caliber, Bounds.Min, Bounds.Max)
		end

		do -- External verifications
			if Class.VerifyData then
				Class.VerifyData(Data, Class)
			end

			HookRun("ACF_VerifyData", "acf_gun", Data, Class)
		end
	end

	local function GetSound(Caliber, Class, Weapon)
		local Result = Weapon and Weapon.Sound or Class.Sound
		local ClassSounds = Class.Sounds

		if ClassSounds then
			local Lowest = math.huge

			for Current, Sound in pairs(ClassSounds) do
				if Caliber <= Current and Current <= Lowest then
					Lowest = Current
					Result = Sound
				end
			end
		end

		return Result
	end

	local function GetMass(Model, PhysObj, Class, Weapon)
		if Weapon then return Weapon.Mass end

		local Volume = PhysObj:GetVolume()
		local Factor = Volume / ModelData.GetModelVolume(Model)

		return math.Round(Class.Mass * Factor)
	end

	local function UpdateWeapon(Entity, Data, Class, Weapon)
		local Model   = Weapon and Weapon.Model or Class.Model
		local Caliber = Weapon and Weapon.Caliber or Data.Caliber
		local Scale   = Weapon and 1 or Caliber / Class.Caliber.Base
		local Cyclic  = ACF.GetWeaponValue("Cyclic", Caliber, Class, Weapon)
		local MagSize = ACF.GetWeaponValue("MagSize", Caliber, Class, Weapon) or 1

		Entity.ACF.Model = Model

		Entity:SetScaledModel(Model)
		Entity:SetScale(Scale)

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name         = Weapon and Weapon.Name or (Caliber .. "mm " .. Class.Name)
		Entity.ShortName    = Weapon and Weapon.ID or (Caliber .. "mm" .. Class.ID)
		Entity.EntType      = Class.Name
		Entity.ClassData    = Class
		Entity.Class        = Class.ID -- Needed for custom killicons
		Entity.Caliber      = Caliber
		Entity.MagReload    = ACF.GetWeaponValue("MagReload", Caliber, Class, Weapon)
		Entity.MagSize      = math.floor(MagSize)
		Entity.BaseCyclic   = Cyclic and 60 / Cyclic
		Entity.Cyclic       = Entity.BaseCyclic
		Entity.ReloadTime   = Entity.Cyclic or 1
		Entity.Spread       = Class.Spread
		Entity.DefaultSound = GetSound(Caliber, Class)
		Entity.SoundPath    = Entity.SoundPath or Entity.DefaultSound
		Entity.SoundPitch   = Entity.SoundPitch or 1
		Entity.SoundVolume  = Entity.SoundVolume or 1
		Entity.HitBoxes     = ACF.GetHitboxes(Model, Scale)
		Entity.Long         = Class.LongBarrel
		Entity.NormalMuzzle = Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("muzzle")).Pos)
		Entity.Muzzle       = Entity.NormalMuzzle

		WireIO.SetupInputs(Entity, Inputs, Data, Class, Weapon)
		WireIO.SetupOutputs(Entity, Outputs, Data, Class, Weapon)

		-- Set NWvars
		Entity:SetNWString("WireName", "ACF " .. Entity.Name)
		Entity:SetNWString("Sound", Entity.SoundPath)
		Entity:SetNWString("SoundPitch", Entity.SoundPitch)
		Entity:SetNWString("SoundVolume", Entity.SoundVolume)
		Entity:SetNWString("Class", Entity.Class)

		-- Adjustable barrel length
		if Entity.Long then
			local Attachment = Entity:GetAttachment(Entity:LookupAttachment(Entity.Long.NewPos))

			Entity.LongMuzzle = Attachment and Entity:WorldToLocal(Attachment.Pos)
		end

		if Entity.Cyclic then -- Automatics don't change their rate of fire
			WireLib.TriggerOutput(Entity, "Reload Time", Entity.Cyclic)
			WireLib.TriggerOutput(Entity, "Rate of Fire", 60 / Entity.Cyclic)
		end

		ACF.Activate(Entity, true)

		local PhysObj = Entity.ACF.PhysObj

		if IsValid(PhysObj) then
			local Mass = GetMass(Model, PhysObj, Class, Weapon)

			Contraption.SetMass(Entity, Mass)
		end
	end

	hook.Add("ACF_OnSetupInputs", "ACF Weapon Fuze", function(Entity, List)
		if Entity:GetClass() ~= "acf_gun" then return end
		if Entity.Caliber <= ACF.MinFuzeCaliber then return end

		List[#List + 1] = "Fuze (Sets the delay in seconds in which explosive rounds will detonate after leaving the weapon.)"
	end)

	hook.Add("ACF_OnSetupInputs", "ACF Cyclic ROF", function(Entity, List)
		if Entity:GetClass() ~= "acf_gun" then return end
		if not Entity.BaseCyclic then return end

		List[#List + 1] = "Rate of Fire (Sets the rate of fire of the weapon in rounds per minute)"
	end)

	-------------------------------------------------------------------------------

	function MakeACF_Weapon(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class = Classes.GetGroup(Weapons, Data.Weapon)
		local Limit = Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return false end -- Check gun spawn limits

		local Weapon   = Weapons.GetItem(Class.ID, Data.Weapon)
		local CanSpawn = HookRun("ACF_PreEntitySpawn", "acf_gun", Player, Data, Class, Weapon)

		if CanSpawn == false then return false end

		local Entity = ents.Create("acf_gun")

		if not IsValid(Entity) then return end

		Player:AddCleanup(Class.Cleanup, Entity)
		Player:AddCount(Limit, Entity)

		Entity.ACF			= {}

		Contraption.SetModel(Entity, Weapon and Weapon.Model or Class.Model)

		Entity:SetPlayer(Player)
		Entity:SetAngles(Angle)
		Entity:SetPos(Pos)
		Entity:Spawn()

		Entity.Owner        = Player -- MUST be stored on ent for PP
		Entity.BarrelFilter = { Entity }
		Entity.State        = "Empty"
		Entity.Crates       = {}
		Entity.CurrentShot  = 0
		Entity.TotalAmmo    = 0
		Entity.BulletData   = EMPTY
		Entity.DataStore    = Entities.GetArguments("acf_gun")

		UpdateWeapon(Entity, Data, Class, Weapon)

		WireLib.TriggerOutput(Entity, "Status", "Empty")
		WireLib.TriggerOutput(Entity, "Entity", Entity)
		WireLib.TriggerOutput(Entity, "Ammo Type", "Empty")
		WireLib.TriggerOutput(Entity, "Projectile Mass", 1000)
		WireLib.TriggerOutput(Entity, "Muzzle Velocity", 1000)

		if Class.OnSpawn then
			Class.OnSpawn(Entity, Data, Class, Weapon)
		end

		HookRun("ACF_OnEntitySpawn", "acf_gun", Entity, Data, Class, Weapon)

		Entity:UpdateOverlay(true)

		do -- Mass entity mod removal
			local EntMods = Data and Data.EntityMods

			if EntMods and EntMods.mass then
				EntMods.mass = nil
			end
		end

		TimerCreate("ACF Ammo Left " .. Entity:EntIndex(), 1, 0, function()
			if not IsValid(Entity) then return end

			UpdateTotalAmmo(Entity)
		end)

		ACF.CheckLegal(Entity)

		return Entity
	end

	Entities.Register("acf_gun", MakeACF_Weapon, "Weapon", "Caliber")

	ACF.RegisterLinkSource("acf_gun", "Crates")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		if self.Firing then return false, "Stop firing before updating the weapon!" end

		VerifyData(Data)

		local Class    = Classes.GetGroup(Weapons, Data.Weapon)
		local Weapon   = Weapons.GetItem(Class.ID, Data.Weapon)
		local OldClass = self.ClassData

		local CanUpdate, Reason = HookRun("ACF_PreEntityUpdate", "acf_gun", self, Data, Class, Weapon)

		if CanUpdate == false then return CanUpdate, Reason end

		if self.State ~= "Empty" then
			self:Unload()
		end

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		HookRun("ACF_OnEntityLast", "acf_gun", self, OldClass)

		ACF.SaveEntity(self)

		UpdateWeapon(self, Data, Class, Weapon)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, Weapon)
		end

		HookRun("ACF_OnEntityUpdate", "acf_gun", self, Data, Class, Weapon)

		if next(self.Crates) then
			for Crate in pairs(self.Crates) do
				self:Unlink(Crate)
			end
		end

		self:UpdateOverlay(true)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		return true, "Weapon updated successfully!"
	end
end ---------------------------------------------

do -- Metamethods --------------------------------
	do -- Inputs/Outputs/Linking ----------------
		WireLib.AddOutputAlias("AmmoCount", "Total Ammo")
		WireLib.AddOutputAlias("Muzzle Weight", "Projectile Mass")

		ACF.RegisterClassLink("acf_gun", "acf_ammo", function(This, Crate)
			if This.Crates[Crate] then return false, "This weapon is already linked to this crate." end
			if Crate.Weapons[This] then return false, "This weapon is already linked to this crate." end
			if Crate.IsRefill then return false, "Refill crates cannot be linked to weapons." end
			if This.Weapon ~= Crate.Weapon then return false, "Wrong ammo type for this weapon." end
			if This.Caliber ~= Crate.Caliber then return false, "Wrong ammo type for this weapon." end

			local Blacklist = Crate.RoundData.Blacklist

			if Blacklist[This.Class] then
				return false, "The ammo type in this crate cannot be used for this weapon."
			end

			This.Crates[Crate]  = true
			Crate.Weapons[This] = true

			This:UpdateOverlay(true)
			Crate:UpdateOverlay(true)

			if This.State == "Empty" then -- When linked to an empty weapon, attempt to load it
				timer.Simple(0.5, function() -- Delay by 500ms just in case the wiring isn't applied at the same time or whatever weird dupe shit happens
					if IsValid(This) and IsValid(Crate) and This.State == "Empty" and Crate:CanConsume() then
						This:Load()
					end
				end)
			end

			return true, "Weapon linked successfully."
		end)

		ACF.RegisterClassUnlink("acf_gun", "acf_ammo", function(This, Crate)
			if This.Crates[Crate] or Crate.Weapons[This] then
				if This.CurrentCrate == Crate then
					This.CurrentCrate = next(This.Crates, Crate)
				end

				This.Crates[Crate]  = nil
				Crate.Weapons[This] = nil

				This:UpdateOverlay(true)
				Crate:UpdateOverlay(true)

				return true, "Weapon unlinked successfully."
			end

			return false, "This weapon is not linked to this crate."
		end)

		ACF.AddInputAction("acf_gun", "Fire", function(Entity, Value)
			local Bool = tobool(Value)

			Entity.Firing = Bool

			if Bool and Entity:CanFire() then
				Entity:Shoot()
			end
		end)

		ACF.AddInputAction("acf_gun", "Unload", function(Entity, Value)
			if tobool(Value) and Entity.State == "Loaded" then
				Entity:Unload()
			end
		end)

		ACF.AddInputAction("acf_gun", "Reload", function(Entity, Value)
			if tobool(Value) then
				if Entity.State == "Loaded" then
					Entity:Unload(true) -- Unload, then reload
				elseif Entity.State == "Empty" then
					Entity:Load()
				end
			end
		end)

		ACF.AddInputAction("acf_gun", "Fuze", function(Entity, Value)
			Entity.SetFuze = tobool(Value) and math.abs(Value)
		end)

		ACF.AddInputAction("acf_gun", "Rate of Fire", function(Entity, Value)
			if not Entity.BaseCyclic then return end

			local Delay = 60 / math.max(Value, 1)

			Entity.Cyclic     = math.Clamp(Delay, Entity.BaseCyclic, 2)
			Entity.ReloadTime = Entity.Cyclic
		end)
	end -----------------------------------------

	do -- Shooting ------------------------------
		local TraceRes  = {} -- Output for traces
		local TraceData = { start = true, endpos = true, filter = true, mask = MASK_SOLID, output = TraceRes }

		function ENT:BarrelCheck()
			local owner  = self:GetPlayer()
			local filter = self.BarrelFilter

			TraceData.start	 = self:GetPos()
			TraceData.endpos = self:LocalToWorld(self.Muzzle)
			TraceData.filter = filter

			ACF.trace(TraceData)

			while TraceRes.HitNonWorld do
				local Entity = TraceRes.Entity

				if Entity.IsACFEntity and not (Entity.IsACFArmor or Entity.IsACFTurret) then break end
				if Entity:CPPIGetOwner() ~= owner then break end

				filter[#filter + 1] = Entity

				ACF.trace(TraceData)
			end

			return TraceRes.HitPos
		end

		function ENT:CanFire()
			if not ACF.GunsCanFire then return false end -- Disabled by the server
			if not self.Firing then return false end -- Nobody is holding the trigger
			if self.Disabled then return false end -- Disabled
			if self.State ~= "Loaded" then -- Weapon is not loaded
				if self.State == "Empty" and not self.Retry then
					if not self:Load() then
						Sounds.SendSound(self, "weapons/pistol/pistol_empty.wav", 70, 100, 1) -- Click!
					end

					self.Retry = true

					timer.Simple(1, function() -- Try again after a second
						if IsValid(self) then
							self.Retry = nil

							if self:CanFire() then
								self:Shoot()
							end
						end
					end)
				end

				return false
			end
			if HookRun("ACF_FireShell", self) == false then return false end -- Something hooked into ACF_FireShell said no

			return true
		end

		function ENT:GetSpread()
			local SpreadScale = ACF.SpreadScale
			local IaccMult    = math.Clamp(((1 - SpreadScale) / 0.5) * ((self.ACF.Health / self.ACF.MaxHealth) - 1) + 1, 1, SpreadScale)

			return self.Spread * ACF.GunInaccuracyScale * IaccMult
		end

		function ENT:Shoot()
			local Cone = math.tan(math.rad(self:GetSpread()))
			local randUnitSquare = (self:GetUp() * (2 * math.random() - 1) + self:GetRight() * (2 * math.random() - 1))
			local Spread = randUnitSquare:GetNormalized() * Cone * (math.random() ^ (1 / ACF.GunInaccuracyBias))
			local Dir = (self:GetForward() + Spread):GetNormalized()
			local Velocity = Contraption.GetAncestor(self):GetVelocity()
			local AmmoType = AmmoTypes.Get(self.BulletData.Type)

			if self.BulletData.CanFuze and self.SetFuze then
				local Variance = math.Rand(-0.015, 0.015) * math.max(0, 203 - self.Caliber) * 0.01

				self.Fuze = math.max(self.SetFuze, 0.02) + Variance -- If possible, we're gonna update the fuze time
			else
				self.Fuze = nil
			end

			self.CurrentUser = self:GetUser(self.Inputs.Fire.Src) -- Must be updated on every shot

			self.BulletData.Owner  = self.CurrentUser
			self.BulletData.Gun	   = self -- because other guns share this table
			self.BulletData.Pos    = self:BarrelCheck()
			self.BulletData.Flight = Dir * self.BulletData.MuzzleVel * 39.37 + Velocity
			self.BulletData.Fuze   = self.Fuze -- Must be set when firing as the table is shared
			self.BulletData.Filter = self.BarrelFilter

			AmmoType:Create(self, self.BulletData) -- Spawn projectile

			self:MuzzleEffect()
			self:Recoil()

			local Energy = ACF.Kinetic(self.BulletData.MuzzleVel * 39.37, self.BulletData.ProjMass).Kinetic

			if Energy > 50 then -- Why yes, this is completely arbitrary! 20mm AC AP puts out about 115, 40mm GL HE puts out about 20
				ACF.Overpressure(self:LocalToWorld(self.Muzzle) - self:GetForward() * 5, Energy, self.BulletData.Owner, self, self:GetForward(), 30)
			end

			if self.MagSize then -- Mag-fed/Automatically loaded
				self.CurrentShot = self.CurrentShot - 1

				if self.CurrentShot > 0 then -- Not empty
					self:Chamber(self.Cyclic)
				else -- Reload the magazine
					self:Load()
				end
			else -- Single-shot/Manually loaded
				self.CurrentShot = 0 -- We only have one shot, so shooting means we're at 0
				self:Chamber()
			end
		end

		function ENT:MuzzleEffect()
			if not ACF.GunsCanSmoke then return end

			local Effect = EffectData()
				Effect:SetEntity(self)
				Effect:SetScale(self.BulletData.PropMass)
				Effect:SetMagnitude(self.ReloadTime)

			util.Effect("ACF_Muzzle_Flash", Effect, true, true)
		end

		function ENT:ReloadEffect(Time)
			local Effect = EffectData()
				Effect:SetEntity(self)
				Effect:SetScale(0)
				Effect:SetMagnitude(Time)

			util.Effect("ACF_Muzzle_Flash", Effect, true, true)
		end

		function ENT:Recoil()
			if not ACF.RecoilPush then return end

			local MassCenter = self:LocalToWorld(self:GetPhysicsObject():GetMassCenter())
			local Energy = self.BulletData.ProjMass * self.BulletData.MuzzleVel * 39.37 + self.BulletData.PropMass * 3000 * 39.37

			ACF.KEShove(self, MassCenter, -self:GetForward(), Energy)
		end
	end -----------------------------------------

	do -- Loading -------------------------------
		local function FindNextCrate(Gun)
			if not next(Gun.Crates) then return end

			-- Find the next available crate to pull ammo from --
			local Select = next(Gun.Crates, Gun.CurrentCrate) or next(Gun.Crates)
			local Start  = Select

			repeat
				if Select:CanConsume() then return Select end -- Return select

				Select = next(Gun.Crates, Select) or next(Gun.Crates)
			until
				Select == Start
		end

		function ENT:Unload(Reload)
			if self.Disabled then return end
			if IsValid(self.CurrentCrate) then self.CurrentCrate:Consume(-1) end -- Put a shell back in the crate, if possible

			local Time = self.MagReload or self.ReloadTime

			self:ReloadEffect(Reload and Time * 2 or Time)
			self:SetState("Unloading")
			Sounds.SendSound(self, "weapons/357/357_reload4.wav", 70, 100, 1)
			self.CurrentShot = 0
			self.BulletData  = EMPTY

			WireLib.TriggerOutput(self, "Ammo Type", "Empty")
			WireLib.TriggerOutput(self, "Shots Left", 0)

			timer.Simple(Time, function()
				if IsValid(self) then
					if Reload then
						self:Load()
					else
						self:SetState("Empty")
					end
				end
			end)
		end

		function ENT:Chamber(TimeOverride)
			if self.Disabled then return end

			local Crate = FindNextCrate(self)

			if IsValid(Crate) then -- Have a crate, start loading
				self:SetState("Loading") -- Set our state to loading
				Crate:Consume() -- Take one round of ammo out of the current crate (Must be called *after* setting the state to loading)

				local BulletData = Crate.BulletData
				local Time		 = TimeOverride or (ACF.BaseReload + (BulletData.CartMass * ACF.MassToTime * 0.666) + (BulletData.ProjLength * ACF.LengthToTime * 0.333)) -- Mass contributes 2/3 of the reload time with length contributing 1/3

				self.CurrentCrate = Crate
				self.ReloadTime   = Time
				self.BulletData   = BulletData
				self.NextFire 	  = Clock.CurTime + Time

				if not TimeOverride then -- Mag-fed weapons don't change rate of fire
					WireLib.TriggerOutput(self, "Reload Time", self.ReloadTime)
					WireLib.TriggerOutput(self, "Rate of Fire", 60 / self.ReloadTime)
				end

				WireLib.TriggerOutput(self, "Ammo Type", BulletData.Type)
				WireLib.TriggerOutput(self, "Shots Left", self.CurrentShot)

				timer.Simple(Time, function()
					if IsValid(self) then
						if self.CurrentShot == 0 then
							self.CurrentShot = math.min(self.MagSize, self.TotalAmmo)
						end

						self.NextFire = nil

						WireLib.TriggerOutput(self, "Shots Left", self.CurrentShot)
						WireLib.TriggerOutput(self, "Projectile Mass", math.Round(self.BulletData.ProjMass * 1000, 2))
						WireLib.TriggerOutput(self, "Muzzle Velocity", math.Round(self.BulletData.MuzzleVel * ACF.Scale, 2))

						self:SetState("Loaded")

						if self:CanFire() then self:Shoot() end
					end
				end)
			else -- No available crate to pull ammo from, out of ammo!
				self:SetState("Empty")

				self.CurrentShot = 0
				self.BulletData  = EMPTY

				WireLib.TriggerOutput(self, "Ammo Type", "Empty")
				WireLib.TriggerOutput(self, "Shots Left", 0)
			end
		end

		function ENT:Load()
			if self.Disabled then return false end
			if not FindNextCrate(self) then -- Can't load without having ammo being provided
				self:SetState("Empty")

				self.CurrentShot = 0
				self.BulletData  = EMPTY

				WireLib.TriggerOutput(self, "Ammo Type", "Empty")
				WireLib.TriggerOutput(self, "Shots Left", 0)

				return false
			end

			self:SetState("Loading")

			if self.MagReload then -- Mag-fed/Automatically loaded
				Sounds.SendSound(self, "weapons/357/357_reload4.wav", 70, 100, 1)

				self.NextFire = Clock.CurTime + self.MagReload

				WireLib.TriggerOutput(self, "Shots Left", self.CurrentShot)

				timer.Simple(self.MagReload, function() -- Reload timer
					if IsValid(self) then
						self:Chamber(self.Cyclic) -- One last timer to chamber the round
					end
				end)
			else -- Single-shot/Manually loaded
				self:Chamber()
			end

			return true
		end
	end -----------------------------------------

	do -- Duplicator Support --------------------
		function ENT:PreEntityCopy()
			if next(self.Crates) then
				local Entities = {}

				for Crate in pairs(self.Crates) do
					Entities[#Entities + 1] = Crate:EntIndex()
				end

				duplicator.StoreEntityModifier(self, "ACFCrates", Entities)
			end

			-- Wire dupe info
			self.BaseClass.PreEntityCopy(self)
		end

		function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
			local EntMods = Ent.EntityMods

			-- Backwards compatibility
			if EntMods.ACFAmmoLink then
				local Entities = EntMods.ACFAmmoLink.entities

				for _, EntID in ipairs(Entities) do
					self:Link(CreatedEntities[EntID])
				end

				EntMods.ACFAmmoLink = nil
			end

			if EntMods.ACFCrates then
				for _, EntID in pairs(EntMods.ACFCrates) do
					self:Link(CreatedEntities[EntID])
				end

				EntMods.ACFCrates = nil
			end

			self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
		end
	end -----------------------------------------

	do -- Overlay -------------------------------
		local Text = "%s\n\nRate of Fire: %s rpm\nShots Left: %s\nAmmo Available: %s"

		function ENT:UpdateOverlayText()
			local AmmoType  = self.BulletData.Type .. (self.BulletData.Tracer ~= 0 and "-T" or "")
			local Firerate  = math.floor(60 / self.ReloadTime)
			local CrateAmmo = 0
			local Status

			if not next(self.Crates) then
				Status = "Not linked to an ammo crate!"
			else
				Status = self.State == "Loaded" and "Loaded with " .. AmmoType or self.State
			end

			for Crate in pairs(self.Crates) do -- Tally up the amount of ammo being provided by active crates
				if Crate:CanConsume() then
					CrateAmmo = CrateAmmo + Crate.Ammo
				end
			end

			return Text:format(Status, Firerate, self.CurrentShot, CrateAmmo)
		end
	end -----------------------------------------

	do -- Misc ----------------------------------
		local MaxDistance = ACF.LinkDistance * ACF.LinkDistance
		local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"

		function ENT:ACF_Activate(Recalc)
			local PhysObj = self.ACF.PhysObj
			local Area    = PhysObj:GetSurfaceArea() * 6.45
			local Armour  = self.Caliber * ACF.ArmorMod
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

		function ENT:SetState(State)
			self.State = State

			self:UpdateOverlay()

			WireLib.TriggerOutput(self, "Status", State)
			WireLib.TriggerOutput(self, "Ready", State == "Loaded" and 1 or 0)

			UpdateTotalAmmo(self)
		end

		function ENT:Think()
			if next(self.Crates) then
				local Pos = self:GetPos()

				for Crate in pairs(self.Crates) do
					if Crate:GetPos():DistToSqr(Pos) > MaxDistance then
						local Sound = UnlinkSound:format(math.random(1, 3))

						Sounds.SendSound(Crate, Sound, 70, 100, 1)
						Sounds.SendSound(self, Sound, 70, 100, 1)

						self:Unlink(Crate)
					end
				end
			end

			self:NextThink(Clock.CurTime + 1)

			return true
		end

		function ENT:Enable()
			self:UpdateOverlay()
		end

		function ENT:Disable()
			self.Firing   = false -- Stop firing

			self:Unload() -- Unload the gun for being a big baddie
			self:UpdateOverlay()
		end

		function ENT:CanProperty(_, Property)
			if self.Long and Property == "bodygroups" then
				timer.Simple(0, function()
					if not IsValid(self) then return end

					local Long = self.Long
					local IsLong = self:GetBodygroup(Long.Index) == Long.Submodel

					self.Muzzle = IsLong and self.LongMuzzle or self.NormalMuzzle
				end)
			end

			return true
		end

		function ENT:OnRemove()
			local Class = self.ClassData

			if Class.OnLast then
				Class.OnLast(self, Class)
			end

			HookRun("ACF_OnEntityLast", "acf_gun", self, Class)

			for Crate in pairs(self.Crates) do
				self:Unlink(Crate)
			end

			timer.Remove("ACF Ammo Left " .. self:EntIndex())

			WireLib.Remove(self)
		end
	end -----------------------------------------
end
