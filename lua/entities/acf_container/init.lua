AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF         = ACF
local WireLib     = WireLib
local Contraption = ACF.Contraption
local TimerSimple = timer.Simple
local Clamp       = math.Clamp
local Max         = math.max
local Abs         = math.abs
local ENTITY      = FindMetaTable("Entity")

-- Mass follows the contents in steps rather than every change: each physics mass change costs a trip
-- through the mass detours and the engine
local MassStepShare = 0.01 -- Share of a full container's mass the contents may drift from its physics mass
local MassStepMin   = 1    -- kg
local MassSettle    = 1    -- Seconds without a change before any remaining drift is written

ENT.WireAmountName = "Amount" -- Default wire output name for amount (Can be aliased to "Fuel" or "Ammo" or whatever)

function ENT:GetUnitMass()
	-- Returns kg per unit (e.g., kg per round, kg per liter, kg per kWh)
	return self.UnitMass or 1
end

-- SelfTbl, where given, is the entity's table, for callers that run every tick: each field read on the
-- entity itself goes through its metatable

local function SettleMass(Entity)
	if not IsValid(Entity) then return end

	local SelfTbl = ENTITY.GetTable(Entity)
	local Wait    = SelfTbl.LastAmountChange + MassSettle - CurTime()

	if Wait > 0 then
		TimerSimple(Wait, function() SettleMass(Entity) end)

		return
	end

	SelfTbl.MassSettlePending = nil

	local Mass = Max(ACF.MinimumMass, SelfTbl.Amount * SelfTbl.GetUnitMass(Entity))

	if Mass ~= SelfTbl.ACF.Mass then Contraption.SetMass(Entity, Mass) end
end

function ENT:SetAmount(Amount, SelfTbl)
	SelfTbl = SelfTbl or ENTITY.GetTable(self)

	local Cap = SelfTbl.Capacity or 0
	local New = Clamp(Amount or 0, 0, Cap)
	local Now = CurTime()

	if New ~= SelfTbl.Amount then
		SelfTbl.LastAmountChange = Now

		-- The check below skips changes made soon after the last one, so the settle catches the last of them
		if not SelfTbl.MassSettlePending then
			SelfTbl.MassSettlePending = true

			TimerSimple(MassSettle, function() SettleMass(self) end)
		end
	end

	SelfTbl.Amount = New

	local TimeCheck = Now - (SelfTbl.LastInfoUpdate or 0) > 0.1
	local ValueCheck = Abs((SelfTbl.LastInfoAmount or 0) - New) > 0.001
	if TimeCheck and ValueCheck then
		if WireLib then
			WireLib.TriggerOutput(self, SelfTbl.WireAmountName, New)
		end

		SelfTbl.UpdateMass(self, false, SelfTbl)
		if SelfTbl.UpdateOverlay then self:UpdateOverlay() end
		SelfTbl.LastInfoUpdate = Now
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

--- Sets the physics mass to what the contents weigh, once they have drifted a step from it
--- @param Instant boolean? # Set it even if unchanged, as after a resize, whose new physics object starts at 1 kg
--- @param SelfTbl table? # The entity's table
function ENT:UpdateMass(Instant, SelfTbl)
	SelfTbl = SelfTbl or ENTITY.GetTable(self)

	local Amount   = SelfTbl.Amount
	local UnitMass = SelfTbl.GetUnitMass(self)
	local Mass     = Max(ACF.MinimumMass, Amount * UnitMass)

	if not Instant then
		local Current = SelfTbl.ACF.Mass

		if Current == Mass then return end

		-- Empty and full are written as they happen, so a container never rests a step off either
		local Capacity = SelfTbl.Capacity or 0
		local Step     = Max(MassStepMin, MassStepShare * Capacity * UnitMass)

		if Current and Abs(Mass - Current) < Step and Amount > 0 and Amount < Capacity then return end
	end

	Contraption.SetMass(self, Mass)
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