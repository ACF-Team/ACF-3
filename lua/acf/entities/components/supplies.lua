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
	function CLASS.CreateMenu(_, Menu)
		-- Shape selector. The combo value is the ContainerShapes class FQN written straight into the
		-- "Shape" field; no string->class translation needed at spawn time.
		local SupplyShape = Menu:AddComboBox()

		SupplyShape:AddChoice("Box", "ACF.ContainerShapes.Box")
		SupplyShape:AddChoice("Sphere", "ACF.ContainerShapes.Sphere")
		SupplyShape:AddChoice("Cylinder", "ACF.ContainerShapes.Cylinder")

		-- Set default shape
		local SelectedShape = ACF.GetClientData("Shape")
		if not GetType(SelectedShape) then SelectedShape = "ACF.ContainerShapes.Box" end

		ACF.SetClientData("Shape", SelectedShape, true)
		SupplyShape:ChooseOptionID(SelectedShape == "ACF.ContainerShapes.Sphere" and 2 or SelectedShape == "ACF.ContainerShapes.Cylinder" and 3 or 1)

		-- Live capacity and rate preview label
		local CapacityLabel = Menu:AddLabel("")

		-- Size sliders
		local Min = ACF.ContainerMinSize
		local Max = ACF.ContainerMaxSize

		-- Set defaults before creating sliders to avoid nil accesses in setters
		local DefaultX = ACF.GetClientNumber("SupplySizeX", 24)
		local DefaultY = ACF.GetClientNumber("SupplySizeY", 24)
		local DefaultZ = ACF.GetClientNumber("SupplySizeZ", 24)

		ACF.SetClientData("SupplySizeX", DefaultX, true)
		ACF.SetClientData("SupplySizeY", DefaultY, true)
		ACF.SetClientData("SupplySizeZ", DefaultZ, true)

		local SupplySize = Vector(DefaultX, DefaultY, DefaultZ)

		local function UpdateSupplyText()
			local Wall = ACF.ContainerArmor * ACF.MmToInch
			local Shape = GetType(ACF.GetClientData("Shape")) or GetType("ACF.ContainerShapes.Box")

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

			ACF.SetClientData("Shape", Data)
			UpdateSupplyText()
		end

		local SizeX = Menu:AddSlider("Length", Min, Max)
		SizeX:SetClientData("SupplySizeX", "OnValueChanged")
		SizeX:DefineSetter(function(Panel, _, _, Value)
			local X = math.Round(Value)

			Panel:SetValue(X)

			SupplySize.x = X

			UpdateSupplyText()

			return X
		end)

		local SizeY = Menu:AddSlider("Width", Min, Max)
		SizeY:SetClientData("SupplySizeY", "OnValueChanged")
		SizeY:DefineSetter(function(Panel, _, _, Value)
			local Y = math.Round(Value)

			Panel:SetValue(Y)

			SupplySize.y = Y

			UpdateSupplyText()

			return Y
		end)

		local SizeZ = Menu:AddSlider("Height", Min, Max)
		SizeZ:SetClientData("SupplySizeZ", "OnValueChanged")
		SizeZ:DefineSetter(function(Panel, _, _, Value)
			local Z = math.Round(Value)

			Panel:SetValue(Z)

			SupplySize.z = Z

			UpdateSupplyText()

			return Z
		end)

		-- Initialize preview with defaults
		UpdateSupplyText()

		ACF.SetClientData("PrimaryClass", "acf_supply")
		ACF.SetClientData("SecondaryClass", "N/A")
	end
end)