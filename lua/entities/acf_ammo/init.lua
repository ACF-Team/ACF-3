AddCSLuaFile("cl_init.lua")

DEFINE_BASECLASS("base_wire_entity")

ENT.PrintName     = "ACF Ammo Crate"
ENT.WireDebugName = "ACF Ammo Crate"

util.AddNetworkString("ACF_RefillEffect")
util.AddNetworkString("ACF_StopRefillEffect")

local CheckLegal = ACF_CheckLegal

function MakeACF_Ammo(Player, Pos, Angle, Id, Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, Data9, Data10)
	if not Player:CheckLimit("_acf_ammo") then return false end

	local Crate = ents.Create("acf_ammo")

	if not IsValid(Crate) then return end

	Player:AddCount("_acf_ammo", Crate)
	Player:AddCleanup("acfmenu", Crate)

	Crate:SetPos(Pos)
	Crate:SetAngles(Angle)
	Crate:SetPlayer(Player)
	Crate:SetModel(ACF.Weapons.Ammo[Id].model)
	Crate:PhysicsInit(SOLID_VPHYSICS)
	Crate:SetMoveType(MOVETYPE_VPHYSICS)
	Crate:Spawn()

	Crate:CreateAmmo(Id, Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, Data9, Data10)
	Crate.IsMaster		= true
	Crate.IsExplosive   = true
	Crate.Ammo			= Crate.Capacity
	Crate.EmptyMass		= ACF.Weapons.Ammo[Id].weight
	Crate.Id			= Id
	Crate.Owner			= Player
	Crate.Size			= Size
	Crate.Weapons		= {}
	Crate.Load			= true -- Crates should be ready to load by default
	Crate.SpecialHealth	= true -- Will call self:ACF_Activate
	Crate.SpecialDamage = true -- Will call self:ACF_OnDamage
	Crate.Inputs		= Wire_CreateInputs( Crate, { "Load" } )
	Crate.Outputs		= WireLib.CreateOutputs( Crate, { "Entity [ENTITY]", "Ammo" } )
	Crate.CanUpdate		= true

	ACF.AmmoCrates[Crate] = true

	Wire_TriggerOutput(Crate, "Entity", Crate)
	Wire_TriggerOutput(Crate, "Ammo", Crate.Ammo)

	Crate:UpdateOverlay()

	local Mass = Crate.EmptyMass + Crate.AmmoMassMax
	local Phys = Crate:GetPhysicsObject()
	if IsValid(Phys) then
		Phys:SetMass(Mass)
	end

	ACF_Activate(Crate) -- Makes Crate.ACF table

	Crate.ACF.PhysObj	= Phys
	Crate.ACF.Model 	= ACF.Weapons.Ammo[Id].model
	Crate.ACF.LegalMass = Mass

	CheckLegal(Crate)

	return Crate
end
list.Set("ACFCvars", "acf_ammo", {"id", "data1", "data2", "data3", "data4", "data5", "data6", "data7", "data8", "data9", "data10"})
duplicator.RegisterEntityClass("acf_ammo", MakeACF_Ammo, "Pos", "Angle", "Id", "RoundId", "RoundType", "RoundPropellant", "RoundProjectile", "RoundData5", "RoundData6", "RoundData7", "RoundData8", "RoundData9", "RoundData10")

function ENT:ACF_Activate(Recalc)
	local EmptyMass = math.max(self.EmptyMass, self:GetPhysicsObject():GetMass() - self.AmmoMassMax)
	local PhysObj   = self:GetPhysicsObject()

	self.ACF = self.ACF or {}

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

function ENT:CreateAmmo(_, Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, Data9, Data10)
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
	self.BulletData.Crate = self:EntIndex()

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
	self:UpdateOverlay()
end

function ENT:TriggerInput(Input, Value)
	if self.Disabled then return end -- Ignore input if disabled

	if Input == "Load" then
		self.Load = self.Ammo ~= 0 and tobool(Value)

		Wire_TriggerOutput(self, "Loading", self.Load and 1 or 0)
		self:UpdateOverlay()
	end
end

function ENT:Link(Target)
	if not IsValid(Target) then return false, "This crate is not a valid entity." end
	if Target:GetClass() ~= "acf_gun" then return false, "Crates can only be linked to weapons." end
	if Target.Crates[self] then return false, "This crate is already linked to this weapon." end
	if self.BulletData.Id ~= Target.Id then return false, "Wrong ammo type for this weapon." end

	self.Weapons[Target] = true
	Target.Crates[self]  = true

	self:UpdateOverlay()
	Target:UpdateOverlay()

	return true, "Crate linked successfully."
end

function ENT:Unlink(Target)
	if not IsValid(Target) then return false, "This crate is not a valid entity." end
	if Target:GetClass() ~= "acf_gun" then return false, "Crates can only be unlinked from weapons." end
	if not Target.Crates[self] then return false, "This crate is not linked to this weapon." end

	self.Weapons[Target] = nil
	Target.Crates[self]  = nil

	return true, "Crate unlinked successfully."
end

function ENT:OnRemove()
	for K in pairs(self.Weapons) do
		self:Unlink(K)
	end
end

function ENT:Consume()
	self.Ammo = self.Ammo - 1

	self:UpdateOverlay()
	self:UpdateMass()

	if self.Ammo == 0 then
		self.Load = false
	end

	Wire_TriggerOutput(Crate, "Ammo", self.Ammo)
end

