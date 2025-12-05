local ACF         = ACF
local Clamp       = math.Clamp
local HookRun     = hook.Run
local Classes     = ACF.Classes
local Utilities   = ACF.Utilities
local WireIO      = Utilities.WireIO
local Entities    = Classes.Entities
local FuelTanks   = Classes.FuelTanks
local FuelTypes   = Classes.FuelTypes
local ActiveTanks = ACF.FuelTanks


local Inputs = {
	"Active (If set to a non-zero value, it'll allow engines to consume fuel from this fuel tank.)",
}

local Outputs = {
	"Activated (Whether or not this fuel tank is able to be used by an engine.)",
	"Fuel (Amount of fuel currently in the tank, in liters or kWh)",
	"Capacity (Total amount of fuel the tank can hold, in liters or kWh)",
	"Leaking (Returns 1 if the fuel tank is currently losing fuel.)",
	"Entity (The fuel tank itself.) [ENTITY]"
}

local function VerifyData(Data)
	-- Build size from FuelSizeX/Y/Z
	local Class = FuelTanks.Get("FTS_S")
	local Min, Max = ACF.ContainerMinSize, ACF.ContainerMaxSize

	-- ACF-3/ACE backwards compatibility. Fuel size was saved as Size for a while in ACF-3, and ACE still saves it as SizeId.
	if (isvector(Data.Size) or isvector(Data.SizeId)) and (not Data.FuelSizeX or not Data.FuelSizeY or not Data.FuelSizeZ) then
		local SizeData = isvector(Data.SizeId) and "SizeId" or "Size"
		Data.FuelSizeX = Clamp(ACF.CheckNumber(Data[SizeData][1], 24), Min, Max)
		Data.FuelSizeY = Clamp(ACF.CheckNumber(Data[SizeData][2], 24), Min, Max)
		Data.FuelSizeZ = Clamp(ACF.CheckNumber(Data[SizeData][3], 24), Min, Max)

		Data.Size = Vector(Data.FuelSizeX, Data.FuelSizeY, Data.FuelSizeZ)

		if isstring(Data.FuelTank) then
			Data.FuelShape = Data.FuelTank == "Drum" and "Cylinder" or "Box"
		end
	-- Pre-scalable ACF-3 backwards compatibility for boxes. The X and Y values are swapped on purpose to match old tank models.
	elseif isstring(Data.FuelTank) and string.StartsWith(Data.FuelTank, "Tank_") then
		local TankSize = string.Split(string.TrimLeft(Data.FuelTank, "Tank_"), "x")
		local X = Clamp(ACF.CheckNumber(tonumber(TankSize[2]) * 10, 24), Min, Max)
		local Y = Clamp(ACF.CheckNumber(tonumber(TankSize[1]) * 10, 24), Min, Max)
		local Z = Clamp(ACF.CheckNumber(tonumber(TankSize[3]) * 10, 24), Min, Max)

		Data.Size = Vector(X, Y, Z)
	-- Pre-scalable ACF-3 backwards compatibility for fuel drums.
	elseif isstring(Data.FuelTank) and Data.FuelTank == "Fuel_Drum" then
		Data.FuelShape = "Cylinder"
		Data.Size = Vector(28, 28, 45)
	else
		local X = Clamp(ACF.CheckNumber(Data.FuelSizeX, 24), Min, Max)
		local Y = Clamp(ACF.CheckNumber(Data.FuelSizeY, 24), Min, Max)
		local Z = Clamp(ACF.CheckNumber(Data.FuelSizeZ, 24), Min, Max)

		Data.Size = Vector(X, Y, Z)
	end

	-- Ensure shape is set
	if not Data.FuelShape then Data.FuelShape = "Box" end

	-- Making sure to provide a valid fuel type
	if not FuelTypes.Get(Data.FuelType) then Data.FuelType = "Petrol" end

	do -- External verifications
		if Class.VerifyData then
			Class.VerifyData(Data, Class)
		end

		HookRun("ACF_OnVerifyData", "acf_fueltank", Data, Class)
	end
