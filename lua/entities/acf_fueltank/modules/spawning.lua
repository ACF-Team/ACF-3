local ACF         = ACF
local Classes     = ACF.Classes
local WireLib     = WireLib
local ActiveTanks = ACF.FuelTanks

local FUELTYPE_BASE = "ACF.FuelTypes.FuelType"
local TANK_MATERIAL = "models/props_canal/metalcrate001d"

-- Resolves a FuelType client-data value (legacy short id, class FQN string, or {Type=} table)
-- to a ContainerShapes-style class FQN. Falls back to Petrol.
local function ResolveFuelType(Value)
	if istable(Value) and Value.Type then Value = Value.Type end
	if Classes.GetTypeByName(Value) then return Value end -- Already a FQN

	for _, Class in ipairs(Classes.GetSubtypes(FUELTYPE_BASE)) do
		if Class.ID == Value then return Classes.GetTypeName(Class) end
	end

	return "ACF.FuelTypes.Petrol"
end

-- Runs on raw client/dupe data before serialization. Resolves the FuelType short ID into a class
-- FQN. Shape (FQN) and the FuelSizeX/Y/Z fields come straight from the menu / compat patch, so no
-- shape/size translation happens here.
function ENT.ACF_OnVerifyClientData(ClientData)
	ClientData.FuelType = ResolveFuelType(ClientData.FuelType)
end

do -- Spawning
	function ENT:ACF_PreSpawn(_, _, _, ClientData)
		self.ACF = {}

		local ShapeClass = Classes.GetTypeByName(ClientData.Shape) or Classes.GetTypeByName("ACF.ContainerShapes.Box")
		local Model      = ShapeClass.Model

		self.ACF.Model = Model

		self:SetMaterial(TANK_MATERIAL)
		self:SetScaledModel(Model)
	end

	function ENT:ACF_OnSpawn()
		self.Engines       = {}
		self.Leaking       = 0
		self.LastThink     = 0
		self.LastAmount    = 0
		self.LastActivated = 0

		duplicator.ClearEntityModifier(self, "mass")

		ActiveTanks[self] = true
	end

	function ENT:ACF_PostSpawn()
		-- Fuel tanks should be active by default.
		self:TriggerInput("Active", 1)
		WireLib.TriggerOutput(self, "Entity", self)
	end
end

do -- Updating
	function ENT:ACF_PostUpdateEntityData()
		self.ACF = self.ACF or {}

		local FuelType = self:ACF_GetUserVar("FuelType")
		local Shape    = self:ACF_GetUserVar("Shape")
		local Size     = Vector(
			self:ACF_GetUserVar("FuelSizeX"),
			self:ACF_GetUserVar("FuelSizeY"),
			self:ACF_GetUserVar("FuelSizeZ")
		)
		local Model    = (Shape and Shape.Model) or "models/acf/core/s_fuel.mdl"

		-- Keep the current fuel level proportionally when reconfiguring an existing tank.
		local Percentage = (self.Capacity and self.Amount) and (self.Amount / self.Capacity) or 1

		self.ACF.Model = Model
		self:SetScaledModel(Model)
		self:SetSize(Size)
		self:SetMaterial(TANK_MATERIAL)

		local FuelID = FuelType.ID

		-- Fields the (still legacy) engine link code + E2/SF read directly.
		self.FuelType    = FuelID
		self.FuelDensity = FuelType.Density
		self.IsExplosive = FuelType.IsExplosive
		self.NoLinks     = false
		self.EntType     = "Fuel Tank"
		self.Name        = FuelID .. " Tank"
		self.ShortName   = FuelID
		self.WireAmountName = "Fuel"

		local _, Capacity, EmptyMass = self:CalcVolumeAndCapacity(Size)

		self.Capacity  = Capacity -- Internal volume available for fuel in liters
		self.EmptyMass = EmptyMass

		if FuelType.IsElectric then
			self.Name     = "Electric Battery"
			self.Liters   = Capacity -- Batteries' capacity is different from internal volume
			self.Capacity = Capacity * ACF.LiIonED
			self.UnitMass = FuelType.Density / ACF.LiIonED -- kg per kWh
		else
			self.UnitMass = FuelType.Density -- kg per liter
		end

		self:SetNWString("WireName", "ACF " .. self.Name)

		self.Amount = Percentage * self.Capacity

		self:UpdateMass(true)

		WireLib.TriggerOutput(self, "Fuel", self.Amount)
		WireLib.TriggerOutput(self, "Capacity", self.Capacity)

		-- Unlink engines that can no longer use this fuel type / model.
		if self.Engines and next(self.Engines) then
			for Engine in pairs(self.Engines) do
				if self.NoLinks or not Engine.FuelTypes[self.FuelType] then
					self:Unlink(Engine)
				end
			end
		end
	end
end

ACF.RegisterLinkSource("acf_fueltank", "Engines")

-- Wire input handler for Active
ACF.AddInputAction("acf_fueltank", "Active", function(Entity, Value)
	Entity.Active = tobool(Value)

	WireLib.TriggerOutput(Entity, "Activated", Entity.Active and 1 or 0)
end)

-- Remove-only teardown. Captured by AutoRegisterV2 as OrigOnRemove; the generated OnRemove still
-- runs ACF_OnEntityLast + WireLib cleanup around this.
function ENT:OnRemove(IsFullUpdate)
	if IsFullUpdate then return end

	if self.Engines then
		for Engine in pairs(self.Engines) do
			self:Unlink(Engine)
		end
	end

	ActiveTanks[self] = nil
end

do -- Overlay text
	function ENT:ACF_UpdateOverlayState(State)
		if self:CanConsume() then
			State:AddSuccess("Active")
		else
			State:AddWarning("Idle")
		end

		if self.Leaking and self.Leaking > 0 then
			State:AddWarning("WARNING: Leaking!")
		end

		local FuelTypeID = self.FuelType
		local FuelType   = Classes.FuelTypes.Get(FuelTypeID)

		State:AddKeyValue("Fuel Type", FuelTypeID)

		if FuelType and FuelType.FuelTankOverlay then
			FuelType.FuelTankOverlay(self.Amount, State)
		else
			local FuelAmount   = math.Round(self.Amount, 2)
			local FuelCapacity = math.Round(self.Capacity, 2)

			State:AddProgressBar("Remaining Fuel", FuelAmount, FuelCapacity, " L")
		end
	end
end

do	-- NET SURFER 2.0
	util.AddNetworkString("ACF_RequestFuelTankInfo")
	util.AddNetworkString("ACF_InvalidateFuelTankInfo")

	function ENT:InvalidateClientInfo()
		net.Start("ACF_InvalidateFuelTankInfo")
			net.WriteEntity(self)
		net.Broadcast()
	end

	net.Receive("ACF_RequestFuelTankInfo", function(_, Ply)
		local Entity = net.ReadEntity()

		if IsValid(Entity) then
			local Engines = {}

			if Entity.Engines and next(Entity.Engines) then
				for E in pairs(Entity.Engines) do
					Engines[#Engines + 1] = E:EntIndex()
				end
			end

			net.Start("ACF_RequestFuelTankInfo")
				net.WriteEntity(Entity)
				net.WriteUInt(#Engines, 6)

				if next(Engines) then
					for _, E in ipairs(Engines) do
						net.WriteUInt(E, MAX_EDICT_BITS)
					end
				end
			net.Send(Ply)
		end
	end)
end