function ENT:Update(ArgsTable)
	-- That table is the player data, as sorted in the ACFCvars above, with player who shot, 
	-- and pos and angle of the tool trace inserted at the start
	local msg = "Ammo crate updated successfully!"
	if ArgsTable[1] ~= self.Owner then return false, "You don't own that ammo crate!" end -- Argtable[1] is the player that shot the tool
	if ArgsTable[6] == "Refill" then return false, "Refill ammo type is only avaliable for new crates!" end -- Argtable[6] is the round type. If it's refill it shouldn't be loaded into guns, so we refuse to change to it

	-- Argtable[5] is the weapon ID the new ammo loads into
	if ArgsTable[5] ~= self.RoundId then
		for Gun in pairs(self.Weapons) do
			Gun:Unlink(self)
		end

		msg = "New ammo type loaded, crate unlinked."
	else -- ammotype wasn't changed, but let's check if new roundtype is blacklisted
		local Blacklist = ACF.AmmoBlacklist[ArgsTable[6]] or {}

		for Gun in pairs(self.Weapons) do
			if table.HasValue(Blacklist, Gun.Class) then
				Gun:Unlink(self)
				msg = "New round type cannot be used with linked gun, crate unlinked."
			end
		end
	end

	local AmmoPercent = self.Ammo / math.max(self.Capacity, 1)
	self:CreateAmmo(ArgsTable[4], ArgsTable[5], ArgsTable[6], ArgsTable[7], ArgsTable[8], ArgsTable[9], ArgsTable[10], ArgsTable[11], ArgsTable[12], ArgsTable[13], ArgsTable[14])
	self.Ammo = math.floor(self.Capacity * AmmoPercent)
	self:UpdateMass()

	return true, msg
end

function ENT:UpdateOverlay()
	if not timer.Exists("ACF Overlay Buffer" .. self:EntIndex()) then
		timer.Create("ACF Overlay Buffer" .. self:EntIndex(), 1, 1, function()
			if IsValid(self) then
				local Status

				if self.DisableReason then
					Status = "Disabled: " .. self.DisableReason
				elseif next(self.Weapons) then
					Status = self.Load and "Providing Ammo" or (self.Ammo ~= 0 and "Idle" or "Empty")
				else
					Status = "Not linked to a weapon!"
				end

				local Tracer = self.BulletData.Tracer ~= 0 and "-T" or ""
				self:SetOverlayText(string.format("%s\n\n%sRounds remaining: %s", Status, self.BulletData.Type .. Tracer .. "\n", self.Ammo))
			end
		end)
	end
end

function ENT:UpdateMass()
	if not timer.Exists("ACF Mass Buffer" .. self:EntIndex()) then
		timer.Create("ACF Mass Buffer" .. self:EntIndex(), 1, 1, function()
			if IsValid(self) then
				self.ACF.LegalMass = self.EmptyMass + self.AmmoMassMax * (self.Ammo / math.max(self.Capacity, 1))

				local Phys = self:GetPhysicsObject()

				if IsValid(Phys) then
					Phys:SetMass(self.ACF.LegalMass)
				end
			end
		end)
	end
end

function ENT:Think()
	local Col = self:GetColor()
	self:SetNWVector("TracerColour", Vector( Col.r, Col.g, Col.b ) )

	if self.Damaged then
		if self.Ammo <= 1 or self.Damaged < CurTime() then -- immediately detonate if there's 1 or 0 shells
			ACF_ScaledExplosion( self ) -- going to let empty crates harmlessly poot still, as an audio cue it died
		elseif self.BulletData.Type ~= "Refill" and math.Rand(0,150) > self.BulletData.RoundVolume^0.5 and math.Rand(0,1) < self.Ammo / math.max(self.Capacity,1) and ACF.RoundTypes[self.BulletData.Type] then
			self:EmitSound("ambient/explosions/explode_4.wav", 350, math.max(255 - self.BulletData.PropMass * 100,60))

			local Speed = ACF_MuzzleVelocity( self.BulletData.PropMass, self.BulletData.ProjMass / 2, self.Caliber )

			self.BulletData.Pos = self:LocalToWorld(self:OBBCenter() + VectorRand() * (self:OBBMaxs() - self:OBBMins()) / 2)
			self.BulletData.Flight = (VectorRand()):GetNormalized() * Speed * 39.37 + self:GetVelocity()
			self.BulletData.Owner = self.Inflictor or self.Owner
			self.BulletData.Gun = self
			self.BulletData.Crate = self:EntIndex()
			self.CreateShell = ACF.RoundTypes[self.BulletData.Type].create(self, self.BulletData)

			self.Ammo = self.Ammo - 1
		end

		self:NextThink( CurTime() + 0.01 + self.BulletData.RoundVolume^0.5 / 100 )
	else
		self:NextThink(CurTime() + 3)
	end

	return true
end

function ENT:Enable()
	self.Disabled = nil

	if self.Inputs.Load.Path then
		self.Load = tobool(self.Inputs.Load.Value)
	else
		self.Load = true
	end

	CheckLegal(self)
end

function ENT:Disable()
	self.Disabled = true
	self.Load     = false
	self.Ammo     = 0

	self:UpdateOverlay()
	self:UpdateMass()

	timer.Simple(ACF.IllegalDisableTime, function()
		if IsValid(self) then
			self:Enable()
		end
	end)
end

function ENT:ACF_OnDamage(Entity, Energy, FrArea, Angle, Inflictor, _, Type)
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