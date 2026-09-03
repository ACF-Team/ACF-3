local ACF = ACF

ACF.Menu.RegisterPage({
	ID       = "acf_control_surface",
	Category = "#acf.menu.entities",
	Name     = "Control Surfaces",
	Icon     = "shape_flip_horizontal",
	Order    = 521,

	Contexts = { Surface = "acf_control_surface" },

	Actions = {
		{
			Bind    = "left",
			Context = "Surface",
			Preview = true,
			Desc    = "Spawn a new control surface, or update the one you're aiming at.",
		},
		{
			Bind = "right",
			Commit = "link",
			Desc = "Select an aircraft baseplate, then a control surface, to link them (hold R to unlink).",
		},
	},

	Build = function(Menu, Contexts)
		local Surface = Contexts.Surface

		Menu:AddTitle("Control Surface")
		Menu:AddLabel("Each surface is a self-contained aerodynamic body: mount it on your aircraft and it makes its own lift/drag from its airflow. Link it to a Control Surface Controller (in Components) for mouse-aim, or wire its Deflection input (degrees) for manual control. The type sets which channel (pitch/yaw/roll) drives it; more area and throw = stronger authority.")

		-- Surface type (axis) + size + max throw, generated from the field metadata.
		local TypeHandle = Menu:AddField(Surface, "Surface")
		Menu:AddField(Surface, "SurfaceSize", { Title = "Size" })
		Menu:AddField(Surface, "MaxDeflection", { Title = "Max Deflection (deg)" })

		local Base = Menu:AddCollapsible("Surface Info", nil, "icon16/shape_flip_horizontal.png")
		local Name = Base:AddTitle()
		local Desc = Base:AddLabel()

		local Preview = Base:AddModelPreview("models/holograms/cube.mdl", true, "Primary")
		Preview:UpdateSettings({ FOV = 100, Height = 100 })

		local function Reflect(TypeObj)
			if not TypeObj then return end
			Name:SetText(TypeObj.Name or "")
			Desc:SetText(TypeObj.Description or "")
			Preview:UpdateModel(TypeObj.Model, TypeObj.Material or "")
		end

		local ClassList = TypeHandle and TypeHandle.ComboBox
		if ClassList and ClassList.Selected then Reflect(ClassList.Selected) end

		if TypeHandle then
			TypeHandle.OnTypeChanged = Reflect
		end
	end,
})
