local ACF        = ACF
local Components = ACF.Classes.Components

-- Class: Supply Unit under Components
Components.Register("SP-RFL", {
	Name   = "Supply Crate",
	Entity = "acf_supply",
	LimitConVar = {
		Name   = "_acf_supply",
		Amount = 4,
		Text   = "Maximum amount of ACF Supply crates a player can create."
	}
})

-- Single generic supply item; capacity scales with size sliders
Components.RegisterItem("RFL-UNIT", "SP-RFL", {
	Name        = "Supply Crate",
	Description = "A scalable container that supplies fuel and ammo.",
	Model       = "models/holograms/hq_rcube_thin.mdl",
	Material    = "phoenix_storms/future_vents",
	Preview = {FOV = 120},
	CreateMenu = function(_, Menu)
		-- Shape selector
		local SupplyShape = Menu:AddComboBox()

		SupplyShape:AddChoice("Box", "Box")
		SupplyShape:AddChoice("Sphere", "Sphere")
		SupplyShape:AddChoice("Cylinder", "Cylinder")

		-- Set default shape
		local SelectedShape = ACF.GetClientData("SupplyShape") or "Box"

		ACF.SetClientData("SupplyShape", SelectedShape, true)
		SupplyShape:ChooseOptionID(SelectedShape == "Sphere" and 2 or SelectedShape == "Cylinder" and 3 or 1)

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
			local Shape = ACF.GetClientData("SupplyShape") or "Box"

			local Volume, Area = ACF.ContainerShapes[Shape](SupplySize, Wall)

			local Capacity = Volume * ACF.gCmToKgIn
			local EmptyMass = Area * Wall * ACF.InchToCmCu * ACF.SteelDensity
			local TransferRate = ACF.SupplyMassRate * (Volume / 1000)

			CapacityLabel:SetText(string.format("Capacity : %s kg\nEmpty Mass : %s kg\nTransfer Rate : %s kg/s", math.Round(Capacity, 2), math.Round(EmptyMass, 2), math.Round(TransferRate, 2)))
		end

		function SupplyShape:OnSelect(_, _, Data)
			ACF.SetClientData("SupplyShape", Data)
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
	end,
})

