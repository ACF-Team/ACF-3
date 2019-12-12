AddCSLuaFile("cl_init.lua")

DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName     = "ACF Ammo Crate"
ENT.WireDebugName = "ACF Ammo Crate"

util.AddNetworkString("ACF_RefillEffect")
util.AddNetworkString("ACF_StopRefillEffect")

function ENT:Initialize()
	self.SpecialHealth = true --If true needs a special ACF_Activate function
	self.SpecialDamage = true --If true needs a special ACF_OnDamage function
	self.IsExplosive = true
	self.Exploding = false
	self.Damaged = false
	self.CanUpdate = true
	self.Load = false
	self.EmptyMass = 0
	self.AmmoMassMax = 0
	self.NextMassUpdate = 0
	self.Ammo = 0
	self.NextLegalCheck = ACF.CurTime + 30 -- give any spawning issues time to iron themselves out
	self.Legal = true
	self.LegalIssues = ""
	self.Master = {}
	self.Sequence = 0
	self.Inputs = Wire_CreateInputs(self, {"Active"}) --, "Fuse Length"
	self.Outputs = Wire_CreateOutputs(self, {"Munitions", "On Fire"})
	self.NextThink = CurTime() + 1
	ACF.AmmoCrates = ACF.AmmoCrates or {}
end

function ENT:ACF_Activate(Recalc)
	local EmptyMass = math.max(self.EmptyMass, self:GetPhysicsObject():GetMass() - self.AmmoMassMax)
	self.ACF = self.ACF or {}
	local PhysObj = self:GetPhysicsObject()

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
	self.ACF.Density = (self:GetPhysicsObject():GetMass() * 1000) / self.ACF.Volume
	self.ACF.Type = "Prop"
end

--This function needs to return HitRes
function ENT:ACF_OnDamage(Entity, Energy, FrArea, Angle, Inflictor, Bone, Type)
	local Mul = ((Type == "HEAT" and ACF.HEATMulAmmo) or 1) --Heat penetrators deal bonus damage to ammo
	local HitRes = ACF_PropDamage(Entity, Energy, FrArea * Mul, Angle, Inflictor) --Calling the standard damage prop function
	if self.Exploding or not self.IsExplosive then return HitRes end

	if HitRes.Kill then
		if hook.Run("ACF_AmmoExplode", self, self.BulletData) == false then return HitRes end
		self.Exploding = true

		if (Inflictor and Inflictor:IsValid() and Inflictor:IsPlayer()) then
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
		Wire_TriggerOutput(self, "On Fire", 1)
	end
	--This function needs to return HitRes

	return HitRes
end

function MakeACF_Ammo(Owner, Pos, Angle, Id, Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, Data9, Data10)
	if not Owner:CheckLimit("_acf_ammo") then return false end
	local Ammo = ents.Create("acf_ammo")
	if not Ammo:IsValid() then return false end
	Ammo:SetAngles(Angle)
	Ammo:SetPos(Pos)
	Ammo:Spawn()
	Ammo:SetPlayer(Owner)
	Ammo.Owner = Owner
	Ammo.Model = ACF.Weapons.Ammo[Id].model
	Ammo:SetModel(Ammo.Model)
	Ammo:PhysicsInit(SOLID_VPHYSICS)
	Ammo:SetMoveType(MOVETYPE_VPHYSICS)
	Ammo:SetSolid(SOLID_VPHYSICS)
	Ammo.Id = Id
	Ammo:CreateAmmo(Id, Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, Data9, Data10)
	Ammo.Ammo = Ammo.Capacity
	Ammo.EmptyMass = ACF.Weapons.Ammo[Ammo.Id].weight
	Ammo.Mass = Ammo.EmptyMass + Ammo.AmmoMassMax
	Ammo.LastMass = 1
	Ammo:UpdateMass()
	Owner:AddCount("_acf_ammo", Ammo)
	Owner:AddCleanup("acfmenu", Ammo)
	table.insert(ACF.AmmoCrates, Ammo)

	return Ammo
end

list.Set("ACFCvars", "acf_ammo", {"id", "data1", "data2", "data3", "data4", "data5", "data6", "data7", "data8", "data9", "data10"})
duplicator.RegisterEntityClass("acf_ammo", MakeACF_Ammo, "Pos", "Angle", "Id", "RoundId", "RoundType", "RoundPropellant", "RoundProjectile", "RoundData5", "RoundData6", "RoundData7", "RoundData8", "RoundData9", "RoundData10")

