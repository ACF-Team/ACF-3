local ACF         = ACF
local Classes     = ACF.Classes
local ActiveTanks = ACF.FuelTanks

local DefaultTank = "ACF.FuelTanks.ScalableFuelTank"
local DefaultShape = "ACF.ContainerShapes.Box"

do -- Spawning
	-- ClientData values may be an FQN string (menu) or a serialized {Type=...} table (dupe).
	local function ResolveType(Value, Default)
		local Name = istable(Value) and Value.Type or Value
		return Classes.GetTypeByName(Name) or Classes.GetTypeByName(Default)
	end

	function ENT:ACF_PreSpawn(_, _, _, ClientData)
		local ShapeClass = ResolveType(ClientData.Shape, DefaultShape)

		self:SetScaledModel(ShapeClass.Model)

		local TankClass = ResolveType(ClientData.FuelTank, DefaultTank)

		self:SetMaterial(TankClass.Material)
	end

	function ENT:ACF_OnSpawn()
		self.Engines       = {}
		self.Leaking       = 0
		self.LastThink     = 0
		self.LastAmount    = 0
		self.LastActivated = 0

		duplicator.ClearEntityModifier(self, "mass")
	end

	function ENT:ACF_PostSpawn(_, _, _, ClientData)
		local TankClass = ResolveType(ClientData.FuelTank, DefaultTank)

		if TankClass.OnSpawn then
			TankClass.OnSpawn(self, ClientData, TankClass)
		end

		-- Fuel tanks should be active by default
		self:TriggerInput("Active", 1)

		ActiveTanks[self] = true
	end
end

do -- Updating
	function ENT:ACF_OnEntityLast()
		local Class = self.ClassData

		if Class and Class.OnLast then
			Class.OnLast(self, Class)
		end
	end

	function ENT:ACF_OnUpdateEntityData()
		-- If updating, keep the same fuel level
		local Percentage = self.Capacity and self.Amount / self.Capacity or 1

		-- Determine shape and model
		local Shape = self:ACF_GetUserVar("Shape")
		local Model = Shape.Model

		local FuelTypeInstance  = self:ACF_GetUserVar("FuelType")
		local FuelTypeClass		= FuelTypeInstance and FuelTypeInstance:GetType() or Classes.GetTypeByName(DefaultTank)
		local FuelTypeName		= Classes.GetTypeName(FuelTypeClass)

		local FuelTankInstance  = self:ACF_GetUserVar("FuelTank")
		local FuelTankClass		= FuelTankInstance and FuelTankInstance:GetType() or Classes.GetTypeByName(DefaultTank)

		local TankSize  = self:ACF_GetUserVar("Size")

		self.ACF.Model = Model
		self:SetScaledModel(Model)
		self:SetSize(TankSize)
		self:SetMaterial(FuelTankClass.Material or "")

		-- Calculate volume and capacity using base class method (uses Entity.Shape)
		local _, Capacity, EmptyMass = self:CalcVolumeAndCapacity(TankSize)

		self.Name        = FuelTypeClass.Name .. " Tank"
		self.ShortName   = FuelTypeClass.ShortName
		self.EntType     = FuelTypeName
		self.FuelDensity = FuelTypeClass.Density
		self.Capacity    = Capacity -- Internal volume available for fuel in liters
		self.EmptyMass   = EmptyMass
		self.NoLinks     = FuelTypeName.Unlinkable

		self.WireAmountName = "Fuel" -- Use "Fuel" output instead of "Amount"

		if FuelTypeName == "ACF.FuelTypes.Electric" then
			self.Name     = "Electric Battery"
			self.Liters   = self.Capacity -- Batteries capacity is different from internal volume
			self.Capacity = self.Capacity * ACF.LiIonED
			self.UnitMass = FuelTypeClass.Density / ACF.LiIonED -- kg per kWh
		else
			self.UnitMass = FuelTypeClass.Density -- kg per liter
		end

		self:SetNWString("WireName", "ACF " .. self.Name)

		self.Amount = Percentage * self.Capacity

		self:UpdateMass(true)

		WireLib.TriggerOutput(self, "Fuel", self.Amount)
		WireLib.TriggerOutput(self, "Capacity", self.Capacity)

		if FuelTypeClass.OnUpdate then
			FuelTypeClass.OnUpdate(self, Data, Class)
		end
	end

	function ENT:ACF_PostUpdateEntityData()
		local Feedback = ""

		if next(self.Engines) then
			local Fuel    = Classes.GetTypeName(self:ACF_GetUserVar("FuelType"):GetType())
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

		return Feedback
	end
end

ACF.RegisterLinkSource("acf_fueltank", "Engines")

-- Wire input handler for Active
ACF.AddInputAction("acf_fueltank", "Active", function(Entity, Value)
	Entity.Active = tobool(Value)

	WireLib.TriggerOutput(Entity, "Activated", Entity.Active and 1 or 0)
end)

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

		local FuelTypeInstance = self:ACF_GetUserVar("FuelType")
		State:AddKeyValue("Fuel Type", FuelTypeInstance.Name)

		if FuelTypeInstance and FuelTypeInstance.FuelTankOverlay then
			FuelInfo = FuelTypeInstance.FuelTankOverlay(self.Amount, State)
		else
			local FuelAmount = math.Round(self.Amount, 2)
			local FuelCapacity = math.Round(self.Capacity, 2)

			State:AddProgressBar("Remaining Fuel", FuelAmount, FuelCapacity, " L")
		end
	end
end

function ENT:OnRemove()
	for Engine in pairs(self.Engines) do
		self:Unlink(Engine)
	end

	ActiveTanks[self] = nil
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

			if next(Entity.Engines) then
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