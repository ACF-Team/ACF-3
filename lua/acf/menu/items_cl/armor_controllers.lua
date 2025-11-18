local ACF = ACF

local function CreateMenu(Menu)
	ACF.SetToolMode("acf_menu", "Spawner", "ArmorController")

	ACF.SetClientData("PrimaryClass", "acf_armor_controller")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("All-In-One Controllers")
	Menu:AddLabel("Allows you to easily setup a tank without requiring a complex wiring setup.")

	local PreviewSettings = {
		FOV = 120,
		Height = 120,
	}
	local Preview = Menu:AddModelPreview("models/hunter/plates/plate025x025.mdl", true)
	Preview:UpdateSettings(PreviewSettings)

	local Instructions = Menu:AddCollapsible("Instructions", true, "icon16/computer_add.png")
	Instructions:AddLabel("Place down the controller. Link each for the given effects: ")
	Instructions:AddLabel("Seat -> Required to control anything")
	Instructions:AddLabel("Main (Not transfer) Gearbox -> Drives mobility")
	Instructions:AddLabel("Turret -> To aim turrets")
	Instructions:AddLabel("Gun -> To shoot guns")
	Instructions:AddLabel("Racks -> To shoot racks")
	Instructions:AddLabel("Baseplates -> To use baseplate seats or to read speed from the controller")
	Instructions:AddLabel("Only these entities need to be linked. The rest will be automatically detected.")
	Instructions:AddLabel("If you don't want the AIO controller to control something, just don't link it.")
end

ACF.AddMenuItem(63, "#acf.menu.entities", "Armor Meshes", "compress", CreateMenu)