function ENT:Update(ArgsTable)
	-- That table is the player data, as sorted in the ACFCvars above, with player who shot, 
	-- and pos and angle of the tool trace inserted at the start
	local msg = "Ammo crate updated successfully!"
	if ArgsTable[1] ~= self.Owner then return false, "You don't own that ammo crate!" end -- Argtable[1] is the player that shot the tool
	if ArgsTable[6] == "Refill" then return false, "Refill ammo type is only avaliable for new crates!" end -- Argtable[6] is the round type. If it's refill it shouldn't be loaded into guns, so we refuse to change to it

	-- Argtable[5] is the weapon ID the new ammo loads into
	if ArgsTable[5] ~= self.RoundId then
		for Key, Gun in pairs(self.Master) do
			if IsValid(Gun) then
				Gun:Unlink(self)
			end
		end

		msg = "New ammo type loaded, crate unlinked."
	else -- ammotype wasn't changed, but let's check if new roundtype is blacklisted
		local Blacklist = ACF.AmmoBlacklist[ArgsTable[6]] or {}

		for Key, Gun in pairs(self.Master) do
			if IsValid(Gun) and table.HasValue(Blacklist, Gun.Class) then
				Gun:Unlink(self)
				msg = "New round type cannot be used with linked gun, crate unlinked."
			end
		end
	end

	local AmmoPercent = self.Ammo / math.max(self.Capacity, 1)
	self:CreateAmmo(ArgsTable[4], ArgsTable[5], ArgsTable[6], ArgsTable[7], ArgsTable[8], ArgsTable[9], ArgsTable[10], ArgsTable[11], ArgsTable[12], ArgsTable[13], ArgsTable[14])
	self.Ammo = math.floor(self.Capacity * AmmoPercent)
	self.LastMass = 1 -- force update of mass
	self:UpdateMass()

	return true, msg
end

function ENT:UpdateOverlayText()
	local roundType = self.RoundType

	if self.BulletData.Tracer and self.BulletData.Tracer > 0 then
		roundType = roundType .. "-T"
	end

	local text = roundType .. " - " .. self.Ammo .. " / " .. self.Capacity
	--text = text .. "\nRound Type: " .. self.RoundType
	local RoundData = ACF.RoundTypes[self.RoundType]

	if RoundData and RoundData.cratetxt then
		text = text .. "\n" .. RoundData.cratetxt(self.BulletData, self)
	end

	if not self.Legal then
		text = text .. "\nNot legal, disabled for " .. math.ceil(self.NextLegalCheck - ACF.CurTime) .. "s\nIssues: " .. self.LegalIssues
	end

	self:SetOverlayText(text)
end

function ENT:CreateAmmo(Id, Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, Data9, Data10)
	local GunData = list.Get("ACFEnts").Guns[Data1]

	if not GunData then
		self:Remove()

		return
	end

	--Data 1 to 4 are should always be Round ID, Round Type, Propellant lenght, Projectile lenght
	self.RoundId = Data1 --Weapon this round loads into, ie 140mmC, 105mmH ...
	self.RoundType = Data2 --Type of round, IE AP, HE, HEAT ...
	self.RoundPropellant = Data3 --Lenght of propellant
	self.RoundProjectile = Data4 --Lenght of the projectile
	self.RoundData5 = (Data5 or 0)
	self.RoundData6 = (Data6 or 0)
	self.RoundData7 = (Data7 or 0)
	self.RoundData8 = (Data8 or 0)
	self.RoundData9 = (Data9 or 0)
	self.RoundData10 = (Data10 or 0)
	local PlayerData = {}
	PlayerData.Id = self.RoundId
	PlayerData.Type = self.RoundType
	PlayerData.PropLength = self.RoundPropellant
	PlayerData.ProjLength = self.RoundProjectile
	PlayerData.Data5 = self.RoundData5
	PlayerData.Data6 = self.RoundData6
	PlayerData.Data7 = self.RoundData7
	PlayerData.Data8 = self.RoundData8
	PlayerData.Data9 = self.RoundData9
	PlayerData.Data10 = self.RoundData10
	self.ConvertData = ACF.RoundTypes[self.RoundType].convert
	self.BulletData = self:ConvertData(PlayerData)
	local Efficiency = 0.1576 * ACF.AmmoMod
	local vol = math.floor(self:GetPhysicsObject():GetVolume())
	self.Volume = vol * Efficiency
	local CapMul = (vol > 40250) and ((math.log(vol * 0.00066) / math.log(2) - 4) * 0.15 + 1) or 1
	local roundType2 = self.RoundType
	local MassMod = 0

	if roundType2 == "APFSDS" then
		MassMod = 11
	elseif roundType2 == "APDS" then
		MassMod = 5.25
	elseif roundType2 == "APCR" then
		MassMod = 5
	else
		MassMod = 1
	end

	self.Capacity = math.floor(CapMul * self.Volume * 16.38 / self.BulletData.RoundVolume)
	self.AmmoMassMax = (self.BulletData.ProjMass * MassMod + self.BulletData.PropMass) * self.Capacity * 2 -- why *2 ?
	self.Caliber = GunData.caliber
	self.RoFMul = (vol > 27000) and (1 - (math.log(vol * 0.00066) / math.log(2) - 4) * 0.2) or 1 --*0.0625 for 25% @ 4x8x8, 0.025 10%, 0.0375 15%, 0.05 20% --0.23 karb edit for cannon rof 2. changed to start from 2x3x4 instead of 2x4x4
	self:SetNWString("Ammo", self.Ammo)
	self:SetNWString("WireName", GunData.name .. " Ammo")
	self.NetworkData = ACF.RoundTypes[self.RoundType].network
	self:NetworkData(self.BulletData)
	self:UpdateOverlayText()
