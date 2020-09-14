local Ent_Info = GetConVar("acf_show_entity_info")
local InfoHelp = {
	[0] = "ACF entities will never display their information bubble when the player looks at them.",
	[1] = "ACF entities will only display their information bubble when the player looks at them while they're not seated.",
	[2] = "ACF entities will always display their information bubble when a player looks at them."
}

local function CreateMenu(Menu)
	do -- Entity Information Settings
		local InfoValue = InfoHelp[Ent_Info:GetInt()] and Ent_Info:GetInt() or 1
		local Base = Menu:AddCollapsible("Entity Information")

		Base:AddLabel("Display ACF entity information:")

		local Info = Base:AddComboBox()
		Info:AddChoice("Never", 0)
		Info:AddChoice("When not seated", 1)
		Info:AddChoice("Always", 2)

		local InfoDesc = Base:AddHelp()
		InfoDesc:SetText(InfoHelp[InfoValue])

		function Info:OnSelect(_, _, Data)
			if not InfoHelp[Data] then
				Data = 1
			end

			Ent_Info:SetInt(Data)

			InfoDesc:SetText(InfoHelp[Data])
		end

		Info:ChooseOptionID(InfoValue + 1)

		local HitBox = Base:AddCheckBox("Draw hitboxes on ACF entities.")
		HitBox:SetConVar("acf_drawboxes")

		Base:AddHelp("Some entities might display more than just their hitbox.")

		local Rounds = Base:AddSlider("Max Rounds", 0, 64, 0)
		Rounds:SetConVar("ACF_MaxRoundsDisplay")

		Base:AddHelp("Requires hitboxes to be enabled. Defines the maximum amount of rounds an ammo crate needs to have before using bulk display.")
	end

	do -- Legal Check Settings
		local Base = Menu:AddCollapsible("Legal Checks")

		local Hints = Base:AddCheckBox("Enable hints on entity disabling.")
		Hints:SetConVar("acf_legalhints")
	end

	do -- Aesthetic Settings
		local Base = Menu:AddCollapsible("Aesthetic Settings")

		local Ropes = Base:AddCheckBox("Create mobility rope links.")
		Ropes:SetConVar("acf_mobilityropelinks")

		local Particles = Base:AddSlider("Particle Mult.", 0.1, 1, 2)
		Particles:SetConVar("acf_cl_particlemul")

		Base:AddHelp("Defines the clientside particle multiplier, reduce it if you're experiencing lag when ACF effects are created.")
	end

	do -- Tool Settings
		local Base = Menu:AddCollapsible("Tool Settings")

		local Category = Base:AddCheckBox("Use custom category for ACF tools.")
		Category:SetConVar("acf_tool_category")

		Base:AddHelp("You will need to rejoin the server for this option to apply.")
	end
end

ACF.AddMenuItem(201, "About the Addon", "Settings", "wrench", CreateMenu)
