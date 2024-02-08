AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF       = ACF
local Contraption	= ACF.Contraption
local Utilities = ACF.Utilities
local Clock     = Utilities.Clock
local hook      = hook

do -- Spawning and Updating --------------------
	local Classes     = ACF.Classes
	local WireIO      = Utilities.WireIO
	local Piledrivers = Classes.Piledrivers
	local AmmoTypes   = Classes.AmmoTypes
	local Entities    = Classes.Entities

	local Inputs = {
		"Fire (Attempts to fire the piledriver.)",
	}
	local Outputs = {
		"Ready (Returns 1 if the piledriver can be fired.)",
		"Status (Returns the current state of the piledriver.) [STRING]",
		"Shots Left (Returns the amount of charges available to fire.)",
		"Reload Time (Returns the charge rate of the piledriver.)",
		"Rate of Fire (Returns how many charges per minute can be fired.)",
		"Spike Mass (Returns the mass in grams of the piledriver's spike.)",
		"Muzzle Velocity (Returns the speed in m/s at which the spike is fired.)",
		"Entity (The piledriver itself.) [ENTITY]",
	}

	local function VerifyData(Data)
		local OldClass = Classes.GetGroup(Piledrivers, Data.Id)

		if OldClass then
			Data.Weapon = OldClass.ID
			Data.Caliber = Piledriver.GetItem(OldClass.ID, Data.Id).Caliber
		end

		local Weapon = Classes.GetGroup(Piledrivers, Data.Weapon)

		Data.Weapon  = Weapon and Weapon.ID or "PD"
		Data.Destiny = "Piledrivers"

		local Class  = Piledrivers.Get(Data.Weapon)
		local Bounds = Class.Caliber

		if not isnumber(Data.Caliber) then
			Data.Caliber = Bounds.Base
		else
			Data.Caliber = math.Clamp(math.Round(Data.Caliber, 2), Bounds.Min, Bounds.Max)
		end

		do -- External verifications
			if Class.VerifyData then
				Class.VerifyData(Data, Class)
			end

			hook.Run("ACF_VerifyData", "acf_piledriver", Data, Class)
		end
	end

	local function UpdatePiledriver(Entity, Data, Class)
		local Caliber = Data.Caliber
		local Scale   = Caliber / Class.Caliber.Base
		local Mass    = math.floor(Class.Mass * Scale)

		Entity.ACF.Model = Class.Model -- Must be set before changing model

		Entity:SetScaledModel(Class.Model)
		Entity:SetScale(Scale)

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name        = Caliber .. "mm " .. Class.Name
		Entity.ShortName   = Caliber .. "mm" .. Class.ID
		Entity.EntType     = Class.Name
		Entity.ClassData   = Class
		Entity.Caliber     = Caliber
		Entity.Cyclic      = 60 / Class.Cyclic
		Entity.MagSize     = Class.MagSize or 1
		Entity.ChargeRate  = Class.ChargeRate or 0.1
		Entity.SpikeLength = Class.Round.MaxLength * Scale
		Entity.Muzzle      = Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("muzzle")).Pos)

		WireIO.SetupInputs(Entity, Inputs, Data, Class)
		WireIO.SetupOutputs(Entity, Outputs, Data, Class)

		WireLib.TriggerOutput(Entity, "Reload Time", Entity.Cyclic)
		WireLib.TriggerOutput(Entity, "Rate of Fire", 60 / Entity.Cyclic)

		do -- Updating bulletdata
			local Ammo = Entity.RoundData

			Data.AmmoType   = "HP"
			Data.Projectile = Entity.SpikeLength

			Ammo.SpikeLength = Entity.SpikeLength

			local BulletData  = Ammo:ServerConvert(Data)
			BulletData.Crate  = Entity:EntIndex()
			BulletData.Filter = { Entity }
			BulletData.Gun    = Entity
			BulletData.Hide   = true

			-- Bullet dies on the next tick
			function BulletData:PreCalcFlight()
				if self.KillTime then return end
				if not self.DeltaTime then return end
				if self.LastThink == Clock.CurTime then return end

				self.KillTime = Clock.CurTime
			end

			function BulletData:OnEndFlight(Trace)
				if not ACF.RecoilPush then return end
				if not IsValid(Entity) then return end
				if not Trace.HitWorld then return end
				if Trace.Fraction == 0 then return end

				local Fraction   = 1 - Trace.Fraction
				local MassCenter = Entity:LocalToWorld(Entity:GetPhysicsObject():GetMassCenter())
				local Energy     = self.ProjMass * self.MuzzleVel * 39.37 * Fraction

				ACF.KEShove(Entity, MassCenter, -Entity:GetForward(), Energy)
			end

			Entity.BulletData = BulletData

			if Ammo.OnFirst then
				Ammo:OnFirst(Entity)
			end

			hook.Run("ACF_OnAmmoFirst", Ammo, Entity, Data, Class)

			Ammo:Network(Entity, Entity.BulletData)

			WireLib.TriggerOutput(Entity, "Spike Mass", math.Round(BulletData.ProjMass * 1000, 2))
			WireLib.TriggerOutput(Entity, "Muzzle Velocity", math.Round(BulletData.MuzzleVel * ACF.Scale, 2))
		end

		-- Set NWvars
		Entity:SetNWString("WireName", "ACF " .. Entity.Name)

		ACF.Activate(Entity, true)

		Contraption.SetMass(Entity, Mass)
	end

	-------------------------------------------------------------------------------

	function MakeACF_Piledriver(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class = Piledrivers.Get(Data.Weapon)
		local Limit = Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return end

		local Entity = ents.Create("acf_piledriver")

		if not IsValid(Entity) then return end

		local AmmoType = AmmoTypes.Get("HP")

		Player:AddCleanup(Class.Cleanup, Entity)
		Player:AddCount(Limit, Entity)

		Entity.ACF          = {}

		Contraption.SetModel(Entity, Class.Model)

		Entity:SetPlayer(Player)
		Entity:SetAngles(Angle)
		Entity:SetPos(Pos)
		Entity:Spawn()

		Entity.Owner        = Player -- MUST be stored on ent for PP
		Entity.RoundData    = AmmoType()
		Entity.LastThink    = Clock.CurTime
		Entity.State        = "Loading"
		Entity.Firing       = false
		Entity.Charge       = 0
		Entity.SingleCharge = 0
		Entity.CurrentShot  = 0
		Entity.DataStore    = Entities.GetArguments("acf_piledriver")

		UpdatePiledriver(Entity, Data, Class)

		WireLib.TriggerOutput(Entity, "State", "Loading")
		WireLib.TriggerOutput(Entity, "Entity", Entity)

		Entity:UpdateOverlay(true)

		ACF.CheckLegal(Entity)

		return Entity
	end

	Entities.Register("acf_piledriver", MakeACF_Piledriver, "Weapon", "Caliber")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		VerifyData(Data)

		local Class    = Piledrivers.Get(Data.Weapon)
		local OldClass = self.ClassData

		local CanUpdate, Reason = hook.Run("ACF_PreEntityUpdate", "acf_piledriver", self, Data, Class)
		if CanUpdate == false then return CanUpdate, Reason end

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		hook.Run("ACF_OnEntityLast", "acf_piledriver", self, OldClass)

		ACF.SaveEntity(self)

		UpdatePiledriver(self, Data, Class)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class)
		end

		hook.Run("ACF_OnEntityUpdate", "acf_piledriver", self, Data, Class)

		self:UpdateOverlay(true)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		return true, "Piledriver updated successfully!"
	end
