local ACF       = ACF
local WireLib   = WireLib
local Round     = math.Round

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

-- Runs on raw client/dupe data before serialization (replaces the legacy VerifyData).
function ENT.ACF_OnVerifyClientData(ClientData)
	if not ClientData.SupplyShape or not ACF.ContainerShapeModels[ClientData.SupplyShape] then
		ClientData.SupplyShape = "Box"
	end
end

do -- Spawning
	function ENT:ACF_PreSpawn(_, _, _, ClientData)
		self.ACF = {}

		local Shape = ClientData.SupplyShape
		if not ACF.ContainerShapeModels[Shape] then Shape = "Box" end

		local Model = ACF.ContainerShapeModels[Shape]

		self.Shape     = Shape
		self.ACF.Model = Model

		self:SetMaterial("phoenix_storms/Future_vents")
		self:SetScaledModel(Model)
	end

	function ENT:ACF_OnSpawn()
		self.LastThink   = 0
		self.MassBuffers = {}
	end

	function ENT:ACF_PostSpawn()
		self:TriggerInput("Active", 1)
		WireLib.TriggerOutput(self, "Entity", self)
	end
end

do -- Updating
	function ENT:ACF_PostUpdateEntityData()
		local Shape = self:ACF_GetUserVar("SupplyShape")
		if not ACF.ContainerShapeModels[Shape] then Shape = "Box" end

		local Model = ACF.ContainerShapeModels[Shape]

		self.Shape     = Shape
		self.ACF.Model = Model
		self:SetScaledModel(Model)

		local Size = Vector(
			self:ACF_GetUserVar("SupplySizeX") or 24,
			self:ACF_GetUserVar("SupplySizeY") or 24,
			self:ACF_GetUserVar("SupplySizeZ") or 24
		)

		self:SetSize(Size)

		local OldCapacity = self.Capacity
		local Volume, Capacity, EmptyMass = self:CalcVolumeAndCapacity(Size)

		self.Volume    = Volume
		self.Capacity  = Capacity
		self.EmptyMass = EmptyMass

		-- Preserve the current fill ratio when resizing an existing crate;
		-- fresh and duped crates spawn full (matches the legacy behaviour).
		local Percentage = (OldCapacity and self.Amount) and (self.Amount / OldCapacity) or 1
		self:SetAmount(Percentage * Capacity)

		self:SetNWString("WireName", "ACF Supply Crate")

		-- ACF.Activate(self, true) is invoked automatically by ACF_UpdateEntityData after this.

		WireLib.TriggerOutput(self, "Capacity", Round(self.Capacity, 2))
		WireLib.TriggerOutput(self, "Entity", self)
		WireLib.TriggerOutput(self, "Activated", self:CanConsume() and 1 or 0)
	end
end

do -- Overlay
	function ENT:ACF_UpdateOverlayState(State)
		State:AddLabel(self:CanConsume() and "Supplying" or "Idle")
		local SizeX, SizeY, SizeZ = self:GetSize():Unpack()
		State:AddSize("Size", SizeX, SizeY, SizeZ)
		State:AddProgressBar("Mass Remaining", Round(self.Amount or 0, 2), Round(self.Capacity or 0, 2), " kg", 2)
	end
end
