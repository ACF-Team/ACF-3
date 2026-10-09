local ACF = ACF

ACF.Menu.RegisterPage({
	ID       = "acf_baseplate",
	Category = "#acf.menu.entities",
	Name     = "#acf.menu.baseplates",
	Icon     = "shape_square",
	Order    = 50,

	Contexts = { Plate = "acf_baseplate" },

	Actions = {
		{
			Bind    = "left",
			Context = "Plate",
			Preview = true,
			Desc    = "Spawn a new baseplate, or update the one you're aiming at.",
		},
		{
			Bind = "right",
			Desc = "Convert the entity you're aiming at into a baseplate.",
			Func = function(Player, Trace)
				if CLIENT then return end

				local Notify = ACF.Utilities.Notify
				local Success, Message = ACF.ConvertBaseplate(Player, Trace.Entity)

				if Success then
					Notify.NoticeToPlayer(Player, "Successfully converted the entity.")
				else
					Notify.WarningToPlayer(Player, "Could not convert", Message)
				end
			end,
		},
	},

	Build = function(Menu, Contexts)
		local Plate = Contexts.Plate

		Menu:AddTitle("#acf.menu.baseplates.settings")
		Menu:AddWikiLink("Baseplates", "docs/getting_started/first_tank/baseplate_aio.html")
		Menu:AddLabel("#acf.menu.baseplates.desc")

		-- Baseplate type: a nested class field -> subtype combobox + type-specific submenu, generated.
		local TypeHandle = Menu:AddField(Plate, "BaseplateType")

		-- Size + toggles: generated from the class field metadata (min/max/decimals/defaults).
		Menu:AddField(Plate, "Width",               { Title = "#acf.menu.baseplates.plate_width" })
		Menu:AddField(Plate, "Length",              { Title = "#acf.menu.baseplates.plate_length" })
		Menu:AddField(Plate, "Thickness",           { Title = "#acf.menu.baseplates.plate_thickness" })
		Menu:AddField(Plate, "DisableAltE",         { Title = "#acf.menu.baseplates.disable_alt_e" })
		Menu:AddField(Plate, "NetworkOptimization", { Title = "#acf.menu.baseplates.network_optimization" })
		Menu:AddField(Plate, "UnfreezeOnEntry",     { Title = "#acf.menu.baseplates.unfreeze_on_entry" })

		-- Info + rotatable preview (drives the toolgun ghost via the "Primary" slot).
		local BaseplateBase = Menu:AddCollapsible("#acf.menu.baseplates.baseplate_info", nil, "icon16/shape_square_edit.png")
		local BaseplateName = BaseplateBase:AddTitle()
		local BaseplateDesc = BaseplateBase:AddLabel()

		local ClassList = TypeHandle and TypeHandle.ComboBox
		if ClassList and ClassList.Selected then
			BaseplateName:SetText(ClassList.Selected.Name)
			BaseplateDesc:SetText(ClassList.Selected.Description)
		end

		if TypeHandle then
			TypeHandle.OnTypeChanged = function(TypeObj)
				BaseplateName:SetText(TypeObj.Name)
				BaseplateDesc:SetText(TypeObj.Description)
			end
		end

		local PreviewSettings = { FOV = 120, Height = 120, AngOffset = Angle(0, -90, 0) }
		local Preview = BaseplateBase:AddModelPreview("models/holograms/cube.mdl", true, "Primary")
		Preview:UpdateSettings(PreviewSettings)
		Preview:UpdateModel("models/holograms/cube.mdl", "hunter/myplastic")

		local function UpdatePreviewSize()
			if not IsValid(Preview) then return end
			-- X and Y are swapped intentionally (matches the old menu's model orientation).
			Preview:SetModelScale(Vector(Plate:Get("Length"), Plate:Get("Width"), Plate:Get("Thickness")))
		end

		Plate:OnChange("BaseplatePreview", nil, UpdatePreviewSize)
		UpdatePreviewSize()

		local ConvertInfo = Menu:AddCollapsible("#acf.menu.baseplates.convert")
		local ConvertText = ""
		for I = 1, 6 do
			ConvertText = ConvertText .. language.GetPhrase("acf.menu.baseplates.convert_info" .. I)
		end
		ConvertInfo:AddLabel(ConvertText)
	end,
})
