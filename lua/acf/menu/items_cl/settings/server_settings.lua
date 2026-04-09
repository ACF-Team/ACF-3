local function CreateMenu(MenuPanel)
	MenuPanel:AddLabel("Server side settings (affects all players).")

	local Base = MenuPanel:AddCollapsible("Settings")
	Base:AddPresetsBar("ServerSettings", "Server")
	ACF.CreatePanelsFromDataVars(Base, "ServerSettings", "Server")
end

ACF.AddMenuItem(2, "Serverside Settings", "icon16/server.png", CreateMenu, "Settings")