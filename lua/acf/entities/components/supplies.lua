local ACF        = ACF
local Classes    = ACF.Classes
local GetType    = Classes.GetTypeByName

local Classes   = ACF.Classes

Classes.DefineClass("ACF.Components.SupplyCrate", "ACF.Components.BaseComponent", function()
	CLASS.Name        = "Supply Crate"
	CLASS.Description = "A scalable container that supplies fuel and ammo."
	CLASS.Model       = "models/acf/core/s_fuel.mdl"
	CLASS.Material    = "phoenix_storms/future_vents"
	CLASS.Preview = {FOV = 120}
	CLASS.Entity = "acf_supply"
	CLASS.TutorialURL = "docs/acf_tutorials/refills.html"
	CLASS.LimitConVar = {
		Name   = "_acf_supply",
		Amount = 4,
		Text   = "Maximum amount of ACF Supply crates a player can create."
	}
	function CLASS.CreateMenu(_, Menu, Ctx)
		-- Shape selector. The combo value is the ContainerShapes class FQN written straight into the
		-- "Shape" field; no string->class translation needed at spawn time.
		local SupplyShape = Menu:AddComboBox()

		SupplyShape:AddChoice("Box", "ACF.ContainerShapes.Box")
		SupplyShape:AddChoice("Sphere", "ACF.ContainerShapes.Sphere")
		SupplyShape:AddChoice("Cylinder", "ACF.ContainerShapes.Cylinder")

		-- Current shape (a live ContainerShapes instance on the context), as an FQN.
		local ShapeInst    = Ctx:Get("Shape")
		local SelectedShape = (ShapeInst and ShapeInst.GetType) and Classes.GetTypeName(ShapeInst:GetType()) or "ACF.ContainerShapes.Box"

		-- Live capacity and rate preview label
		local CapacityLabel = Menu:AddLabel("")

		-- Size sliders
		local Min = ACF.ContainerMinSize
		local Max = ACF.ContainerMaxSize

		local SupplySize = Vector(Ctx:Get("SupplySizeX") or 24, Ctx:Get("SupplySizeY") or 24, Ctx:Get("SupplySizeZ") or 24)

		local function UpdateSupplyText()
			local Wall    = ACF.ContainerArmor * ACF.MmToInch
			local Current = Ctx:Get("Shape")
			local Shape   = (Current and Current.GetType) and Current:GetType() or GetType("ACF.ContainerShapes.Box")

			local Volume, Area = Shape.ShapeCalculation(SupplySize, Wall)

			local Capacity = Volume * ACF.gCmToKgIn
			local EmptyMass = Area * Wall * ACF.InchToCmCu * ACF.SteelDensity
			local TransferRate = ACF.SupplyMassRate * (Volume / 1000)

			CapacityLabel:SetText(string.format("Capacity : %s kg\nEmpty Mass : %s kg\nTransfer Rate : %s kg/s", math.Round(Capacity, 2), math.Round(EmptyMass, 2), math.Round(TransferRate, 2)))

			if Menu.ComponentPreview then
				Menu.ComponentPreview:SetModelScale(SupplySize)
			end
		end

		function SupplyShape:OnSelect(_, _, Data)
			local ShapeClass = GetType(Data) or GetType("ACF.ContainerShapes.Box")

			if Menu.ComponentPreview then
				Menu.ComponentPreview:UpdateModel(ShapeClass.Model, "phoenix_storms/future_vents")
			end

			Ctx:Set("Shape", Data)
			UpdateSupplyText()
		end
		SupplyShape:ChooseOptionID(SelectedShape == "ACF.ContainerShapes.Sphere" and 2 or SelectedShape == "ACF.ContainerShapes.Cylinder" and 3 or 1)

		local SizeX = Menu:AddSlider("Length", Min, Max)
		function SizeX:OnValueChanged(Value)
			local X = math.Round(Value)
			self:SetValue(X)
			SupplySize.x = X
			UpdateSupplyText()
			Ctx:Set("SupplySizeX", X)
		end
		SizeX:SetValue(SupplySize.x)

		local SizeY = Menu:AddSlider("Width", Min, Max)
		function SizeY:OnValueChanged(Value)
			local Y = math.Round(Value)
			self:SetValue(Y)
			SupplySize.y = Y
			UpdateSupplyText()
			Ctx:Set("SupplySizeY", Y)
		end
		SizeY:SetValue(SupplySize.y)

		local SizeZ = Menu:AddSlider("Height", Min, Max)
		function SizeZ:OnValueChanged(Value)
			local Z = math.Round(Value)
			self:SetValue(Z)
			SupplySize.z = Z
			UpdateSupplyText()
			Ctx:Set("SupplySizeZ", Z)
		end
		SizeZ:SetValue(SupplySize.z)

		-- Initialize preview with defaults
		UpdateSupplyText()
	end
end)