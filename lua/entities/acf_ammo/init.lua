AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("ACF_RefillEffect")
util.AddNetworkString("ACF_StopRefillEffect")

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local CheckLegal  = ACF_CheckLegal
local ClassLink	  = ACF.GetClassLink
local ClassUnlink = ACF.GetClassUnlink
local TimerCreate = timer.Create
local TimerExists = timer.Exists

local function Overlay(Ent)
	local Tracer = Ent.BulletData.Tracer ~= 0 and "-T" or ""
	local Text = "%s\n\nRound type: %s\nRounds remaining: %s / %s"
	local Status

	if Ent.DisableReason then
		Status = "Disabled: " .. Ent.DisableReason
	elseif next(Ent.Weapons) then
		Status = Ent.Load and "Providing Ammo" or (Ent.Ammo ~= 0 and "Idle" or "Empty")
	else
		Status = "Not linked to a weapon!"
	end

	Ent:SetOverlayText(string.format(Text, Status, Ent.BulletData.Type .. Tracer, Ent.Ammo, Ent.Capacity))
end

local function UpdateAmmoData(Entity, Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, Data9, Data10)
	local GunData = ACF.Weapons.Guns[Data1]

	if not GunData then
		Entity:Remove()
		return
	end

	local GunClass = ACF.Classes.GunClass[GunData.gunclass]

	--Data 1 to 4 are should always be Round ID, Round Type, Propellant lenght, Projectile lenght
	Entity.RoundId = Data1 --Weapon this round loads into, ie 140mmC, 105mmH ...
	Entity.RoundType = Data2 --Type of round, IE AP, HE, HEAT ...
	Entity.RoundPropellant = Data3 --Lenght of propellant
	Entity.RoundProjectile = Data4 --Lenght of the projectile
	Entity.RoundData5 = Data5 or 0
	Entity.RoundData6 = Data6 or 0
	Entity.RoundData7 = Data7 or 0
	Entity.RoundData8 = Data8 or 0
	Entity.RoundData9 = Data9 or 0
	Entity.RoundData10 = Data10 or 0

	Entity.Name = Data1 .. " " .. Data2
	Entity.ShortName = Data1
	Entity.EntType = Data2

	local PlayerData = {
		Id = Entity.RoundId,
		Type = Entity.RoundType,
		PropLength = Entity.RoundPropellant,
		ProjLength = Entity.RoundProjectile,
		Data5 = Entity.RoundData5,
		Data6 = Entity.RoundData6,
		Data7 = Entity.RoundData7,
		Data8 = Entity.RoundData8,
		Data9 = Entity.RoundData9,
		Data10 = Entity.RoundData10
	}

	Entity.BulletData = ACF.RoundTypes[Entity.RoundType].convert(Entity, PlayerData)
	Entity.BulletData.Crate = Entity:EntIndex()

	Entity.SupplyingTo = {}

	local Efficiency = 0.1576 * ACF.AmmoMod
	local Volume = math.floor(Entity:GetPhysicsObject():GetVolume())
	local CapMul = (Volume > 40250) and ((math.log(Volume * 0.00066) / math.log(2) - 4) * 0.15 + 1) or 1
	local MassMod = Entity.BulletData.MassMod or 1

	Entity.Volume = Volume * Efficiency
	Entity.Capacity = math.floor(CapMul * Entity.Volume * 16.38 / Entity.BulletData.RoundVolume)
	Entity.AmmoMassMax = math.floor((Entity.BulletData.ProjMass * MassMod + Entity.BulletData.PropMass) * Entity.Capacity * 2) -- why *2 ?
	Entity.Caliber = GunData.caliber
	Entity.RoFMul = (Volume > 27000) and (1 - (math.log(Volume * 0.00066) / math.log(2) - 4) * 0.2) or 1 --*0.0625 for 25% @ 4x8x8, 0.025 10%, 0.0375 15%, 0.05 20% --0.23 karb edit for cannon rof 2. changed to start from 2x3x4 instead of 2x4x4
	Entity.Spread = GunClass.spread * ACF.GunInaccuracyScale

	Entity:SetNWString("WireName", GunData.name .. " Ammo")

	ACF.RoundTypes[Entity.RoundType].network(Entity, Entity.BulletData)

	Entity:UpdateOverlay()
