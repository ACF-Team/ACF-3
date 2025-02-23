local ACF = ACF

local GridMaterial = CreateMaterial("acf_bp_vis_grid1", "VertexLitGeneric", {
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

	Menu:AddTitle("Baseplate Settings")
	Menu:AddLabel("The root entity of all ACF contraptions.")

	local ClassList    = Menu:AddComboBox()
	local BaseplateBase     = Menu:AddCollapsible("Baseplate Information")
	local BaseplateName     = BaseplateBase:AddTitle()
	local BaseplateDesc     = BaseplateBase:AddLabel()

	local SizeX        = Menu:AddSlider("Plate Width (gmu)", 36, 96, 2)
	local SizeY        = Menu:AddSlider("Plate Length (gmu)", 36, 420, 2)
	local SizeZ        = Menu:AddSlider("Plate Thickness (gmu)", 0.5, 3, 2)

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected       = Data

		BaseplateName:SetText(Data.Name)
		BaseplateDesc:SetText(Data.Description)

		ACF.SetClientData("BaseplateType", Data.ID)
	end

	BaseplateBase:AddLabel("Comparing the current dimensions with a 105mm Howitzer:")

	local Vis = BaseplateBase:AddModelPreview("models/howitzer/howitzer_105mm.mdl", true)
	Vis:SetSize(30, 256)

	function Vis:PreDrawModel(_)
		local W, H, T = SizeX:GetValue(), SizeY:GetValue(), SizeZ:GetValue()
		self.CamDistance = math.max(W, H, 60) * 1

		render.SetMaterial(GridMaterial)
		render.DrawBox(vector_origin, angle_zero, Vector(-H / 2, -W / 2, -T / 2), Vector(H / 2, W / 2, T / 2), color_white)
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

	local BaseplateConvertInfo     = Menu:AddCollapsible("Trying to convert a baseplate?")

	BaseplateConvertInfo:AddLabel("You can right click on an entity to replace an existing entity with an ACF Baseplate. " ..
		"This will, to the best of its abilities (given you're using a cubical prop, with the long side facing forwards, ex. a SProps plate), replace the entity you're looking at with " ..
		"a new ACF baseplate.\n\nIt works by taking an Advanced Duplicator 2 copy of the entire contraption from the target entity, replacing the target entity " ..
		"in the dupe's class to acf_baseplate, setting the size based off the physical size of the target entity, then removing all entities and re-pasting the dupe. " ..
		"\n\nYou will need to manually re-copy the contraption with the Adv. Dupe 2 tool before using it again, but after that, everything should be converted. This is " ..
		"an experimental tool, so if something breaks with an ordinary setup, report it at https://github.com/ACF-Team/ACF-3/issues."
	)
	local Entries = BaseplateTypes.GetEntries()
	ACF.LoadSortedList(ClassList, Entries, "Name")
end

ACF.AddMenuItem(0, "Entities", "Baseplates", "shape_square", CreateMenu)