end --------------------------------------------

do -- Entity Activation ------------------------
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
		self.ACF.Ductility = 0
	end
end --------------------------------------------

do -- Entity Inputs ----------------------------
	ACF.AddInputAction("acf_piledriver", "Fire", function(Entity, Value)
		Entity.Firing = tobool(Value)

		Entity:Shoot()
	end)
end ---------------------------------------------

do -- Entity Overlay ----------------------------
	local Text  = "%s\n\nCharges Left:\n%s / %s\n[%s]\n\nRecharge State:\n%s%%\n[%s]\n\nRecharge Rate: %s charges/s\nRate of Fire: %s rpm\n\nMax Penetration: %s mm\nSpike Velocity: %s m/s\nSpike Length: %s cm\nSpike Mass: %s"
	local Empty = "▯"
	local Full  = "▮"

	local function GetChargeBar(Percentage)
		local Bar = ""

		for I = 0.05, 0.95, 0.1 do
			Bar = Bar .. (I <= Percentage and Full or Empty)
		end

		return Bar
	end

	-------------------------------------------------------------------------------

	ENT.OverlayDelay = 0.1

	function ENT:UpdateOverlayText()
		local Shots   = GetChargeBar(self.Charge / self.MagSize)
		local State   = GetChargeBar(self.SingleCharge)
		local Current = self.CurrentShot
		local Total   = self.MagSize
		local Percent = math.floor(self.SingleCharge * 100)
		local Rate    = self.ChargeRate
		local RoF     = self.Cyclic * 60
		local Bullet  = self.BulletData
		local Display = self.RoundData:GetDisplayData(Bullet)
		local MaxPen  = math.Round(Display.MaxPen, 2)
		local Mass    = ACF.GetProperMass(Bullet.ProjMass)
		local MuzVel  = math.Round(Bullet.MuzzleVel, 2)
		local Length  = Bullet.ProjLength

		return Text:format(self.State, Current, Total, Shots, Percent, State, Rate, RoF, MaxPen, MuzVel, Length, Mass)
	end