end

local function RefillEffect(Entity, Target)
	net.Start("ACF_RefillEffect")
		net.WriteFloat(Entity:EntIndex())
		net.WriteFloat(Target:EntIndex())
		net.WriteString(Target.RoundType)
	net.Broadcast()
end

local function StopRefillEffect(Entity, TargetID)
	net.Start("ACF_StopRefillEffect")
		net.WriteFloat(Entity:EntIndex())
		net.WriteFloat(TargetID)
	net.Broadcast()
end

--===============================================================================================--

function MakeACF_Ammo(Player, Pos, Ang, Id, ...)
	if not Player:CheckLimit("_acf_ammo") then return end

	local CrateData = ACF.Weapons.Ammo[Id]

	if not CrateData then return end

	local Crate = ents.Create("acf_ammo")

	if not IsValid(Crate) then return end

	Player:AddCount("_acf_ammo", Crate)
	Player:AddCleanup("acfmenu", Crate)

	Crate:SetPos(Pos)
	Crate:SetAngles(Ang)
	Crate:SetPlayer(Player)
	Crate:SetModel(CrateData.model)
	Crate:Spawn()

	Crate:PhysicsInit(SOLID_VPHYSICS)
	Crate:SetMoveType(MOVETYPE_VPHYSICS)

	UpdateAmmoData(Crate, ...)

	Crate.IsExplosive   = true
	Crate.Ammo			= Crate.Capacity
	Crate.EmptyMass		= math.floor(CrateData.weight)
	Crate.Id			= Id
	Crate.Owner			= Player
	Crate.Size			= Size
	Crate.Weapons		= {}
	Crate.Load			= true -- Crates should be ready to load by default
	Crate.Inputs		= WireLib.CreateInputs(Crate, { "Load", "Output [VECTOR]"})
	Crate.Outputs		= WireLib.CreateOutputs(Crate, { "Entity [ENTITY]", "Ammo", "Loading", "On Fire" })
	Crate.CanUpdate		= true
	Crate.HitBoxes 		= {
				Main = {
					Pos = Crate:OBBCenter(),
					Scale = (Crate:OBBMaxs() - Crate:OBBMins()) - Vector(0.5, 0.5, 0.5),
				}
			}

	WireLib.TriggerOutput(Crate, "Entity", Crate)
	WireLib.TriggerOutput(Crate, "Ammo", Crate.Ammo)

	ACF.AmmoCrates[Crate] = true

	local Mass = Crate.EmptyMass + Crate.AmmoMassMax
	local Phys = Crate:GetPhysicsObject()
	if IsValid(Phys) then
		Phys:SetMass(Mass)
	end

	ACF_Activate(Crate) -- Makes Crate.ACF table

	Crate.ACF.Model 	= ACF.Weapons.Ammo[Id].model
	Crate.ACF.LegalMass = math.floor(Mass)

	CheckLegal(Crate)
	Crate:UpdateOverlay(true)

	return Crate
end

list.Set("ACFCvars", "acf_ammo", {"id", "data1", "data2", "data3", "data4", "data5", "data6", "data7", "data8", "data9", "data10"})
duplicator.RegisterEntityClass("acf_ammo", MakeACF_Ammo, "Pos", "Angle", "Id", "RoundId", "RoundType", "RoundPropellant", "RoundProjectile", "RoundData5", "RoundData6", "RoundData7", "RoundData8", "RoundData9", "RoundData10")
ACF.RegisterLinkSource("acf_ammo", "Weapons")

--===============================================================================================--
-- Meta Funcs
--===============================================================================================--

