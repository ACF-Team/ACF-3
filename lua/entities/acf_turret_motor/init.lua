AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Local Vars

local ACF			= ACF
local Contraption	= ACF.Contraption
local Classes		= ACF.Classes

local DefaultType = "ACF.Turrets.Motor.Electric"

do	-- Spawn and Update funcs
	local function GetMass(Motor, Size)
		local SizePerc = Size ^ 2
		return math.Round(math.max(Motor.Mass * SizePerc, 5), 1)
	end

	function ENT:ACF_PreSpawn(_, _, _, Data)
		self.ACF = {}

		local Sel   = Data and Data.Motor
		local Class = Classes.GetTypeByName(Sel and Sel.Type or DefaultType) or Classes.GetTypeByName(DefaultType)

		self:SetScaledModel(Class.Model)
	end

	function ENT:ACF_PostUpdateEntityData()
		local Motor = self:ACF_GetUserVar("Motor")
		local Class = Motor:GetType()
		local Group = Classes.GetBaseClass(Class)
		local Size  = self:ACF_GetUserVar("CompSize")
		local Teeth = self:ACF_GetUserVar("Teeth")
		local Model = Motor.Model

		self:SetScaledModel(Model)
		self:SetScale(Size)

		self.ACF.Model      = Model
		self.Name           = Motor.Name
		self.ShortName      = Motor.ID
		self.EntType        = Group.Name
		self.Class          = Group.ID
		self.CompSize       = Size
		self.Motor          = Motor.ID
		self.Active         = true
		self.SoundPath      = Motor.Sound
		self.DefaultSound   = Motor.Sound

		self.Torque         = Group.GetTorque(Motor, Size)
		self.Teeth          = Teeth
		self.Efficiency     = Motor.Efficiency
		self.Speed          = Motor.Speed
		self.Accel          = Motor.Accel
		self.ValidPlacement = false

		self.ScaledArmor    = math.max(math.Round(5 * (Size ^ 1.2), 1), 2)

		self:SetNWString("WireName", "ACF " .. self.Name)
		self:SetNWString("Class", self.Class)

		-- ACF.Activate(self, true) is invoked automatically by ACF_UpdateEntityData after this.

		local Health    = self.ACF.Health
		local MaxHealth = self.ACF.MaxHealth
		self.DamageScale = (Health and MaxHealth) and math.max((Health / (MaxHealth * 0.75)) - 0.25 / 0.75, 0) or 1

		Contraption.SetMass(self, GetMass(Motor, Size))

		if IsValid(self.Turret) then
			self.Turret:UpdateTurretSlew()
			self:ValidatePlacement()
		end
	end
end

do	-- Metamethods and other important stuff
	do
		function ENT:ACF_UpdateOverlayState(State)
			if IsValid(self.Turret) then
				if self.Active then
					State:AddKeyValue("Status", "Active")
				else
					State:AddError("Status: " .. self.InactiveReason)
				end
				State:AddKeyValue("Linked to", tostring(self.Turret))
			else
				State:AddError("Inactive: Not linked to a turret drive!")
			end

			State:AddKeyValue("Torque", ("%G Nm"):format(self.Torque))
			State:AddKeyValue("Gear Teeth", ("%G t"):format(self.Teeth))
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

			if self.Turret then self.Turret:UpdateTurretSlew() end
		end

		function ENT:ACF_OnRepaired() -- Normally has OldArmor, OldHealth, Armor, and Health passed
			self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75, 0)

			if self.Turret then self.Turret:UpdateTurretSlew() end
		end

		function ENT:ACF_Activate(Recalc)
			local PhysObj	= self.ACF.PhysObj
			local Area		= PhysObj:GetSurfaceArea() * ACF.InchToCmSq
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

		function ENT:SetActive(Active, Reason)
			self.Active = Active
			self.InactiveReason = Reason

			self:UpdateOverlay(true)
		end

		function ENT:CFW_OnParentedTo(_, _)
			self:ValidatePlacement()
		end

		function ENT:ValidatePlacement()
			self.ValidPlacement = true

			if not IsValid(self.Turret) then self.ValidPlacement = false self:SetActive(false, "") return end

			if not IsValid(self:GetParent()) then
				self.ValidPlacement = false
				self:SetActive(false, "Must be parented!")
				return
			end

			local Turret = self.Turret
			local LocPos	= Turret:OBBCenter() + Turret:WorldToLocal(self:LocalToWorld(self:OBBCenter()))
			local MaxDist	= (((Turret.TurretData.RingSize / 2) * 1.2) + 12 + self.CompSize * 7.5) ^ 2
			local LocDist	= Vector(LocPos.x, LocPos.y, 0):Length2DSqr()

			if LocDist > MaxDist then
				self.ValidPlacement = false
				self:SetActive(false, "Too far from ring!")
				return
			end

			if math.abs(LocPos.z) > ((Turret.TurretData.RingHeight * 1.5) + 12) then
				self.ValidPlacement = false
				self:SetActive(false, "Too far above/below ring!")
				return
			end

			if (IsValid(Turret:GetParent()) and self:GetParent() ~= Turret:GetParent()) and (self:GetParent() ~= Turret) then
				self.ValidPlacement = false
				self:SetActive(false, "Must be parented to (or share parent with) the ring!")
				return
			end
		end

		function ENT:IsActive()
			if self.Disabled then return false end
			if self.ValidPlacement == false then return false end

			if (self.ACF.Health / self.ACF.MaxHealth) <= 0.25 then
				self:SetActive(false, "Too damaged!")
				return false
			end

			if self.Active == false then self:SetActive(true, "") end
			return true
		end

		function ENT:GetCost()
			return self.CompSize * 2
		end

		function ENT:GetInfo()
			return {Teeth = self.Teeth, Speed = self.Speed, Torque = self.Torque * self.DamageScale, Efficiency = self.Efficiency, Accel = self.Accel}
		end
	end
end
