AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Local Vars

local ACF			= ACF
local Classes		= ACF.Classes
local Utilities		= ACF.Utilities
local HookRun		= hook.Run

do	-- Spawn and Update funcs
	local WireIO	= Utilities.WireIO
	local Entities	= Classes.Entities
	local Turrets	= Classes.Turrets

	local Outputs	= {
		"Entity (The turret motor itself.) [ENTITY]"
	}

	local function VerifyData(Data)
		if not Data.Motor then Data.Motor = Data.Id end

		local Class = Classes.GetGroup(Turrets, Data.Motor)

		if not Class then
			Class = Turrets.Get("2-Motor")

			Data.Destiny		= "Motors"
			Data.Motor			= "Motor-ELC"
		end

		local Motor = Turrets.GetItem(Class.ID, Data.Motor)

		if not Motor then
			Motor = Turrets.GetItem(Class.ID, "Motor-ELC")
		end

		Data.ID		= Motor.ID

		Data.CompSize	= math.Clamp(Data.CompSize, Motor.ScaleLimit.Min, Motor.ScaleLimit.Max)

		Data.Teeth		= math.Clamp(math.Round(Data.Teeth), Motor.Teeth.Min, Motor.Teeth.Max)
	end

	------------------

	local function GetMass(Motor,Data)
		local SizePerc = Data.CompSize ^ 2
		return math.Round(math.max(Motor.Mass * SizePerc,5), 1)
	end

	local function UpdateMotor(Entity, Data, Class, Motor)
		local Model		= Motor.Model
		local Size		= Data.CompSize

		Entity:SetScaledModel(Model)
		Entity:SetScale(Size)

		Entity.ACF.Model	= Model
		Entity.Name			= Motor.Name
		Entity.ShortName	= Motor.ID
		Entity.EntType		= Class.Name
		Entity.ClassData	= Class
		Entity.Class		= Class.ID
		Entity.CompSize		= Size
		Entity.Motor		= Data.Motor
		Entity.Active		= true

		Entity.Torque		= Class.GetTorque(Motor,Size)
		Entity.Teeth		= Data.Teeth
		Entity.Efficiency	= Motor.Efficiency
		Entity.Speed		= Motor.Speed
		Entity.Accel		= Motor.Accel

		Entity.ScaledArmor	= math.max(math.Round(5 * (Size ^ 1.2),1),2)

		WireIO.SetupOutputs(Entity, Outputs, Data, Class, Motor)

		Entity:SetNWString("WireName","ACF " .. Entity.Name)
		Entity:SetNWString("Class", Entity.Class)

		WireLib.TriggerOutput(Entity, "Entity", Entity)

		for _,v in ipairs(Entity.DataStore) do
			Entity[v] = Data[v]
		end

		ACF.Activate(Entity, true)

		Entity.DamageScale	= math.max((Entity.ACF.Health / (Entity.ACF.MaxHealth * 0.75)) - 0.25 / 0.75,0)

		local PhysObj = Entity:GetPhysicsObject()

		if IsValid(PhysObj) then
			local Mass = GetMass(Motor,Data)

			Entity.ACF.Mass			= Mass
			Entity.ACF.LegalMass	= Mass

			PhysObj:SetMass(Mass)
		end

		if IsValid(Entity.Turret) then
			Entity.Turret:UpdateTurretSlew()
		end
	end

	function MakeACF_TurretMotor(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class = Classes.GetGroup(Turrets,Data.Motor)
		local Limit	= Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return end

		local Motor	= Turrets.GetItem(Class.ID, Data.Motor)

		local CanSpawn	= HookRun("ACF_PreEntitySpawn", "acf_turret_motor", Player, Data, Class, Motor)

		if CanSpawn == false then return end

		local Entity = ents.Create("acf_turret_motor")

		if not IsValid(Entity) then return end

		Player:AddCleanup(Class.Cleanup, Entity)
		Player:AddCount(Limit, Entity)

		Entity:SetModel(Motor.Model)
		Entity:SetPlayer(Player)
		Entity:SetAngles(Angle)
		Entity:SetPos(Pos)
		Entity:Spawn()

		Entity.ACF				= {}
		Entity.Owner			= Player
		Entity.DataStore		= Entities.GetArguments("acf_turret_motor")

		UpdateMotor(Entity, Data, Class, Motor)

		Entity:UpdateOverlay(true)

		HookRun("ACF_OnEntitySpawn", "acf_turret_motor", Entity, Data, Class, Motor)

		ACF.CheckLegal(Entity)

		return Entity
	end

	Entities.Register("acf_turret_motor", MakeACF_TurretMotor, "Motor", "CompSize")

	function ENT:Update(Data)
		VerifyData(Data)

		local Class = Classes.GetGroup(Turrets, Data.Motor)
		local Motor	= Turrets.GetItem(Class.ID, Data.Motor)
		local OldClass	= self.ClassData

		local CanUpdate, Reason	= HookRun("ACF_PreEntityUpdate", "acf_turret_motor", self, Data, Class, Motor)

		if CanUpdate == false then return CanUpdate, Reason end

		HookRun("ACF_OnEntityLast", "acf_turret_motor", self, OldClass)

		ACF.SaveEntity(self)

		UpdateMotor(self, Data, Class, Motor)

		ACF.RestoreEntity(self)

		HookRun("ACF_OnEntityUpdate", "acf_turret_motor", self, Data, Class, Motor)

		self:UpdateOverlay(true)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		--self:UpdateTurretMass()

		return true, "Motor updated successfully!"
	end
end

do	-- Metamethods and other important stuff
	do
		local Text = "%s\n\n%GNm Torque\n%Gt"
		function ENT:UpdateOverlayText()
			local Status = ""
			if IsValid(self.Turret) then
				if self.Active then
					Status = "Linked to " .. tostring(self.Turret)
				else
					Status = self.InactiveReason
				end
			else
				Status = "Not linked to a turret drive!"
			end

			return Text:format(Status,self.Torque,self.Teeth)
		end
	end

	do	-- ACF Funcs
		function ENT:Enable()
			self.Active	= true
			self:UpdateOverlay()
		end

		function ENT:Disable()
			self.Active	= true
			self:UpdateOverlay()
		end

		function ENT:ACF_OnDamage(DmgResult, DmgInfo)
			local HitRes = Damage.doPropDamage(self, DmgResult, DmgInfo)

			self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75,0)

			return HitRes
		end

		function ENT:ACF_OnRepaired() -- Normally has OldArmor, OldHealth, Armor, and Health passed
			self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75,0)

			self:UpdateOverlay()
		end

		function ENT:ACF_Activate(Recalc)
			local PhysObj	= self.ACF.PhysObj
			local Area		= PhysObj:GetSurfaceArea() * 6.45
			local Armour	= self.ScaledArmor
			local Health	= Area / ACF.Threshold
			local Percent	= 1

			if Recalc and self.ACF.Health and self.ACF.MaxHealth then
				Percent = self.ACF.Health / self.ACF.MaxHealth
			end

			self.ACF.Area		= Area
			self.ACF.Health		= Health * Percent
			self.ACF.MaxHealth	= Health
			self.ACF.Armour		= Armour * (0.5 + Percent * 0.5)
			self.ACF.MaxArmour	= Armour
			self.ACF.Type		= "Prop"
		end

		function ENT:SetActive(Active,Reason)
			local Trigger = (self.Active ~= Active) or (self.InactiveReason ~= Reason)
			if not Active then
				self.InactiveReason = Reason
				self.Active = false
			else
				self.InactiveReason = ""
				self.Active = true
			end

			if Trigger then self:UpdateOverlay(true) end
		end

		function ENT:IsActive()
			if not IsValid(self.Turret) then self:SetActive(false,"") return false end
			local Turret = self.Turret

			local LocPos	= Turret:WorldToLocal(self:LocalToWorld(self:OBBCenter()))
			local MaxDist	= (((Turret.TurretData.RingSize / 2) * 1.1) + 12) ^ 2
			local LocDist	= Vector(LocPos.x,LocPos.y,0):Length2DSqr()

			if LocDist > MaxDist then
				self:SetActive(false,"Too far from ring!")
				return false
			end

			if math.abs(LocPos.z) > ((Turret.TurretData.RingHeight * 1.5) + 12) then
				self:SetActive(false,"Too far above/below ring!")
				return false
			end

			if not IsValid(self:GetParent()) then
				self:SetActive(false,"Must be parented!")
				return false
			end

			if (self:GetParent() ~= Turret:GetParent()) and (self:GetParent() ~= Turret) then
				self:SetActive(false,"Must be parented to (or share parent with) the ring!")
				return false
			end

			if (self.ACF.Health / self.ACF.MaxHealth) <= 0.5 then
				self:SetActive(false,"Too damaged!")
				return false
			end

			if self.Active == false then self:SetActive(true,"") end
			return true
		end

		function ENT:GetInfo()
			return {Teeth = self.Teeth, Speed = self.Speed, Torque = self.Torque, Efficiency = self.Efficiency, Accel = self.Accel}
		end
	end
end