function ENT:ACF_Activate(Recalc)
	local PhysObj   = self.ACF.PhysObj
	local EmptyMass = math.max(self.EmptyMass, PhysObj:GetMass() - self.AmmoMassMax)

	if not self.ACF.Area then
		self.ACF.Area = PhysObj:GetSurfaceArea() * 6.45
	end

	if not self.ACF.Volume then
		self.ACF.Volume = PhysObj:GetVolume() * 16.38
	end

	local Armour = EmptyMass * 1000 / self.ACF.Area / 0.78 --So we get the equivalent thickness of that prop in mm if all it's weight was a steel plate
	local Health = self.ACF.Volume / ACF.Threshold --Setting the threshold of the prop Area gone 
	local Percent = 1

	if Recalc and self.ACF.Health and self.ACF.MaxHealth then
		Percent = self.ACF.Health / self.ACF.MaxHealth
	end

	self.ACF.Health = Health * Percent
	self.ACF.MaxHealth = Health
	self.ACF.Armour = Armour * (0.5 + Percent / 2)
	self.ACF.MaxArmour = Armour
	self.ACF.Type = nil
	self.ACF.Mass = self.Mass
	self.ACF.Density = (PhysObj:GetMass() * 1000) / self.ACF.Volume
	self.ACF.Type = "Prop"
end

function ENT:ACF_OnDamage(Entity, Energy, FrArea, Angle, Inflictor, _, Type)
	local Mul = (Type == "HEAT" and ACF.HEATMulAmmo) or 1 --Heat penetrators deal bonus damage to ammo
	local HitRes = ACF_PropDamage(Entity, Energy, FrArea * Mul, Angle, Inflictor) --Calling the standard damage prop function

	if self.Exploding or not self.IsExplosive then return HitRes end

	if HitRes.Kill then
		if hook.Run("ACF_AmmoExplode", self, self.BulletData) == false then return HitRes end

		self.Exploding = true

		if IsValid(Inflictor) and Inflictor:IsPlayer() then
			self.Inflictor = Inflictor
		end

		if self.Ammo > 1 then
			ACF_ScaledExplosion(self)
		else
			ACF_HEKill(self, VectorRand())
		end
	end

	-- cookoff chance calculation
	if self.Damaged then return HitRes end

	local Ratio = (HitRes.Damage / self.BulletData.RoundVolume) ^ 0.2

	if (Ratio * self.Capacity / self.Ammo) > math.Rand(0, 1) then
		self.Inflictor = Inflictor
		self.Damaged = CurTime() + (5 - Ratio * 3)

		WireLib.TriggerOutput(self, "On Fire", 1)
	end

	return HitRes
end

function ENT:Enable()
	if not CheckLegal(self) then return end

	self.Disabled	   = nil
	self.DisableReason = nil

	if self.Inputs.Load.Path then
		self.Load = tobool(self.Inputs.Load.Value)
	else
		self.Load = true
	end

	self:UpdateOverlay(true)
	self:UpdateMass()
end

function ENT:Disable()
	self.Disabled = true
	self.Load     = false

	self:UpdateOverlay(true)
	self:UpdateMass()
end

function ENT:Update(ArgsTable)
	-- That table is the player data, as sorted in the ACFCvars above, with player who shot, 
	-- and pos and angle of the tool trace inserted at the start
	local Message = "Ammo crate updated successfully!"

	if ArgsTable[1] ~= self.Owner then return false, "You don't own that ammo crate!" end -- Argtable[1] is the player that shot the tool
	if ArgsTable[6] == "Refill" then return false, "Refill ammo type is only avaliable for new crates!" end -- Argtable[6] is the round type. If it's refill it shouldn't be loaded into guns, so we refuse to change to it

	-- Argtable[5] is the weapon ID the new ammo loads into
	if ArgsTable[5] ~= self.RoundId then
		for Gun in pairs(self.Weapons) do
			self:Unlink(Gun)
		end

		Message = "New ammo type loaded, crate unlinked."
	else -- ammotype wasn't changed, but let's check if new roundtype is blacklisted
		local Blacklist = ACF.AmmoBlacklist[ArgsTable[6]]

		for Gun in pairs(self.Weapons) do
			if table.HasValue(Blacklist, Gun.Class) then
				self:Unlink(Gun)
				Message = "New round type cannot be used with linked gun, crate unlinked."
			end
		end
	end

	local AmmoPercent = self.Ammo / math.max(self.Capacity, 1)

	UpdateAmmoData(self, unpack(ArgsTable, 5, 14))

	self.Ammo = math.floor(self.Capacity * AmmoPercent)

	self:UpdateMass()

	return true, Message
