local ACF = ACF

ACF.Menu.RegisterPage({
	ID       = "acf_rotor",
	Category = "#acf.menu.entities",
	Name     = "Main Rotors",
	Icon     = "cog",
	Order    = 522,

	Contexts = { Rotor = "acf_rotor" },

	Actions = {
		{ Bind = "left",  Context = "Rotor", Preview = true, Desc = "Spawn a new main rotor, or update the one you're aiming at." },
		{ Bind = "right", Commit = "link", Desc = "Select a gearbox, then a rotor, to link them (hold R to unlink)." },
	},

	Build = function(Menu, Contexts)
		local Rotor = Contexts.Rotor

		Menu:AddTitle("Main Rotor")
		Menu:AddLabel("A drivetrain effector: link it to a gearbox and it converts shaft torque into vertical lift (Collective controls how much). Cyclic tilts the disc to translate/aim -- link the rotor to a Control Surface Controller (Components) to fly by mouse. The lift comes with a reaction torque on the airframe that a tail rotor must cancel.")

		Menu:AddField(Rotor, "Blades",   { Title = "Blade Count" })
		Menu:AddField(Rotor, "Diameter", { Title = "Diameter (m)" })

		local Base = Menu:AddCollapsible("Performance", nil, "icon16/cog_edit.png")
		Base:AddLabel("Lift grows with diameter (D^4) but its torque draw (D^5) and the reaction torque it dumps on the hull grow faster -- a big rotor needs a strong, low-RPM drivetrain and a good tail rotor.")

		local Preview = Base:AddModelPreview("models/holograms/cube.mdl", true, "Primary")
		Preview:UpdateSettings({ FOV = 100, Height = 100 })
	end,
})

ACF.Menu.RegisterPage({
	ID       = "acf_tail_rotor",
	Category = "#acf.menu.entities",
	Name     = "Tail Rotors",
	Icon     = "cog",
	Order    = 523,

	Contexts = { Tail = "acf_tail_rotor" },

	Actions = {
		{ Bind = "left",  Context = "Tail", Preview = true, Desc = "Spawn a new tail rotor, or update the one you're aiming at." },
	},

	Build = function(Menu, Contexts)
		local Tail = Contexts.Tail

		Menu:AddTitle("Tail Rotor")
		Menu:AddLabel("Makes sideways thrust at its position: it automatically cancels the main rotor's reaction torque (anti-torque) AND provides yaw control. Mount it out on the tail boom for a long moment arm, and link it to a Control Surface Controller (Components) for mouse yaw. Shoot it off and the helicopter spins.")

		Menu:AddField(Tail, "Size", { Title = "Size" })

		local Preview = Menu:AddModelPreview("models/holograms/cube.mdl", true, "Primary")
		Preview:UpdateSettings({ FOV = 100, Height = 100 })
	end,
})