end

local function UpdateFuelTank(Entity, Data, Class, FuelType)
	-- If updating, keep the same fuel level
	local Percentage = Entity.Capacity and Entity.Amount / Entity.Capacity or 1

	-- Determine shape and model
	local Shape = Data.FuelShape or "Box"
	local Model = ACF.ContainerShapeModels[Shape]

	Entity.ACF = Entity.ACF or {}
	Entity.ACF.Model = Model
	Entity.ClassData = Class
	Entity.Shape = Shape -- Store shape on entity for volume calculations

	Entity:SetScaledModel(Model)
	Entity:SetSize(Data.Size)
	Entity:SetMaterial(Class.Material or "")

	-- Storing all the relevant information on the entity for duping
	for _, V in ipairs(Entity.DataStore) do
		Entity[V] = Data[V]
	end

	-- Calculate volume and capacity using base class method (uses Entity.Shape)
	local _, Capacity, EmptyMass = Entity:CalcVolumeAndCapacity(Data.Size)

	Entity.Name        = Entity.FuelType .. " Tank"
	Entity.ShortName   = Entity.FuelType
	Entity.EntType     = Class.Name
	Entity.FuelDensity = FuelType.Density
	Entity.Capacity    = Capacity -- Internal volume available for fuel in liters
	Entity.EmptyMass   = EmptyMass
	Entity.IsExplosive = Class.IsExplosive
	Entity.NoLinks     = Class.Unlinkable

	WireIO.SetupInputs(Entity, Inputs, Data, Class, FuelType)
	WireIO.SetupOutputs(Entity, Outputs, Data, Class, FuelType)

	Entity.WireAmountName = "Fuel" -- Use "Fuel" output instead of "Amount"

	if Entity.FuelType == "Electric" then
		Entity.Name     = "Electric Battery"
		Entity.Liters   = Entity.Capacity -- Batteries capacity is different from internal volume
		Entity.Capacity = Entity.Capacity * ACF.LiIonED
		Entity.UnitMass = FuelType.Density / ACF.LiIonED -- kg per kWh
	else
		Entity.UnitMass = FuelType.Density -- kg per liter
	end

	Entity:SetNWString("WireName", "ACF " .. Entity.Name)

	Entity.Amount = Percentage * Entity.Capacity

	ACF.Activate(Entity, true)

	Entity:UpdateMass(true)

	WireLib.TriggerOutput(Entity, "Fuel", Entity.Amount)
	WireLib.TriggerOutput(Entity, "Capacity", Entity.Capacity)
end

function ACF.MakeFuelTank(Player, Pos, Angle, Data)
	VerifyData(Data)

	local Class    = FuelTanks.Get("FTS_S")
	local FuelType = FuelTypes.Get(Data.FuelType)
	local Limit    = Class.LimitConVar.Name

	-- Determine model based on shape
	local Shape = Data.FuelShape or "Box"
	local Model = ACF.ContainerShapeModels[Shape]

	if not Player:CheckLimit(Limit) then return end

	local CanSpawn = HookRun("ACF_PreSpawnEntity", "acf_fueltank", Player, Data, Class)

	if CanSpawn == false then return end

	local Tank = ents.Create("acf_fueltank")

	if not IsValid(Tank) then return end

	Tank.ACF = Tank.ACF or {}

	Tank:SetScaledModel(Model)
	Tank:SetMaterial(Class.Material)
	Tank:SetAngles(Angle)
	Tank:SetPos(Pos)
	Tank:Spawn()

	Player:AddCleanup("acf_fueltank", Tank)
	Player:AddCount(Limit, Tank)

	Tank.Engines       = {}
	Tank.Leaking       = 0
	Tank.LastThink     = 0
	Tank.LastAmount    = 0
	Tank.LastActivated = 0
	Tank.DataStore     = Entities.GetArguments("acf_fueltank")

	duplicator.ClearEntityModifier(Tank, "mass")

	UpdateFuelTank(Tank, Data, Class, FuelType)

	if Class.OnSpawn then
		Class.OnSpawn(Tank, Data, Class)
	end

	HookRun("ACF_OnSpawnEntity", "acf_fueltank", Tank, Data, Class)

	-- Fuel tanks should be active by default
	Tank:TriggerInput("Active", 1)

	ActiveTanks[Tank] = true

	return Tank
