AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF         = ACF
local WireLib     = WireLib
local Contraption = ACF.Contraption
local TimerCreate = timer.Create
local TimerExists = timer.Exists
local Clamp       = math.Clamp
local ENTITY      = FindMetaTable("Entity")

ENT.WireAmountName = "Amount" -- Default wire output name for amount (Can be aliased to "Fuel" or "Ammo" or whatever)

function ENT:GetUnitMass()
	-- Returns kg per unit (e.g., kg per round, kg per liter, kg per kWh)
	return self.UnitMass or 1
end

-- SelfTbl, where given, is the entity's table, for callers that run every tick: each field read on the
-- entity itself goes through its metatable

function ENT:SetAmount(Amount, SelfTbl)
	SelfTbl = SelfTbl or ENTITY.GetTable(self)

	local Cap = SelfTbl.Capacity or 0
	local New = Clamp(Amount or 0, 0, Cap)

	SelfTbl.Amount = New

	local TimeCheck = CurTime() - (SelfTbl.LastInfoUpdate or 0) > 0.1
	local ValueCheck = math.abs((SelfTbl.LastInfoAmount or 0) - New) > 0.001
	if TimeCheck and ValueCheck then
		if WireLib then
			WireLib.TriggerOutput(self, SelfTbl.WireAmountName, New)
		end

		self:UpdateMass()
		if SelfTbl.UpdateOverlay then self:UpdateOverlay() end
		SelfTbl.LastInfoUpdate = CurTime()
		SelfTbl.LastInfoAmount = New
	end
end

function ENT:Consume(Amount, SelfTbl)
	SelfTbl = SelfTbl or ENTITY.GetTable(self)

	SelfTbl.SetAmount(self, SelfTbl.Amount - Amount, SelfTbl)
end

function ENT:CanConsume(SelfTbl)
	SelfTbl = SelfTbl or ENTITY.GetTable(self)

	if not ACF.IsOperational(self, SelfTbl) then return false end
	if not SelfTbl.Active then return false end

	return SelfTbl.Amount > 0
end

function ENT:UpdateMass(Instant)
	if Instant then
		local NewMass = math.max(ACF.MinimumMass, self.Amount * self:GetUnitMass())
		Contraption.SetMass(self, NewMass)
		return
	end

	local ID = "ACF Mass Buffer " .. self:EntIndex()

	if TimerExists(ID) then return end

	TimerCreate(ID, 0, 1, function()
		if not IsValid(self) then return end
		local NewMass = math.max(ACF.MinimumMass, self.Amount * self:GetUnitMass())
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

-- Calculate volume and capacity from size
-- Returns: Volume (cu in), Capacity (liters)
function ENT:CalcVolumeAndCapacity(Size)
	local Shape = self:ACF_GetUserVar("Shape")
	local ShapeCalc = Shape and Shape.ShapeCalculation
	if not ShapeCalc then return 0, 0 end

	local Volume = ShapeCalc(Size)

	local Capacity = Volume * ACF.gCmToKgIn

	return Volume, Capacity
end