end ---------------------------------------------

do -- Firing ------------------------------------
	local Sounds = ACF.Utilities.Sounds
	local Impact = "physics/metal/metal_barrel_impact_hard%s.wav"

	-- The entity won't even attempt to shoot if this function returns false
	function ENT:AllowShoot()
		if self.Disabled then return false end
		if self.RetryShoot then return false end

		return self.Firing
	end

	-- The entity should produce a "click" sound if this function returns false
	function ENT:CanShoot()
		if not ACF.GunsCanFire then return false end
		if not ACF.AllowFunEnts then return false end
		if hook.Run("ACF_FireShell", self) == false then return false end

		return self.CurrentShot > 0
	end

	function ENT:Shoot()
		if not self:AllowShoot() then return end

		local Delay = self.Cyclic

		if self:CanShoot() then
			local Sound  = self.SoundPath or Impact:format(math.random(5, 6))
			local Bullet = self.BulletData

			if Sound ~= "" then
				Sounds.SendSound(self, Sound, 70, math.Rand(98, 102), 1)
			end
			self:SetSequence("load")

			Bullet.Owner  = self:GetUser(self.Inputs.Fire.Src) -- Must be updated on every shot
			Bullet.Pos    = self:LocalToWorld(self.Muzzle)
			Bullet.Flight = self:GetForward() * Bullet.MuzzleVel * 39.37

			self.RoundData:Create(self, Bullet)

			self:Consume()
			self:SetState("Loading")

			self.Loading = true

			timer.Simple(0.35, function()
				if not IsValid(self) then return end

				self:SetSequence("idle")
			end)
		else
			Sounds.SendSound(self, "weapons/pistol/pistol_empty.wav", 70, math.Rand(98, 102), 1)

			Delay = 1
		end

		if not self.RetryShoot then
			self.RetryShoot = true

			timer.Simple(Delay, function()
				if not IsValid(self) then return end

				self.RetryShoot = nil

				if self.Loading then
					self.Loading = nil

					if self.CurrentShot > 0 then
						self:SetState("Loaded")
					end
				end

				self:Shoot()
			end)
		end
	end
end ---------------------------------------------

do -- Misc --------------------------------------
	function ENT:Disable()
		self.Charge       = 0
		self.SingleCharge = 0
		self.CurrentShot  = 0

		self:SetState("Loading")
	end

	function ENT:SetState(State)
		self.State = State

		self:UpdateOverlay()

		WireLib.TriggerOutput(self, "Status", State)
		WireLib.TriggerOutput(self, "Ready", State == "Loaded" and 1 or 0)
	end

	function ENT:Consume(Num)
		self.Charge      = math.Clamp(self.Charge - (Num or 1), 0, self.MagSize)
		self.CurrentShot = math.floor(self.Charge)

		WireLib.TriggerOutput(self, "Shots Left", self.CurrentShot)

		self:UpdateOverlay()
	end

	function ENT:Think()
		local Time = Clock.CurTime

		if not self.Disabled and self.CurrentShot < self.MagSize then
			local Delta  = Time - self.LastThink
			local Amount = self.ChargeRate * Delta

			self:Consume(-Amount) -- Slowly recharging the piledriver

			self.SingleCharge = self.Charge - self.CurrentShot

			if not self.Loading and self.State == "Loading" and self.CurrentShot > 0 then
				self:SetState("Loaded")
			end
		end

		self:NextThink(Time)

		self.LastThink = Time

		return true
	end

	function ENT:OnRemove()
		local Class = self.ClassData

		if Class.OnLast then
			Class.OnLast(self, Class)
		end

		hook.Run("ACF_OnEntityLast", "acf_piledriver", self, Class)

		WireLib.Remove(self)
	end
end ---------------------------------------------
