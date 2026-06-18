local ACF        = ACF
local Components = ACF.Classes.Components

-- Class: Supply Unit under Components
Components.Register("SP-RFL", {
	Name   = "Supply Crate",
	Entity = "acf_supply",
	TutorialURL = "docs/acf_tutorials/refills.html",
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
	Model       = "models/acf/core/s_fuel.mdl",
	Material    = "phoenix_storms/future_vents",
	Preview = {FOV = 120},
	CreateMenu = function(_, Menu)
		local Classes    = ACF.Classes
		local SupplySize -- Live Vector, assigned by AddSizeSliders below

		-- Shape selector (uses the shared acf_container "Shape" class field, sent as an FQN string)
		local SupplyShape  = Menu:AddComboBox()
		local ShapeOptions = Classes.GetChildren(Classes.GetTypeByName("ACF.ContainerShapes.BaseContainerShape"))

		do
			local Selected, SelectedType = 1, "ACF.ContainerShapes.Box"

			for _, ShapeType in pairs(ShapeOptions) do
				local ID       = SupplyShape:AddChoice(ShapeType.Name, ShapeType)
				local TypeName = Classes.GetTypeName(ShapeType)

				if TypeName == ACF.GetClientData("Shape") then
					Selected     = ID
					SelectedType = TypeName
				end
			end

			ACF.SetClientData("Shape", SelectedType, true)
			SupplyShape:ChooseOptionID(Selected)
		end

		-- Live capacity and rate preview label
		local CapacityLabel = Menu:AddLabel("")

		local Min = ACF.ContainerMinSize
		local Max = ACF.ContainerMaxSize

		local function UpdateSupplyText()
			if not SupplySize then return end

			local Wall       = ACF.ContainerArmor * ACF.MmToInch
			local ShapeData  = ACF.GetClientData("Shape")
			local ShapeClass = istable(ShapeData) and ShapeData or Classes.GetTypeByName(ShapeData)
			local ShapeName  = (ShapeClass and ShapeClass.Name) or "Box"
			local ShapeCalc  = ACF.ContainerShapes[ShapeName] or ACF.ContainerShapes.Box

			local Volume, Area = ShapeCalc(SupplySize, Wall)

			local Capacity     = Volume * ACF.gCmToKgIn
			local EmptyMass    = Area * Wall * ACF.InchToCmCu * ACF.SteelDensity
			local TransferRate = ACF.SupplyMassRate * (Volume / 1000)

			CapacityLabel:SetText(string.format("Capacity : %s kg\nEmpty Mass : %s kg\nTransfer Rate : %s kg/s", math.Round(Capacity, 2), math.Round(EmptyMass, 2), math.Round(TransferRate, 2)))

			if Menu.ComponentPreview then
				Menu.ComponentPreview:SetModelScale(SupplySize)
			end
		end

		function SupplyShape:OnSelect(_, _, Data)
			local ShapeClass = istable(Data) and Data or Classes.GetTypeByName(Data)
			local TypeName   = ShapeClass and Classes.GetTypeName(ShapeClass) or "ACF.ContainerShapes.Box"
			local ShapeName  = ShapeClass and ShapeClass.Name or "Box"

			ACF.SetClientData("Shape", TypeName)

			if Menu.ComponentPreview then
				Menu.ComponentPreview:UpdateModel(ACF.ContainerShapeModels[ShapeName] or "models/acf/core/s_fuel.mdl", "phoenix_storms/future_vents")
			end

			UpdateSupplyText()
		end

		-- Size sliders drive the single Vector "Size" client data var (eager-pushed by the helper).
		SupplySize = select(4, Menu:AddSizeSliders("Size", Min, Max, Vector(24, 24, 24), UpdateSupplyText))

		-- Initialize preview with defaults
		UpdateSupplyText()

		ACF.SetClientData("PrimaryClass", "acf_supply")
		ACF.SetClientData("SecondaryClass", "N/A")
	end,
})

