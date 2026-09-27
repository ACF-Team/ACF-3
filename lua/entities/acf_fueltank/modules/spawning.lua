local ACF         = ACF
local Classes     = ACF.Classes
local WireLib     = WireLib
local ActiveTanks = ACF.FuelTanks
local Fuel        = ACF.Mobility.Fuel

local TANK_MATERIAL = "models/props_canal/metalcrate001d"

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
		self:TriggerInput("Active", 1)
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
		-- Publish the fuel type FQN so engine fuel compatibility checks (keyed by FQN) resolve.
		self.FuelType    = Classes.GetTypeName(FuelType:GetType())
		self.FuelDensity = FuelType.Density
		self.ConvexMaterial = FuelType.ArmorType or "RHA" -- Convex armor type defaults to this fuel's material
		self.IsExplosive = FuelType.IsExplosive
		self.IsElectric  = FuelType.IsElectric
		self.FuelPriority = self:ACF_GetUserVar("FuelPriority")
		self.EntType     = "Fuel Tank"
		self.Name        = FuelID .. " Tank"
		self.ShortName   = FuelID
		self.WireAmountName = "Fuel"

		local _, Capacity = self:CalcVolumeAndCapacity(Size)

		self.Capacity = Capacity -- Internal volume available for fuel in liters

		if FuelType.IsElectric then
			self.Name     = "Electric Battery"
			self.Liters   = Capacity -- Batteries' capacity is different from internal volume
			self.Capacity = Capacity * ACF.LiIonED
			self.UnitMass = FuelType.Density / ACF.LiIonED -- kg per kWh
		else
			self.UnitMass = FuelType.Density -- kg per liter
		end

		self:ACF_SetEntityName("ACF " .. self.Name)

		self.Amount = Percentage * self.Capacity

		self:UpdateMass(true)

		WireLib.TriggerOutput(self, "Fuel", self.Amount)
		WireLib.TriggerOutput(self, "Capacity", self.Capacity)

		-- Fuel type or priority may have changed (no-op on a fresh spawn, which isn't parented yet)
		if self.ACF_FuelParent then Fuel.Join(self) end
	end

	function ENT:CFW_OnParentedTo()
		Fuel.Join(self)
	end
end

ACF.RegisterLinkSource("acf_fueltank", "Engines")

-- Wire input handler for Active
ACF.AddInputAction("acf_fueltank", "Active", function(Entity, Value)
	Entity.Active = tobool(Value)

	WireLib.TriggerOutput(Entity, "Activated", Entity.Active and 1 or 0)

	if Entity.Active then Fuel.Notify(Entity) end
end)

function ENT:SetAmount(Amount)
	local WasEmpty = (self.Amount or 0) <= 0

	self.BaseClass.SetAmount(self, Amount)

	if WasEmpty and self.Amount > 0 then Fuel.Notify(self) end
end

function ENT:Enable()
	self.BaseClass.Enable(self)

	Fuel.Notify(self)
end

-- Remove-only teardown. Captured by AutoRegisterV2 as OrigOnRemove; the generated OnRemove still
-- runs ACF_OnEntityLast + WireLib cleanup around this.
function ENT:OnRemove(IsFullUpdate)
	if IsFullUpdate then return end

	Fuel.Leave(self)

	ActiveTanks[self] = nil
end

do -- Overlay text
	function ENT:ACF_UpdateOverlayState(State)
		if self.ACF.Health == 0 then
			State:AddError("Destroyed")
		elseif self:CanConsume() then
			State:AddSuccess("Active")
		else
			State:AddWarning("Idle")
		end

		if self.Leaking and self.Leaking > 0 then
			State:AddWarning("WARNING: Leaking!")
		end

		-- The V2 fuel type instance lives on the entity's field set; read it straight off.
		local FuelType = self:ACF_GetUserVar("FuelType")

		State:AddKeyValue("Fuel Type", FuelType and FuelType.ID or self.FuelType)
		State:AddNumber("Priority", self.FuelPriority)

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
