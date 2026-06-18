local ACF       = ACF
local Classes   = ACF.Classes
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

do -- Spawning
	function ENT:ACF_PreSpawn(_, _, _, ClientData)
		self.ACF = {}

		-- ClientData.Shape is the raw FQN string; the "Shape" field defaults to Box server-side.
		local ShapeClass = Classes.GetTypeByName(ClientData.Shape) or Classes.GetTypeByName("ACF.ContainerShapes.Box")
		local Model      = ShapeClass.Model or ACF.ContainerShapeModels.Box

		self.Shape     = ShapeClass.Name
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
		local Shape     = self:ACF_GetUserVar("Shape")
		local ShapeName = (Shape and Shape.Name) or "Box"
		local Model     = (Shape and Shape.Model) or ACF.ContainerShapeModels[ShapeName] or ACF.ContainerShapeModels.Box

		self.Shape     = ShapeName
		self.ACF.Model = Model
		self:SetScaledModel(Model)
		local Size = self:ACF_GetUserVar("Size")

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