end

function ENT:TriggerInput(Name, Value)
	if self.Disabled then return end -- Ignore input if disabled

	if not self.Inputs.Load.Path then -- If unwired turn on loading
		self.Load = self.Ammo ~= 0
		WireLib.TriggerOutput(self, "Loading", self.Load and 1 or 0)
	end


	if Name == "Output" then
		if not self.Inputs.Output.Path then -- Reset output of unwired
			self.Output = nil

			return
		end

		Value = self:WorldToLocal(Value)

		local Mins, Maxs = self:OBBMins(), self:OBBMaxs()
		local X = math.Clamp(Value[1], Mins[1], Maxs[1])
		local Y = math.Clamp(Value[2], Mins[2], Maxs[2])
		local Z = math.Clamp(Value[3], Mins[3], Maxs[3])

		self.Output = Vector(X, Y, Z)

	elseif Name == "Load" then
		self.Load = self.Ammo ~= 0 and tobool(Value)
		WireLib.TriggerOutput(self, "Loading", self.Load and 1 or 0)
	end


	self:UpdateOverlay()
end

function ENT:Link(Target)
	if not IsValid(Target) then return false, "Attempted to link an invalid entity." end
	if self == Target then return false, "Can't link a crate to itself." end

	local Function = ClassLink(self:GetClass(), Target:GetClass())

	if Function then
		return Function(self, Target)
	end

	return false, "Crates can't be linked to '" .. Target:GetClass() .. "'."
end

function ENT:Unlink(Target)
	if not IsValid(Target) then return false, "Attempted to unlink an invalid entity." end
	if self == Target then return false, "Can't unlink a crate from itself." end

	local Function = ClassUnlink(self:GetClass(), Target:GetClass())

	if Function then
		return Function(self, Target)
	end

	return false, "Crates can't be unlinked from '" .. Target:GetClass() .. "'."
end