end

Entities.Register("acf_fueltank", ACF.MakeFuelTank, "FuelTank", "FuelType", "FuelShape", "Size")

ACF.RegisterLinkSource("acf_fueltank", "Engines")

-- Wire input handler for Active
ACF.AddInputAction("acf_fueltank", "Active", function(Entity, Value)
	Entity.Active = tobool(Value)

	WireLib.TriggerOutput(Entity, "Activated", Entity.Active and 1 or 0)
end)


function ENT:Update(Data)
	VerifyData(Data)

	local Class    = FuelTanks.Get("FTS_S")
	local FuelType = FuelTypes.Get(Data.FuelType)
	local OldClass = self.ClassData
	local Feedback = ""

	local CanUpdate, Reason = HookRun("ACF_PreUpdateEntity", "acf_fueltank", self, Data, Class)

	if CanUpdate == false then return CanUpdate, Reason end

	if OldClass.OnLast then
		OldClass.OnLast(self, OldClass)
	end

	HookRun("ACF_OnEntityLast", "acf_fueltank", self, OldClass)

	ACF.SaveEntity(self)

	UpdateFuelTank(self, Data, Class, FuelType)

	ACF.RestoreEntity(self)

	if Class.OnUpdate then
		Class.OnUpdate(self, Data, Class)
	end

	HookRun("ACF_OnUpdateEntity", "acf_fueltank", self, Data, Class)

	if next(self.Engines) then
		local Fuel    = self.FuelType
		local NoLinks = self.NoLinks
		local Count, Total = 0, 0

		for Engine in pairs(self.Engines) do
			if NoLinks or not Engine.FuelTypes[Fuel] then
				self:Unlink(Engine)

				Count = Count + 1
			end

			Total = Total + 1
		end

		if Count == Total then
			Feedback = "\nUnlinked from all engines due to fuel type or model change."
		elseif Count > 0 then
			local Text = "\nUnlinked from %s out of %s engines due to fuel type or model change."

			Feedback = Text:format(Count, Total)
		end
	end

	return true, "Fuel tank updated successfully!" .. Feedback
end


do -- Overlay text
	function ENT:ACF_UpdateOverlayState(State)
		if self:CanConsume() then
			State:AddSuccess("Active")
		else
			State:AddWarning("Idle")
		end

		if self.Leaking > 0 then
			State:AddWarning("WARNING: Leaking!")
		end

		local FuelTypeID = self.FuelType
		local FuelType = Classes.FuelTypes.Get(FuelTypeID)

		State:AddKeyValue("Fuel Type", FuelTypeID)

		if FuelType and FuelType.FuelTankOverlay then
			FuelInfo = FuelType.FuelTankOverlay(self.Amount, State)
		else
			local FuelAmount = math.Round(self.Amount, 2)
			local FuelCapacity = math.Round(self.Capacity, 2)

			State:AddProgressBar("Remaining Fuel", FuelAmount, FuelCapacity, " L")
		end
	end
end

function ENT:OnRemove()
	local Class = self.ClassData

	if Class.OnLast then
		Class.OnLast(self, Class)
	end

	HookRun("ACF_OnEntityLast", "acf_fueltank", self, Class)

	for Engine in pairs(self.Engines) do
		self:Unlink(Engine)
	end

	ActiveTanks[self] = nil

	-- Call base class OnRemove for WireLib cleanup
	if self.BaseClass.OnRemove then
		self.BaseClass.OnRemove(self)
	end
end