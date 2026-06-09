local ACF     = ACF
local Classes = ACF.Classes

local function CreateMenu(Menu)
	ACF.SetToolMode("acf_menu", "Spawner", "Baseplate")
	ACF.SetClientData("PrimaryClass", "acf_baseplate")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("#acf.menu.baseplates.settings")
	Menu:AddWikiLink("Baseplates", "docs/getting_started/first_tank/baseplate_aio.html")
	Menu:AddLabel("#acf.menu.baseplates.desc")

	local EntityClassDef = Classes.GetTypeByName("acf_baseplate")

	local TypeSelector = Classes.CreateTypeSelector(Menu, EntityClassDef, "BaseplateType")
	local ClassList    = TypeSelector.ComboBox

	local WidthOpts     	= Classes.GetTypeFieldByName(EntityClassDef, "Width").Options
	local LengthOpts     	= Classes.GetTypeFieldByName(EntityClassDef, "Length").Options
	local ThicknessOpts     = Classes.GetTypeFieldByName(EntityClassDef, "Thickness").Options

	ACF.SetClientData("Width",     ACF.GetClientNumber("Width",     WidthOpts.Default     or 36),  true)
	ACF.SetClientData("Length",    ACF.GetClientNumber("Length",    LengthOpts.Default    or 36),  true)
	ACF.SetClientData("Thickness", ACF.GetClientNumber("Thickness", ThicknessOpts.Default or 1.5), true)

	local SizeX      = Menu:AddSlider("#acf.menu.baseplates.plate_width",     WidthOpts.Min     or 36,  WidthOpts.Max     or 240, WidthOpts.Decimals     or 2)
	local SizeY      = Menu:AddSlider("#acf.menu.baseplates.plate_length",    LengthOpts.Min    or 36,  LengthOpts.Max    or 480, LengthOpts.Decimals    or 2)
	local SizeZ      = Menu:AddSlider("#acf.menu.baseplates.plate_thickness", ThicknessOpts.Min or 0.5, ThicknessOpts.Max or 3,   ThicknessOpts.Decimals or 2)
	local DisableAltE = Menu:AddCheckBox("#acf.menu.baseplates.disable_alt_e")

	local BaseplateBase = Menu:AddCollapsible("#acf.menu.baseplates.baseplate_info", nil, "icon16/shape_square_edit.png")
	local BaseplateName = BaseplateBase:AddTitle()
	local BaseplateDesc = BaseplateBase:AddLabel()

	if ClassList and ClassList.Selected then
		BaseplateName:SetText(ClassList.Selected.Name)
		BaseplateDesc:SetText(ClassList.Selected.Description)
	end

	function TypeSelector.OnTypeChanged(TypeObj)
		BaseplateName:SetText(TypeObj.Name)
		BaseplateDesc:SetText(TypeObj.Description)
	end

	local PreviewSettings = {
		FOV       = 120,
		Height    = 120,
		AngOffset = Angle(0, -90, 0),
	}

	local BaseplatePreview = BaseplateBase:AddModelPreview("models/holograms/cube.mdl", true, "Primary")
	BaseplatePreview:UpdateSettings(PreviewSettings)
	BaseplatePreview:UpdateModel("models/holograms/cube.mdl", "hunter/myplastic")

	local function UpdatePreviewSize()
		local X, Y, Z = SizeX:GetValue(), SizeY:GetValue(), SizeZ:GetValue()
		BaseplatePreview:SetModelScale(Vector(Y, X, Z)) -- X and Y are swapped intentionally
	end

	SizeX:SetClientData("Width", "OnValueChanged")
	SizeX:DefineSetter(function(Panel, _, _, Value)
		local X = math.Round(Value, 2)
		Panel:SetValue(X)
		UpdatePreviewSize()
		return X
	end)

	SizeY:SetClientData("Length", "OnValueChanged")
	SizeY:DefineSetter(function(Panel, _, _, Value)
		local Y = math.Round(Value, 2)
		Panel:SetValue(Y)
		UpdatePreviewSize()
		return Y
	end)

	SizeZ:SetClientData("Thickness", "OnValueChanged")
	SizeZ:DefineSetter(function(Panel, _, _, Value)
		local Z = math.Round(Value, 2)
		Panel:SetValue(Z)
		UpdatePreviewSize()
		return Z
	end)

	DisableAltE:SetClientData("DisableAltE", "OnChange")

	UpdatePreviewSize()

	local BaseplateConvertInfo = Menu:AddCollapsible("#acf.menu.baseplates.convert")
	local BaseplateConvertText = ""
	for I = 1, 6 do
		BaseplateConvertText = BaseplateConvertText .. language.GetPhrase("acf.menu.baseplates.convert_info" .. I)
	end
	BaseplateConvertInfo:AddLabel(BaseplateConvertText)
end

ACF.AddMenuItem(50, "#acf.menu.entities", "#acf.menu.baseplates", "shape_square", CreateMenu)