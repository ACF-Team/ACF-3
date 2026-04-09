local function CreateMenu(MenuPanel)
	MenuPanel:AddLabel("Client side settings (only affect what you see).")

	local Base = MenuPanel:AddCollapsible("Settings")
	Base:AddPresetsBar("ClientSettings")
	ACF.CreatePanelsFromDataVars(Base, "ClientSettings")
end

ACF.AddMenuItem(1, "Clientside Settings", "icon16/user.png", CreateMenu, "Settings")