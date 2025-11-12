AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF         = ACF
local WireLib     = WireLib
local Contraption = ACF.Contraption
local TimerCreate = timer.Create
local TimerExists = timer.Exists
local Clamp       = math.Clamp
local Round       = math.Round

ENT.Spawnable      = false
ENT.AdminSpawnable = false
ENT.WireAmountName = "Amount" -- Default wire output name for amount (Can be aliased to "Fuel" or "Ammo" or whatever)


function ENT:GetUnitMass()
	-- Returns kg per unit (e.g., kg per round, kg per liter, kg per kWh)
	return self.UnitMass or 1
end

function ENT:SetAmount(Amount)
	local Cap = self.Capacity or 0
	local New = Round(Clamp(Amount or 0, 0, Cap), 2)

	if New == self.Amount then return end

	self.Amount = New

	if WireLib then
		WireLib.TriggerOutput(self, self.WireAmountName, New)
	end

	self:UpdateMass()
	if self.UpdateOverlay then self:UpdateOverlay() end
end

function ENT:Consume(Amount)
	local New = self.Amount - Amount

	self:SetAmount(New)
end

function ENT:CanConsume()
	if self.Disabled then return false end
	if not self.Active then return false end

	return self.Amount > 0
end

function ENT:UpdateMass(Instant)
	if Instant then
		local NewMass = self.EmptyMass + (self.Amount * self:GetUnitMass())
		Contraption.SetMass(self, NewMass)
		return
	end

	local ID = "ACF Mass Buffer " .. self:EntIndex()

	if TimerExists(ID) then return end

	TimerCreate(ID, 0, 1, function()
		if not IsValid(self) then return end
		local NewMass = self.EmptyMass + (self.Amount * self:GetUnitMass())
		Contraption.SetMass(self, NewMass)
	end)
end

function ENT:Enable()
	WireLib.TriggerOutput(self, "Activated", self:CanConsume() and 1 or 0)
end

function ENT:Disable()
	WireLib.TriggerOutput(self, "Activated", 0)
end

function ENT:OnRemove()
	WireLib.Remove(self)
end

function ENT:ACF_Activate(Recalc)
	local Wall  = ACF.ContainerArmor * ACF.MmToInch
	local Shape = self.Shape or "Box"
	local ShapeCalc = ACF.ContainerShapes[Shape]
	local Size  = self.Size or (self.GetOriginalSize and self:GetOriginalSize())

	if not ShapeCalc or not Size then return end

	local _, SurfaceAreaIn2 = ShapeCalc(Size, Wall)
	local Area = SurfaceAreaIn2 * ACF.InchToCmSq -- convert to cm^2 to match damage model

	local Percent = 1
	if Recalc and self.ACF and self.ACF.Health and self.ACF.MaxHealth then
		Percent = self.ACF.Health / self.ACF.MaxHealth
	end

	self.ACF = self.ACF or {}

	local Armour = ACF.ContainerArmor * ACF.ArmorMod
	local Health = Area / ACF.Threshold

	self.ACF.Area      = Area
	self.ACF.Health    = Health * Percent
	self.ACF.MaxHealth = Health
	self.ACF.Armour    = Armour * (0.5 + Percent * 0.5)
	self.ACF.MaxArmour = Armour
	self.ACF.Type      = "Prop"
end

function ENT:OnResized(Size)
	local Wall = ACF.ContainerArmor * ACF.MmToInch
	local Shape = self.Shape or "Box"
	local _, SurfaceArea = ACF.ContainerShapes[Shape](Size, Wall)

	self.EmptyMass = (SurfaceArea * Wall) * ACF.InchToCmCu * ACF.SteelDensity
end

function ENT:VerifySize(Data, SizeKeyX, SizeKeyY, SizeKeyZ, DefaultSize)
	-- Size already provided
	if isvector(Data.Size) then return Data.Size end

	-- Build size from individual components
	local Min = ACF.ContainerMinSize or 6
	local Max = ACF.ContainerMaxSize or 96
	local Def = DefaultSize or (Min + Max) / 2

	local X = Clamp(ACF.CheckNumber(Data[SizeKeyX], Def), Min, Max)
	local Y = Clamp(ACF.CheckNumber(Data[SizeKeyY], Def), Min, Max)
	local Z = Clamp(ACF.CheckNumber(Data[SizeKeyZ], Def), Min, Max)

	return Vector(X, Y, Z)
end

-- Calculate volume, capacity, and empty mass from size
-- Returns: Volume (cu in), Capacity (liters), EmptyMass (kg)
function ENT:CalcVolumeAndCapacity(Size)
	local Wall  = ACF.ContainerArmor * ACF.MmToInch
	local Shape = self.Shape or "Box"
	local ShapeCalc = ACF.ContainerShapes[Shape]
	local Volume, Area = ShapeCalc(Size, Wall)

	local Capacity  = Volume * ACF.gCmToKgIn
	local EmptyMass = (Area * Wall) * ACF.InchToCmCu * ACF.SteelDensity

	return Volume, Capacity, EmptyMass
end