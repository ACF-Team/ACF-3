AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Local Vars

local ACF			= ACF
local Contraption	= ACF.Contraption
local Classes		= ACF.Classes
local Utilities		= ACF.Utilities
local HookRun		= hook.Run

do	-- Spawn and Update funcs
	local WireIO	= Utilities.WireIO
	local Entities	= Classes.Entities
	local Turrets	= Classes.Turrets

	local Outputs	= {
		"Entity (The gyroscope itself.) [ENTITY]"
	}

	local function VerifyData(Data)
		if not Data.Gyro then Data.Gyro = Data.Id end

		local Class = Classes.GetGroup(Turrets, Data.Gyro)

		if not Class then
			Class = Turrets.Get("3-Gyro")

			Data.Destiny	= "TurretGyros"
			Data.Gyro		= "1-Gyro"
		end

		local Gyro = Turrets.GetItem(Class.ID, Data.Gyro)

		if not Gyro then
			Gyro = Turrets.GetItem(Class.ID, "1-Gyro")
		end

		Data.ID		= Gyro.ID
		Data.IsDual	= Gyro.IsDual
	end

	------------------

	local function UpdateGyro(Entity, Data, Class, Gyro)
		Contraption.SetModel(Entity, Gyro.Model)

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		Entity.Name			= Gyro.Name
		Entity.ShortName	= Gyro.ID
		Entity.EntType		= Class.Name
		Entity.ClassData	= Class
		Entity.Class		= Class.ID
		Entity.Gyro			= Data.Gyro
		Entity.Active		= true
		Entity.IsDual		= Gyro.IsDual

		WireIO.SetupOutputs(Entity, Outputs, Data, Class, Gyro)

		Entity:SetNWString("WireName","ACF " .. Entity.Name)
		Entity:SetNWString("Class", Entity.Class)

		WireLib.TriggerOutput(Entity, "Entity", Entity)

		for _,v in ipairs(Entity.DataStore) do
			Entity[v] = Data[v]
		end

		ACF.Activate(Entity, true)

		Entity.DamageScale	= math.max((Entity.ACF.Health / (Entity.ACF.MaxHealth * 0.75)) - 0.25 / 0.75,0)

		Contraption.SetMass(Entity, Gyro.Mass)

		if IsValid(Entity.Turret) then
			Entity.Turret:UpdateTurretSlew()
		end
	end

	function MakeACF_TurretGyro(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class = Classes.GetGroup(Turrets,Data.Gyro)
		local Limit	= Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return end

		local Gyro	= Turrets.GetItem(Class.ID, Data.Gyro)

		local CanSpawn	= HookRun("ACF_PreEntitySpawn", "acf_turret_gyro", Player, Data, Class, Gyro)

		if CanSpawn == false then return end

		local Entity = ents.Create("acf_turret_gyro")

		if not IsValid(Entity) then return end

		Player:AddCleanup(Class.Cleanup, Entity)
		Player:AddCount(Limit, Entity)

		Entity.ACF				= {}

		Contraption.SetModel(Entity, Gyro.Model)

		Entity:SetPlayer(Player)
		Entity:SetAngles(Angle)
		Entity:SetPos(Pos)
		Entity:Spawn()

		Entity.Owner			= Player
		Entity.DataStore		= Entities.GetArguments("acf_turret_gyro")

		UpdateGyro(Entity, Data, Class, Gyro)

		Entity:UpdateOverlay(true)

		HookRun("ACF_OnEntitySpawn", "acf_turret_gyro", Entity, Data, Class, Gyro)

		ACF.CheckLegal(Entity)

		return Entity
	end

	Entities.Register("acf_turret_gyro", MakeACF_TurretGyro, "Gyro")

	function ENT:Update(Data)
		VerifyData(Data)
		local Extra = ""

		local Class = Classes.GetGroup(Turrets, Data.Gyro)
		local Gyro	= Turrets.GetItem(Class.ID, Data.Gyro)
		local OldClass	= self.ClassData

		local CanUpdate, Reason	= HookRun("ACF_PreEntityUpdate", "acf_turret_gyro", self, Data, Class, Gyro)

		if CanUpdate == false then return CanUpdate, Reason end

		HookRun("ACF_OnEntityLast", "acf_turret_gyro", self, OldClass)

		ACF.SaveEntity(self)

		UpdateGyro(self, Data, Class, Gyro)

		ACF.RestoreEntity(self)

		HookRun("ACF_OnEntityUpdate", "acf_turret_gyro", self, Data, Class, Gyro)

		if Data.IsDual ~= self.IsDual then
			self.IsDual = Data.IsDual

			if Data.IsDual then
				if IsValid(self.Turret) then self.Turret:Unlink(self) Extra = "\nUnlinked turret drive." end
			else -- Not dual drive gyro
				if IsValid(self["Turret-H"]) then
					self["Turret-H"]:Link(self) -- Relink the horizontal drive as the primary drive, if available
					self["Turret-H"]:Unlink(self)
					Extra = "\nUnlinked horizontal drive, relinked as primary."
				end

				if IsValid(self["Turret-V"]) then
					if not IsValid(self["Turret-H"]) then
						self["Turret-V"]:Link(self)
						Extra = "\nUnlinked vertical drive, relinked as primary."
					else Extra = Extra .. "\nUnlinked vertical drive." end
					self["Turret-V"]:Unlink(self)
				end
			end
		end

		self:UpdateOverlay(true)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		return true, "Gyro updated successfully!" .. Extra
	end
end

do	-- Metamethods and other important stuff
	do	-- Overlay shenanigans
		function ENT:UpdateOverlayText()
			local Status = ""

			if self.IsDual then
				Status = ("Vertical Drive: " .. (IsValid(self["Turret-V"]) and tostring(self["Turret-V"]) or "Not linked")) .. "\nHorizontal Drive: " .. (IsValid(self["Turret-H"]) and tostring(self["Turret-H"]) or "Not linked")
			else
				Status = "Drive: " .. (IsValid(self.Turret) and tostring(self.Turret) or "Not linked")
			end

			if self.Active then
				Status = Status .. "\nActive"
			else
				Status = Status .. "\nInactve: " .. self.InactiveReason
			end

			return Status
		end
	end

	do	-- ACF Funcs
		function ENT:Enable()
			self:SetActive(true,"")
			self:UpdateOverlay()
		end

		function ENT:Disable()
			self.Active	= false
			self:SetActive(false,"")
			self:UpdateOverlay()
		end

		function ENT:ACF_PostDamage()
			self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75,0)
		end

		function ENT:ACF_OnRepaired() -- Normally has OldArmor, OldHealth, Armor, and Health passed
			self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75,0)
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
			if self.Disabled then return false end

			if not (IsValid(self.Turret) or IsValid(self["Turret-H"]) or IsValid(self["Turret-V"])) then self:SetActive(false,"") return false end

			if (self.ACF.Health / self.ACF.MaxHealth) <= 0.25 then
				self:SetActive(false,"Too damaged!")
				return false
			end

			if self.Active == false then self:SetActive(true,"") end
			return true
		end

		function ENT:GetInfo()
			return self.DamageScale
		end
	end
end