end

function ENT:UpdateMass()
	self.Mass = self.EmptyMass + self.AmmoMassMax * (self.Ammo / math.max(self.Capacity, 1))

	--reduce superflous engine calls, update crate mass every 5 kgs change or every 10s-15s
	if math.abs(self.LastMass - self.Mass) > 5 or CurTime() > self.NextMassUpdate then
		self.LastMass = self.Mass
		self.NextMassUpdate = CurTime() + math.Rand(10, 15)
		local phys = self:GetPhysicsObject()

		if (phys:IsValid()) then
			phys:SetMass(self.Mass)
		end
	end
end

function ENT:GetInaccuracy()
	--local SpreadScale = ACF.SpreadScale
	local inaccuracy = 0
	local Gun = list.Get("ACFEnts").Guns[self.RoundId]

	if Gun then
		local Classes = list.Get("ACFClasses")

		inaccuracy = (Classes.GunClass[Gun.gunclass] or {
			spread = 0
		}).spread
	end

	local coneAng = inaccuracy * ACF.GunInaccuracyScale

	return coneAng
end

function ENT:TriggerInput(iname, value)
	if (iname == "Active") then
		if value > 0 and self.Legal then
			self.Load = true
			self:FirstLoad()
		else
			self.Load = false
		end
	end
end

function ENT:FirstLoad()
	for Key, Value in pairs(self.Master) do
		local Gun = self.Master[Key]

		if IsValid(Gun) and Gun.FirstLoad and Gun.BulletData.Type == "Empty" and Gun.Legal then
			Gun:LoadAmmo(false, false)
		end
	end
end

