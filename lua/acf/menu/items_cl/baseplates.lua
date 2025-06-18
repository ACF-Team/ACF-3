local ACF = ACF

local GridMaterial = CreateMaterial("acf_bp_vis_grid2", "UnlitGeneric", {
	["$basetexture"] = "hunter/myplastic",
	["$model"] = 1,
	["$translucent"] = 1,
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1
})

local BaseplateTypes = ACF.Classes.BaseplateTypes

local function CreateMenu(Menu)
	ACF.SetToolMode("acf_menu", "Spawner", "Baseplate")
	ACF.SetClientData("PrimaryClass", "acf_baseplate")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("#acf.menu.baseplates.settings")
	Menu:AddLabel("#acf.menu.baseplates.desc")

	local ClassList    = Menu:AddComboBox()

	local SizeX        = Menu:AddSlider("#acf.menu.baseplates.plate_width", 36, 96, 2)
	local SizeY        = Menu:AddSlider("#acf.menu.baseplates.plate_length", 36, 420, 2)
	local SizeZ        = Menu:AddSlider("#acf.menu.baseplates.plate_thickness", 0.5, 3, 2)

	local BaseplateBase     = Menu:AddCollapsible("#acf.menu.baseplates.baseplate_info", nil, "icon16/shape_square_edit.png")
	local BaseplateName     = BaseplateBase:AddTitle()
	local BaseplateDesc     = BaseplateBase:AddLabel()

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected       = Data

		BaseplateName:SetText(Data.Name)
		BaseplateDesc:SetText(Data.Description)

		ACF.SetClientData("BaseplateType", Data.ID)
	end

	local Vis = BaseplateBase:AddPanel("DPanel")
	Vis:SetSize(30, 256)

	function Vis:Paint(ScrW, ScrH)
		local W, H = SizeX:GetValue(), SizeY:GetValue()
		self.CamDistance = math.max(W, H, 60) * 1

		local Z = (math.max(1, ScrH / H) / math.max(1, ScrW / W)) * 2
		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(GridMaterial)
		surface.DrawTexturedRectRotated(ScrW / 2, ScrH / 2, W * Z, H * Z, 0)

		surface.SetDrawColor(255, 70, 70); surface.DrawRect((ScrW / 2) - 1, ScrH / 2, 3, H / 2 * Z)
		surface.SetDrawColor(70, 255, 70); surface.DrawRect(ScrW / 2, (ScrH / 2) - 1, W / 2 * Z, 3)
	end

	SizeX:SetClientData("Width", "OnValueChanged")
	SizeX:DefineSetter(function(Panel, _, _, Value)
		local X = math.Round(Value, 2)

		Panel:SetValue(X)

		return X
	end)

	SizeY:SetClientData("Length", "OnValueChanged")
	SizeY:DefineSetter(function(Panel, _, _, Value)
		local Y = math.Round(Value, 2)

		Panel:SetValue(Y)

		return Y
	end)

	SizeZ:SetClientData("Thickness", "OnValueChanged")
	SizeZ:DefineSetter(function(Panel, _, _, Value)
		local Z = math.Round(Value, 2)

		Panel:SetValue(Z)

		return Z
	end)

	local BaseplateConvertInfo = Menu:AddCollapsible("#acf.menu.baseplates.convert")
	local BaseplateConvertText = ""

	for I = 1, 6 do
		BaseplateConvertText = BaseplateConvertText .. language.GetPhrase("acf.menu.baseplates.convert_info" .. I)
	end

	BaseplateConvertInfo:AddLabel(BaseplateConvertText)
	local Entries = BaseplateTypes.GetEntries()
	ACF.LoadSortedList(ClassList, Entries, "Name")
end

ACF.AddMenuItem(50, "#acf.menu.entities", "#acf.menu.baseplates", "shape_square", CreateMenu)