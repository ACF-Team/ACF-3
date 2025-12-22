local ACF = ACF

local function CreateMenu(Menu)
	ACF.SetToolMode("acf_menu", "Spawner", "Controller")

	ACF.SetClientData("PrimaryClass", "acf_controller")
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
	Instructions:AddLabel("Direct ballistic computer -> To compute compensate for drop of projectiles")
	Instructions:AddLabel("Warning receivers -> To receive warnings about lasers/radars aimed at you")
	Instructions:AddLabel("Only these entities need to be linked. The rest will be automatically detected.")
	Instructions:AddLabel("If you don't want the AIO controller to control something, just don't link it.")
	Instructions:AddLabel("Hold C and right click the controller to edit the settings.")

	local Controls = Menu:AddCollapsible("Controls", false, "icon16/computer_go.png")
	Controls:AddLabel("Mouse1: Fire primary weapon (largest caliber gun)")
	Controls:AddLabel("Mouse2: Fire secondary weapon (any other gun)")
	Controls:AddLabel("Alt: Fire tertiary weapon (any racks)")
	Controls:AddLabel("Shift: Fire smoke launchers")
	Controls:AddLabel("W/S: Move forward/backward")
	Controls:AddLabel("A/D: Turn left/right")
	Controls:AddLabel("Space: Brakes")
	Controls:AddLabel("CTRL: Switch Cameras")
	Controls:AddLabel("R: Unlock turret")
	Controls:AddLabel("1/2/3: Select next ammo type (press again to force reload)")
	Controls:AddLabel("Mouse3: Lase ballistic computer")

	local TroubleShooting = Menu:AddCollapsible("Troubleshooting", false, "icon16/computer_error.png")
	TroubleShooting:AddLabel("If you're using a single gearbox, make sure all your forward gears come before your reverse gears in the readout.")

	ACF.SetClientData("AIOUseDefaults", true, true)
end

ACF.AddMenuItem(62, "#acf.menu.entities", "Controllers", "joystick", CreateMenu)