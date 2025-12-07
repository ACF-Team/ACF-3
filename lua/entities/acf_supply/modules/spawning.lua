local ACF       = ACF
local Utilities = ACF.Utilities
local Classes   = ACF.Classes
local WireLib   = WireLib
local Entities  = Classes.Entities
local WireIO    = Utilities.WireIO
local Round     = math.Round
local HookRun   = hook.Run

local Inputs = {
	"Active (If set to a non-zero value, it will allow this unit to supply mass.)",
}

local Outputs = {
	"Activated (Whether or not this unit can supply mass.)",
	"Amount (Current mass stored, in kilograms)",
	"Capacity (Total mass capacity, in kilograms)",
	"Entity (The supply entity itself.) [ENTITY]",
}

ACF.AddInputAction("acf_supply", "Active", function(Entity, Value)
	local Active = tobool(Value)

	if Entity.Active ~= Active then
		Entity.Active = Active

		if Active then
			Entity:Enable()
		else
			Entity:Disable()
		end
	end
end)

local function VerifyData(Data)
	local X = ACF.CheckNumber(Data.SupplySizeX, 24)
	local Y = ACF.CheckNumber(Data.SupplySizeY, 24)
	local Z = ACF.CheckNumber(Data.SupplySizeZ, 24)

	Data.Size = Vector(X, Y, Z)

	if not Data.SupplyShape then Data.SupplyShape = "Box" end

	if not ACF.ContainerShapeModels[Data.SupplyShape] then
		Data.SupplyShape = "Box"
	end

	HookRun("ACF_OnVerifyData", "acf_supply", Data)
end

local function UpdateSupply(Entity, Data)
	local Percentage = Entity.Capacity and Entity.Amount / Entity.Capacity or 1

	Entity.ACF = Entity.ACF or {}
	local Model = Entity.ACF.Model or Data.Model or "models/holograms/hq_rcube_thin.mdl"
	Entity.ACF.Model = Model

	-- Clamp and verify size via base helper
	Data.Size = Entity:VerifySize(Data, "SupplySizeX", "SupplySizeY", "SupplySizeZ", 24)

	Entity:SetScaledModel(Model)
	Entity:SetSize(Data.Size or Entity:GetOriginalSize())

	Entity.DataStore = Entities.GetArguments("acf_supply")
	for _, V in ipairs(Entity.DataStore) do
		Entity[V] = Data[V]
	end

	local Volume, Capacity, EmptyMass = Entity:CalcVolumeAndCapacity(Data.Size)

	Entity.Volume    = Volume
	Entity.Capacity  = Capacity
	Entity.EmptyMass = EmptyMass

	WireIO.SetupInputs(Entity, Inputs, Data)
	WireIO.SetupOutputs(Entity, Outputs, Data)

	Entity:SetNWString("WireName", "ACF Supply Crate")

	ACF.Activate(Entity, true)

	Entity:SetAmount(Percentage * Capacity)

	WireLib.TriggerOutput(Entity, "Capacity", Round(Entity.Capacity, 2))
	WireLib.TriggerOutput(Entity, "Entity", Entity)
	WireLib.TriggerOutput(Entity, "Activated", Entity:CanConsume() and 1 or 0)
end

function ACF.MakeSupply(Player, Pos, Angle, Data)
	VerifyData(Data)

	local Limit = "_acf_supply"
	local Shape = Data.SupplyShape or "Box"
	local Model = ACF.ContainerShapeModels[Shape]

	if Player.CheckLimit and not Player:CheckLimit(Limit) then return end

	local CanSpawn = HookRun("ACF_PreSpawnEntity", "acf_supply", Player, Data)
	if CanSpawn == false then return false end

	local Supply = ents.Create("acf_supply")
	if not IsValid(Supply) then return end

	Supply.ACF = Supply.ACF or {}
	Supply.ACF.Model = Model
	Supply.Shape = Shape

	Supply:SetMaterial("phoenix_storms/Future_vents")
	Supply:SetScaledModel(Model)
	Supply:SetAngles(Angle)
	Supply:SetPos(Pos)
	Supply:Spawn()

	if Player.AddCleanup then Player:AddCleanup("acf_supply", Supply) end
	if Player.AddCount then Player:AddCount(Limit, Supply) end

	Supply.DataStore   = Entities.GetArguments("acf_supply")
	Supply.LastThink   = 0
	Supply.MassBuffers = {}

	UpdateSupply(Supply, Data)

	HookRun("ACF_OnSpawnEntity", "acf_supply", Supply, Data)

	Supply:TriggerInput("Active", 1)

	WireLib.TriggerOutput(Supply, "Entity", Supply)

	return Supply
end

Entities.Register("acf_supply", ACF.MakeSupply, "SupplyShape", "SupplySizeX", "SupplySizeY", "SupplySizeZ", "Size", "Amount")

function ENT:Update(Data)
	VerifyData(Data)
	-- Clamp and verify size via base helper for updates
	Data.Size = self:VerifySize(Data, "SupplySizeX", "SupplySizeY", "SupplySizeZ", 24)

	local Shape = Data.SupplyShape
	if Shape ~= self.Shape then
		self.Shape = Shape
		local Model = ACF.ContainerShapeModels[Shape]
		self:SetScaledModel(Model)
	end

	local Volume, Capacity, EmptyMass = self:CalcVolumeAndCapacity(Data.Size)
	local Percentage = self.Capacity and self.Amount / self.Capacity or 1

	self.Volume    = Volume
	self.Capacity  = Capacity
	self.EmptyMass = EmptyMass

	self:SetSize(Data.Size)

	self:SetAmount(Percentage * Capacity)

	WireLib.TriggerOutput(self, "Capacity", Round(self.Capacity, 2))

	return true, "Supply crate updated successfully!"
end

do
	function ENT:ACF_UpdateOverlayState(State)
		State:AddLabel(self:CanConsume() and "Supplying" or "Idle")
		State:AddProgressBar("Mass Remaining", Round(self.Amount or 0, 2), Round(self.Capacity or 0, 2), " kg", 2)
	end
end