local ACF = ACF

local function CreateMenu(Menu)
	ACF.SetToolMode("acf_menu", "Spawner", "Controller")

	ACF.SetClientData("PrimaryClass", "acf_controller")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("All-In-One Controllers")
	Menu:AddLabel("Allows you to easily setup a tank without requiring a complex wiring setup.")

	local Instructions = Menu:AddCollapsible("Instructions", true, "icon16/computer_add.png")
	Instructions:AddLabel("Place down the controller. Link each for the given effects: ")
	Instructions:AddLabel("Seat -> Required to control anything")
	Instructions:AddLabel("Main (Not transfer) Gearbox -> Drives mobility")
	Instructions:AddLabel("Turret -> To aim turrets")
	Instructions:AddLabel("Gun -> To shoot guns")
	Instructions:AddLabel("Racks -> To shoot racks")
	Instructions:AddLabel("Baseplates -> To use baseplate seats or to read speed from the controller")
	Instructions:AddLabel("Crew -> To use crew seats if you're doing multicrew stuff")
	Instructions:AddLabel("Only these entities need to be linked. The rest will be automatically detected.")
	Instructions:AddLabel("If you don't want the AIO controller to control something, just don't link it.")

	local TroubleShooting = Menu:AddCollapsible("Troubleshooting", true, "icon16/computer_error.png")
	TroubleShooting:AddLabel("If you're using a single gearbox, make sure all your forward gears come before your reverse gears in the readout.")

	local Controls = Menu:AddCollapsible("Controls", true, "icon16/computer_go.png")
	Controls:AddLabel("Mouse1: Fire primary weapon (largest caliber gun)")
	Controls:AddLabel("Mouse2: Fire secondary weapon (any other gun)")
	Controls:AddLabel("Alt: Fire tertiary weapon (any racks)")
	Controls:AddLabel("Shift: Fire smoke launchers")
	Controls:AddLabel("W/S: Move forward/backward")
	Controls:AddLabel("A/D: Turn left/right")
	Controls:AddLabel("Space: Brakes")
	Controls:AddLabel("CTRL: Switch Cameras")
	Controls:AddLabel("R: Unlock turret")

	local Settings = Menu:AddCollapsible("Settings Instructions", true, "icon16/computer_edit.png")
	Settings:AddLabel("Some defaults are applied when you place a controller with the tool. You can change these by editing its properties using the context menu (C + right click).")
	Settings:AddTitle("Camera Settings")
	Settings:AddLabel("When zoomed out, the max values are used. When zoomed in, the min values are used. Slew is the rotation speed of the camera.")
	Settings:AddTitle("Camera Specific Settings")
	Settings:AddLabel("Set Cam Count to the number of cameras you want. The offset is the position of the camera relative to the controller. If Orbit is not 0, the camera will orbit around the point instead.")
	Settings:AddTitle("HUD Settings")
	Settings:AddLabel("Hud Type can be either Minimal or Simple. Minimal is ideal for turrets and simple is ideal for full vehicles.")
	Settings:AddTitle("Drivetrain Settings")
	Settings:AddLabel("Throttle Idle: When not holding any keys, the engine will use this throttle value. Recommended to be 0. Speed units in KPH or MPH. Fuel units in Liters or Gallons.")
	Settings:AddTitle("Brake Settings")
	Settings:AddLabel("Automatic brake engagement will engage when control is released. Manual needs you to hold a key. High brake strength makes you turn faster, up to a point.")
	Settings:AddTitle("Shifting Settings")
	Settings:AddLabel("The automatic shifter will shift up if the RPM is above the min RPM and shift down if the RPM is below the max RPM. The time is the time it takes to shift.")

	ACF.SetClientData("AIOUseDefaults", true, true)
end

ACF.AddMenuItem(62, "#acf.menu.entities", "Controllers", "joystick", CreateMenu)