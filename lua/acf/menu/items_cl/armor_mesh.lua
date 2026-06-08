local ACF = ACF

local function CreateMenu(Menu)
	ACF.SetToolMode("acf_menu", "Spawner", "ArmorMesh")

	ACF.SetClientData("PrimaryClass", "acf_armor_mesh")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("All-In-One Armor Meshes")
	Menu:AddLabel("Compiles armor together for better performance.")

	local PreviewSettings = {
		FOV = 120,
		Height = 120,
	}
	local Preview = Menu:AddModelPreview("models/hunter/plates/plate05x05.mdl", true, "Primary")
	Preview:UpdateSettings(PreviewSettings)
end

ACF.AddMenuItem(63, "#acf.menu.entities", "Armor Meshes", "joystick", CreateMenu)