function ENT:Think()
	if self.TracerColor ~= self:GetColor() then
		local Color = self:GetColor()

		self.TracerColor = Color
		self:SetNWVector("TracerColour", Vector(Color.r, Color.g, Color.b))
	end

	self:NextThink(CurTime() + 1)

	if self.Damaged then
		if self.Ammo <= 1 or self.Damaged < CurTime() then -- immediately detonate if there's 1 or 0 shells
			ACF_ScaledExplosion(self) -- going to let empty crates harmlessly poot still, as an audio cue it died
		elseif self.BulletData.Type ~= "Refill"  and ACF.RoundTypes[self.BulletData.Type] then
			local VolumeRoll = math.Rand(0, 150) > self.BulletData.RoundVolume ^ 0.5
			local AmmoRoll = math.Rand(0, 1) < self.Ammo / math.max(self.Capacity, 1)

			if VolumeRoll and AmmoRoll then
				local Speed = ACF_MuzzleVelocity( self.BulletData.PropMass, self.BulletData.ProjMass / 2, self.Caliber )

				self:EmitSound("ambient/explosions/explode_4.wav", 350, math.max(255 - self.BulletData.PropMass * 100,60))

				self.BulletData.Pos = self:LocalToWorld(self:OBBCenter() + VectorRand() * (self:OBBMaxs() - self:OBBMins()) / 2)
				self.BulletData.Flight = (VectorRand()):GetNormalized() * Speed * 39.37 + self:GetVelocity()
				self.BulletData.Owner = self.Inflictor or self.Owner
				self.BulletData.Gun = self
				self.BulletData.Crate = self:EntIndex()
				self.CreateShell = ACF.RoundTypes[self.BulletData.Type].create(self, self.BulletData)

				self:Consume()
			end
		end

		self:NextThink(CurTime() + 0.01 + self.BulletData.RoundVolume ^ 0.5 / 100)

	elseif self.RoundType == "Refill" and self.Load and self.Ammo > 0 then
		local MaxDist = ACF.RefillDistance * ACF.RefillDistance
		local SelfPos = self:GetPos()

		for Crate in pairs(ACF.AmmoCrates) do
			if self ~= Crate and Crate.RoundType ~= "Refill" and Crate.Ammo < Crate.Capacity then
				local Distance = SelfPos:DistToSqr(Crate:GetPos())

				if Distance <= MaxDist then
					local Supply = math.ceil((50000 / ((Crate.BulletData.ProjMass + Crate.BulletData.PropMass) * 1000)) / Distance ^ 0.5)
					local Transfer = math.min(Supply, Crate.Capacity - Crate.Ammo)

					if not self.SupplyingTo[Crate] then
						self.SupplyingTo[Crate] = Crate:EntIndex()

						RefillEffect(self, Crate)
					end

					Crate.Ammo = Crate.Ammo + Transfer
					self.Ammo = self.Ammo - Transfer

					if not Crate.Load then
						Crate:TriggerInput("Load", Crate.Inputs.Load.Value or 1)
					end

					Crate.Supplied = true
					Crate:EmitSound("items/ammo_pickup.wav", 350, 80, 0.30)

					Crate:UpdateMass()
					Crate:UpdateOverlay()
				end
			end
		end

		self:UpdateMass()
		self:UpdateOverlay()
	end

	-- checks to stop supply
	if self.SupplyingTo then
		local MaxDist = ACF.RefillDistance * ACF.RefillDistance
		local SelfPos = self:GetPos()

		for Crate, EntID in pairs(self.SupplyingTo) do
			if not IsValid(Crate) then
				self.SupplyingTo[Crate] = nil

				StopRefillEffect(self, EntID)
			else
				local Distance = SelfPos:DistToSqr(Crate:GetPos())

				if self.Damaged or not self.Load or Distance > MaxDist or Crate.Ammo >= Crate.Capacity then
					self.SupplyingTo[Crate] = nil

					StopRefillEffect(self, EntID)
				end
			end
		end
	end

	return true
end

function ENT:Consume()
	self.Ammo = self.Ammo - 1

	self:UpdateOverlay()
	self:UpdateMass()

	if self.Ammo == 0 then
		self.Load = false
	end

	WireLib.TriggerOutput(self, "Ammo", self.Ammo)
end

function ENT:UpdateOverlay(Instant)
	if Instant then
		Overlay(self)
		return
	end

	if not TimerExists("ACF Overlay Buffer" .. self:EntIndex()) then
		TimerCreate("ACF Overlay Buffer" .. self:EntIndex(), 1, 1, function()
			if IsValid(self) then
				Overlay(self)
			end
		end)
	end
end

function ENT:UpdateMass()
	if TimerExists("ACF Mass Buffer" .. self:EntIndex()) then return end

	TimerCreate("ACF Mass Buffer" .. self:EntIndex(), 5, 1, function()
		if IsValid(self) then
			self.ACF.LegalMass = math.floor(self.EmptyMass + self.AmmoMassMax * (self.Ammo / math.max(self.Capacity, 1)))

			local Phys = self:GetPhysicsObject()

			if IsValid(Phys) then
				Phys:SetMass(self.ACF.LegalMass)
			end
		end
	end)
end

function ENT:OnRemove()
	for K in pairs(self.Weapons) do
		self:Unlink(K)
	end

	ACF.AmmoCrates[self] = nil

	WireLib.Remove(self)
end
