local ACF     = ACF
local Classes = ACF.Classes

local PanelText = "Area : %s m²\nMass : %s"

function ACF.CreateBlowoutPanelMenu(_, Menu, Ctx)
	local Info      = Menu:AddLabel("")
	local Size      = Vector(Ctx:Get("PanelLength") or 24, Ctx:Get("PanelWidth") or 24, Ctx:Get("PanelThickness") or 20) -- Thickness in mm
	local ArmorType = Classes.GetSubtypeByName("ACF.ArmorTypes.BaseArmorType", "ACF.ArmorTypes.RHA")

	local function UpdateText()
		local Thickness = Size.z * ACF.MmToInch
		local Area      = Size.x * Size.y * ACF.InchToMeter ^ 2
		local Mass      = Size.x * Size.y * Thickness * ArmorType.Density * ACF.gCmToKgIn

		Info:SetText(PanelText:format(math.Round(Area, 2), ACF.FormatMass(Mass)))

		if Menu.ComponentPreview then
			Menu.ComponentPreview:SetModelScale(Vector(Size.x, Size.y, Thickness))
		end
	end

	local function AddSizeSlider(Title, Key, Axis, Min, Max, Decimals)
		local Slider = Menu:AddSlider(Title, Min, Max, Decimals)

		function Slider:OnValueChanged(Value)
			local Rounded = math.Round(Value, Decimals)

			self:SetValue(Rounded)

			Size[Axis] = Rounded

			Ctx:Set(Key, Rounded)
			UpdateText()
		end

		Slider:SetValue(Size[Axis])
	end

	AddSizeSlider("Length", "PanelLength", "x", ACF.ContainerMinSize, ACF.ContainerMaxSize, 2)
	AddSizeSlider("Width", "PanelWidth", "y", ACF.ContainerMinSize, ACF.ContainerMaxSize, 2)
	AddSizeSlider("Thickness (mm RHA)", "PanelThickness", "z", 5, ACF.BlowoutPanelMaxThickness, 0)

	UpdateText()
end

Classes.DefineClass("ACF.Components.BlowoutPanel", "ACF.Components.BaseComponent", function(CLASS)
	CLASS.Name        = "Blow-out Panel"
	CLASS.Description = "A weak plate that gives way when a linked ammo crate cooks off, letting the burning propellant vent out of the vehicle instead of bursting it. Only works if the crate's gas can reach it and nothing of the vehicle is outside it. Link it to the crates it serves."
	CLASS.Icon        = "icon16/door_out.png"
	CLASS.Model       = "models/holograms/cube.mdl"
	CLASS.Material    = "hunter/myplastic"
	CLASS.Entity      = "acf_blowout_panel"
	CLASS.CreateMenu  = ACF.CreateBlowoutPanelMenu
end)
