AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Local Vars

local ACF			= ACF
local Contraption	= ACF.Contraption
local Classes		= ACF.Classes

local DefaultType = "ACF.Turrets.Gyro.Single"

do	-- Spawn and Update funcs
	function ENT:ACF_PreSpawn(_, _, _, Data)
		self.ACF = {}

		local Sel   = Data and Data.Gyro
		local Class = Classes.GetTypeByName(Sel and Sel.Type or DefaultType) or Classes.GetTypeByName(DefaultType)

		Contraption.SetModel(self, Class.Model)
	end

	function ENT:ACF_PostUpdateEntityData()
		local Gyro    = self:ACF_GetUserVar("Gyro")
		local Class   = Gyro:GetType()
		local Group   = Classes.GetBaseClass(Class)
		local WasDual = self.IsDual

		Contraption.SetModel(self, Gyro.Model)

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		self.Name      = Gyro.Name
		self.ShortName = Gyro.ID
		self.EntType   = Group.Name
		self.Class     = Group.ID
		self.Gyro      = Gyro.ID
		self.Active    = true
		self.IsDual    = Gyro.IsDual

		self:SetNWString("WireName", "ACF " .. self.Name)
		self:SetNWString("Class", self.Class)

		-- ACF.Activate(self, true) is invoked automatically by ACF_UpdateEntityData after this.

		local Health    = self.ACF.Health
		local MaxHealth = self.ACF.MaxHealth
		self.DamageScale = (Health and MaxHealth) and math.max((Health / (MaxHealth * 0.75)) - 0.25 / 0.75, 0) or 1

		Contraption.SetMass(self, Gyro.Mass)

		if IsValid(self.Turret) then
			self.Turret:UpdateTurretSlew()
		end

		-- When switching between single/dual axis on an existing gyro, drop the now-invalid links.
		if WasDual ~= nil and WasDual ~= Gyro.IsDual then
			if Gyro.IsDual then
				if IsValid(self.Turret) then self.Turret:Unlink(self) end
			else -- Not dual drive gyro
				if IsValid(self["Turret-H"]) then
					self["Turret-H"]:Link(self) -- Relink the horizontal drive as the primary drive, if available
					self["Turret-H"]:Unlink(self)
				end

				if IsValid(self["Turret-V"]) then
					if not IsValid(self["Turret-H"]) then
						self["Turret-V"]:Link(self)
					end
					self["Turret-V"]:Unlink(self)
				end
			end
		end
	end
end

do	-- Metamethods and other important stuff
	do	-- Overlay shenanigans
		function ENT:ACF_UpdateOverlayState(State)
			if self.IsDual then
				State:AddKeyValue("Vertical Drive", IsValid(self["Turret-V"]) and tostring(self["Turret-V"]) or "Not linked")
				State:AddKeyValue("Horizontal Drive", IsValid(self["Turret-H"]) and tostring(self["Turret-H"]) or "Not linked")
			else
				State:AddKeyValue("Drive", IsValid(self.Turret) and tostring(self.Turret) or "Not linked")
			end

			if self.Active then
				State:AddKeyValue("Status", "Active")
			else
				State:AddError("Inactive: " .. self.InactiveReason)
			end
		end
	end

	do	-- ACF Funcs
		function ENT:Enable()
			self:SetActive(true, "")
			self:UpdateOverlay()
		end

		function ENT:Disable()
			self.Active	= false
			self:SetActive(false, "")
			self:UpdateOverlay()
		end

		function ENT:ACF_PostDamage()
			self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75, 0)
		end

		function ENT:ACF_OnRepaired() -- Normally has OldArmor, OldHealth, Armor, and Health passed
			self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75, 0)
		end

		function ENT:SetActive(Active, Reason)
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

			if not (IsValid(self.Turret) or IsValid(self["Turret-H"]) or IsValid(self["Turret-V"])) then self:SetActive(false, "") return false end

			if (self.ACF.Health / self.ACF.MaxHealth) <= 0.25 then
				self:SetActive(false, "Too damaged!")
				return false
			end

			if self.Active == false then self:SetActive(true, "") end
			return true
		end

		function ENT:GetCost()
			return self.IsDual and 8 or 4
		end

		function ENT:GetInfo()
			return self.DamageScale
		end
	end
end
