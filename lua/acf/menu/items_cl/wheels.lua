local ACF = ACF

local function CreateMenu(Menu)
	ACF.SetToolMode("acf_menu", "Spawner", "Wheels")
	ACF.SetClientData("PrimaryClass", "acf_wheel")
	ACF.SetClientData("SecondaryClass", "N/A")

	local VerificationCtx = ACF.Classes.Entities.VerificationContext("acf_wheel")
	VerificationCtx:StartClientData(ACF.GetAllClientData(true))

	Menu:AddNumberUserVar(VerificationCtx, "Physical Radius", "PhysRadius")
end

ACF.AddMenuItem(211, "#acf.menu.entities", "Wheels", "tire", CreateMenu)