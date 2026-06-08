local ACF = ACF
local BaseplateTypes = ACF.Classes.BaseplateTypes

local function CreateMenu(Menu)
	ACF.SetToolMode("acf_menu", "Spawner", "Baseplate")
	ACF.SetClientData("PrimaryClass", "acf_baseplate")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("#acf.menu.baseplates.settings")

	Menu:AddWikiLink("Baseplates", "docs/getting_started/first_tank/baseplate_aio.html")

	Menu:AddLabel("#acf.menu.baseplates.desc")

	local ClassList    = Menu:AddComboBox()

	-- Set default baseplate size values before creating sliders to prevent nil value errors
	local DefaultWidth = ACF.GetClientNumber("Width", 36)
	local DefaultLength = ACF.GetClientNumber("Length", 36)
	local DefaultThickness = ACF.GetClientNumber("Thickness", 1.5)
	local DefaultGForceTicks = ACF.GetClientNumber("GForceTicks", 4)

	ACF.SetClientData("Width", DefaultWidth, true)
	ACF.SetClientData("Length", DefaultLength, true)
	ACF.SetClientData("Thickness", DefaultThickness, true)
	ACF.SetClientData("GForceTicks", DefaultGForceTicks, true)

	local SizeX        			= Menu:AddSlider("#acf.menu.baseplates.plate_width", 36, 240, 2)
	local SizeY        			= Menu:AddSlider("#acf.menu.baseplates.plate_length", 36, 420, 2)
	local SizeZ        			= Menu:AddSlider("#acf.menu.baseplates.plate_thickness", 0.5, 3, 2)
	local DisableAltE  			= Menu:AddCheckBox("#acf.menu.baseplates.disable_alt_e")
	local ExplodeCollide 		= Menu:AddCheckBox("#acf.menu.baseplates.explode_on_collisions")
	local ExplodeCollideInfo 	= Menu:AddHelp("#acf.menu.baseplates.explode_on_collisions_info")
	local GForceTicks  			= Menu:AddSlider("#acf.menu.baseplates.gforce_ticks", 1, 7, 0)
	local GForceTicksInfo   	= Menu:AddHelp("#acf.menu.baseplates.gforce_ticks_info")

	local BaseplateBase     = Menu:AddCollapsible("#acf.menu.baseplates.baseplate_info", nil, "icon16/shape_square_edit.png")
	local BaseplateName     = BaseplateBase:AddTitle()
	local BaseplateDesc     = BaseplateBase:AddLabel()

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected       = Data

		BaseplateName:SetText(Data.Name)
		BaseplateDesc:SetText(Data.Description)

		local IsAircraft = Data.ID == "Aircraft"
		local IsRecreational = Data.ID == "Recreational"

		ExplodeCollide:SetVisible(IsRecreational)
		ExplodeCollideInfo:SetVisible(IsRecreational)
		GForceTicks:SetVisible(IsAircraft)
		GForceTicksInfo:SetVisible(IsAircraft)

		ACF.SetClientData("BaseplateType", Data.ID)
	end

	local PreviewSettings = {
		FOV = 120,
		Height = 120,
		AngOffset = Angle(0, -90, 0),
	}

	local BaseplatePreview = BaseplateBase:AddModelPreview("models/holograms/cube.mdl", true, "Primary")
	BaseplatePreview:UpdateSettings(PreviewSettings)
	BaseplatePreview:UpdateModel("models/holograms/cube.mdl", "hunter/myplastic")

	local function UpdatePreviewSize()
		local X, Y, Z = SizeX:GetValue(), SizeY:GetValue(), SizeZ:GetValue()
		BaseplatePreview:SetModelScale(Vector(Y, X, Z)) -- Yes, X and Y are swapped on purpose...
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

	GForceTicks:SetClientData("GForceTicks", "OnValueChanged")
	GForceTicks:DefineSetter(function(Panel, _, _, Value)
		local Ticks = math.Round(Value, 0)

		Panel:SetValue(Ticks)

		return Ticks
	end)

	DisableAltE:SetClientData("DisableAltE", "OnChange")
	ExplodeCollide:SetClientData("ExplodeOnCollisions", "OnChange")

	UpdatePreviewSize()

	local BaseplateConvertInfo = Menu:AddCollapsible("#acf.menu.baseplates.convert")
	local BaseplateConvertText = ""
	for I = 1, 6 do
		BaseplateConvertText = BaseplateConvertText .. language.GetPhrase("acf.menu.baseplates.convert_info" .. I)
	end
	BaseplateConvertInfo:AddLabel(BaseplateConvertText)

	local Entries = BaseplateTypes.GetEntries()
	ACF.LoadSortedList(ClassList, Entries, "Name", "Icon")
	ClassList:ChooseOptionID(2)
end

ACF.AddMenuItem(50, "#acf.menu.entities", "#acf.menu.baseplates", "shape_square", CreateMenu)