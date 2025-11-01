AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF         = ACF
local Classes     = ACF.Classes
local Contraption = ACF.Contraption
local Entities    = Classes.Entities

do -- Spawning and Updating
	local Armors = Classes.ArmorTypes

	function ENT.ACF_GetHookArguments(Data)
		return Armors.Get(Data.ArmorType)
	end

	function ENT.ACF_PreVerifyClientData(Data)
		-- Verifying dimension values
		if not isnumber(Data.Width) then
			Data.Width = ACF.CheckNumber(Data.PlateSizeX, 24)
		end

		if not isnumber(Data.Height) then
			Data.Height = ACF.CheckNumber(Data.PlateSizeY, 24)
		end

		if not isnumber(Data.Thickness) then
			Data.Thickness = ACF.CheckNumber(Data.PlateSizeZ, 5)
		end
	end

	function ENT.ACF_OnVerifyClientData(Data)
		local Armor = Armors.Get(Data.ArmorType)

		-- Verifying dimension values
		local MaxPossible = ACF.MaximumMass / (Data.Width * Data.Height * Armor.Density * ACF.gCmToKgIn) * ACF.InchToMm
		local MaxAllowed  = math.min(ACF.MaximumArmor, ACF.GetServerNumber("MaxThickness"))

		Data.Thickness = math.min(Data.Thickness, MaxPossible)
		Data.Size      = Vector(Data.Width, Data.Height, math.Clamp(Data.Thickness, ACF.MinimumArmor, MaxAllowed) * ACF.MmToInch)

		-- External verifications
		if Armor.VerifyData then
			Armor:VerifyData(Data)
		end
	end

	function ENT:ACF_PostUpdateEntityData(Data)
		local Armor = self:ACF_GetUserVar("ArmorType")
		local Size = Data.Size

		self.ClassData  = Armor
		self.Tensile    = Armor.Tensile
		self.Density    = Armor.Density

		self:SetNW2String("ArmorType", Armor.ID)
		self:SetSize(Size)

		self:UpdateMass(true)

		if Armor.OnUpdate then
			Armor:OnUpdate(self, Data)
		end
	end

	function ENT:ACF_PreSpawn()
		self:SetScaledModel("models/holograms/hq_rcube_thin.mdl")
		self:SetMaterial("phoenix_storms/metalfloor_2-3")
	end

	function ENT:ACF_PostSpawn(_, _, _, Data)
		duplicator.ClearEntityModifier(self, "mass")

		local Armor = self:ACF_GetUserVar("ArmorType")

		if Armor.OnSpawn then
			Armor:OnSpawn(self, Data)
		end
	end
end

do -- ACF Activation and Damage
	local Trace = { Entity = true, StartPos = true, HitPos = true }
	local TensileDivisor = 1111 -- Balancing health multiplier around RHA

	function ENT:ACF_Activate(Recalc)
		local PhysObj = self.ACF.PhysObj
		local Area = PhysObj:GetSurfaceArea() * ACF.InchToCmSq
		local Health  = Area / ACF.Threshold * (self.Tensile / TensileDivisor)
		local Percent = 1

		if Recalc and self.ACF.Health and self.ACF.MaxHealth then
			Percent = self.ACF.Health / self.ACF.MaxHealth
		end

		self.ACF.Area      = Area
		self.ACF.Armour    = 1
		self.ACF.MaxArmour = 1
		self.ACF.Health    = Health * Percent
		self.ACF.MaxHealth = Health
		self.ACF.Ductility = 0
		self.ACF.Type      = "Prop"
	end

	function ENT:ACF_OnDamage(DmgResult, DmgInfo)
		Trace.Entity   = self
		Trace.StartPos = DmgInfo:GetOrigin()
		Trace.HitPos   = DmgInfo:GetHitPos()

		local Armor  = self:GetArmor(Trace)
		local Area   = DmgResult:GetArea()
		local Pen    = DmgResult:GetPenetration()
		local MaxPen = math.min(Armor, Pen)
		local Forced = DmgResult.Damage
		local Damage = isnumber(Forced) and Forced or MaxPen * Area -- Damage is simply the volume of the hole made
		local HP     = self.ACF.Health

		self.ACF.Health = HP - Damage -- Update health

		--[[
		print("Damage!")
		print("    PenCaliber: " .. math.Round(Bullet.Diameter * 10))
		print("    MaxPen: " .. MaxPen)
		print("    MaxDamage: " .. Pen * Area)
		print("    HP: " .. math.Round(HP, 3))
		print("    Effective Armor: " .. math.Round(Armor))
		print("    Damage: " .. math.Round(Damage, 3))
		print("    pdHP: " .. math.Round(self.ACF.Health, 3))
		print("    Loss: " .. math.Clamp(MaxPen / Pen, 0, 1))
		]]--

		return { -- Damage report
			Loss     = math.Clamp(MaxPen / Pen, 0, 1), -- Energy loss ratio
			Damage   = Damage,
			Overkill = math.max(Pen - MaxPen, 0),
			Kill     = Damage > HP
		}
	end
end

do -- Mass Update
	local TimerCreate = timer.Create
	local TimerExists = timer.Exists

	local function UpdateMass(Entity)
		local Size = Entity.Size
		local Mass = Entity.ClassData:GetMass(Size.x * Size.y * Size.z)

		Contraption.SetMass(Entity, Mass)
	end

	function ENT:UpdateMass(Instant)
		if Instant then
			return UpdateMass(self)
		end

		if TimerExists("ACF Mass Buffer" .. self:EntIndex()) then return end

		TimerCreate("ACF Mass Buffer" .. self:EntIndex(), 1, 1, function()
			if not IsValid(self) then return end

			UpdateMass(self)
		end)
	end
end

do -- Wire overlay text
	local OverlayText = "Armor Type: %s\nPlate Size: %.1f x %.1f x %.1f"

	function ENT:UpdateOverlayText()
		return OverlayText:format(self.ClassData.Name, self.Size[1], self.Size[2], self.Size[3])
	end
end

Entities.Register()