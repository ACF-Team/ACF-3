local ACF = ACF

local GridMaterial = CreateMaterial("acf_bp_vis_grid1", "VertexLitGeneric", {
	["$basetexture"] = "hunter/myplastic",
	["$model"] = 1,
	["$translucent"] = 1,
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1
})

local function CreateMenu(Menu)
	ACF.SetToolMode("acf_menu", "Spawner", "Baseplate")
	ACF.SetClientData("PrimaryClass", "acf_baseplate")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("#acf.menu.baseplates.settings")
	Menu:AddLabel("#acf.menu.baseplates.desc")

	local SizeX        = Menu:AddSlider("#acf.menu.baseplates.plate_width", 36, 96, 2)
	local SizeY        = Menu:AddSlider("#acf.menu.baseplates.plate_length", 36, 420, 2)
	local SizeZ        = Menu:AddSlider("#acf.menu.baseplates.plate_thickness", 0.5, 3, 2)

	local BaseplateBase = Menu:AddCollapsible("Baseplate Information")
	BaseplateBase:AddLabel("Comparing the current dimensions with a 105mm Howitzer:")

	local Vis = BaseplateBase:AddModelPreview("models/howitzer/howitzer_105mm.mdl", true)
	Vis:SetSize(30, 300)

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

	local BaseplateConvertInfo = Menu:AddCollapsible("#acf.menu.baseplates.convert")
	local BaseplateConvertText = ""

	for I = 1, 6 do
		BaseplateConvertText = BaseplateConvertText .. language.GetPhrase("acf.menu.baseplates.convert_info" .. I)
	end

	BaseplateConvertInfo:AddLabel(BaseplateConvertText)
end

ACF.AddMenuItem(0, "#acf.menu.entities", "#acf.menu.baseplates", "shape_square", CreateMenu)