function ENT:Think()
	if ACF.CurTime > self.NextLegalCheck then
		--local minmass = math.floor(self.EmptyMass+self.AmmoMassMax*((self.Ammo-1)/math.max(self.Capacity,1)))-5  -- some possible weirdness with heavy shells, and refills.  just going to check above empty mass
		self.Legal, self.LegalIssues = ACF_CheckLegal(self, self.Model, math.floor(self.EmptyMass), nil, false, true, false, true)
		self.NextLegalCheck = ACF.LegalSettings:NextCheck(self.Legal)
		self:UpdateOverlayText()

		if not self.Legal then
			--if self.Load then self:TriggerInput("Active",0) end
			self.Load = false
		end
	end

	self:UpdateMass()

	if self.Ammo ~= self.AmmoLast or not self.Legal then
		self:UpdateOverlayText()
		self.AmmoLast = self.Ammo
	end

	local color = self:GetColor()
	self:SetNWVector("TracerColour", Vector(color.r, color.g, color.b))
	local cvarGrav = GetConVar("sv_gravity")
	local vec = Vector(0, 0, cvarGrav:GetInt() * -1)

	self:SetNWVector("Accel", vec)
	self:NextThink(CurTime() + 1)

	-- cookoff handling
	if self.Damaged then
		-- immediately detonate if there's 1 or 0 shells
		if self.Ammo <= 1 or self.Damaged < CurTime() then
			ACF_ScaledExplosion(self) -- going to let empty crates harmlessly poot still, as an audio cue it died
		else
			if not (self.BulletData.Type == "Refill") and math.Rand(0, 150) > self.BulletData.RoundVolume ^ 0.5 and math.Rand(0, 1) < self.Ammo / math.max(self.Capacity, 1) and ACF.RoundTypes[self.BulletData.Type] then
				self:EmitSound("ambient/explosions/explode_4.mp3", 350, math.max(255 - self.BulletData.PropMass * 100, 60))
				local Speed = ACF_MuzzleVelocity(self.BulletData.PropMass, self.BulletData.ProjMass / 2, self.Caliber)
				self.BulletData.Pos = self:LocalToWorld(self:OBBCenter() + VectorRand() * (self:OBBMaxs() - self:OBBMins()) / 2)
				self.BulletData.Flight = (VectorRand()):GetNormalized() * Speed * 39.37 + self:GetVelocity()
				self.BulletData.Owner = self.Inflictor or self.Owner
				self.BulletData.Gun = self
				self.BulletData.Crate = self:EntIndex()
				self.CreateShell = ACF.RoundTypes[self.BulletData.Type].create
				self:CreateShell(self.BulletData)
				self.Ammo = self.Ammo - 1
			end

			self:NextThink(CurTime() + 0.01 + self.BulletData.RoundVolume ^ 0.5 / 100)
		end
		-- Completely new, fresh, genius, beautiful, flawless refill system.
	elseif self.RoundType == "Refill" and self.Ammo > 0 and self.Load then
		for _, Ammo in pairs(ACF.AmmoCrates) do
			if Ammo.RoundType ~= "Refill" then
				local dist = self:GetPos():Distance(Ammo:GetPos())

				if dist < ACF.RefillDistance and Ammo.Capacity > Ammo.Ammo then
					self.SupplyingTo = self.SupplyingTo or {}

					if not table.HasValue(self.SupplyingTo, Ammo:EntIndex()) then
						table.insert(self.SupplyingTo, Ammo:EntIndex())
						self:RefillEffect(Ammo)
					end

					local Supply = math.ceil((50000 / ((Ammo.BulletData.ProjMass + Ammo.BulletData.PropMass) * 1000)) / dist)
					--Msg(tostring(50000).."/"..((Ammo.BulletData.ProjMass+Ammo.BulletData.PropMass)*1000).."/"..dist.."="..Supply.."\n")
					local Transfert = math.min(Supply, Ammo.Capacity - Ammo.Ammo)
					Ammo.Ammo = Ammo.Ammo + Transfert
					self.Ammo = self.Ammo - Transfert
					Ammo.Supplied = true
					Ammo.Entity:EmitSound("items/ammo_pickup.mp3", 350, 80, 0.30)
				end
			end
		end
	end

	-- checks to stop supply
	if self.SupplyingTo then
		for k, EntID in pairs(self.SupplyingTo) do
			local Ammo = ents.GetByIndex(EntID)

			if not IsValid(Ammo) then
				table.remove(self.SupplyingTo, k)
				self:StopRefillEffect(EntID)
			else
				local dist = self:GetPos():Distance(Ammo:GetPos())

				-- If ammo crate is out of refill max distance or is full or our refill crate is damaged or just in-active then stop refiliing it.
				if (dist > ACF.RefillDistance) or (Ammo.Capacity <= Ammo.Ammo) or self.Damaged or not self.Load or not Ammo.Legal then
					table.remove(self.SupplyingTo, k)
					self:StopRefillEffect(EntID)
				end
			end
		end
	end

	Wire_TriggerOutput(self, "Munitions", self.Ammo)

	return true
end

function ENT:RefillEffect(Target)
	net.Start("ACF_RefillEffect")
	net.WriteFloat(self:EntIndex())
	net.WriteFloat(Target:EntIndex())
	net.WriteString(Target.RoundType)
	net.Broadcast()
end

function ENT:StopRefillEffect(TargetID)
	net.Start("ACF_StopRefillEffect")
	net.WriteFloat(self:EntIndex())
	net.WriteFloat(TargetID)
	net.Broadcast()
end

function ENT:OnRemove()
	for Key, Value in pairs(self.Master) do
		if self.Master[Key] and self.Master[Key]:IsValid() then
			self.Master[Key]:Unlink(self)
			self.Ammo = 0
		end
	end

	for k, v in pairs(ACF.AmmoCrates) do
		if v == self then
			table.remove(ACF.AmmoCrates, k)
		end
	end
end