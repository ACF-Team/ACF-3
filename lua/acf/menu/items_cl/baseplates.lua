local ACF = ACF
local BaseplateTypes = ACF.Classes.BaseplateTypes

local function CreateMenu(Menu)
	ACF.SetToolMode("acf_menu", "Spawner", "Baseplate")
	ACF.SetClientData("PrimaryClass", "acf_baseplate")
	ACF.SetClientData("SecondaryClass", "N/A")

	local VerificationCtx = ACF.Classes.Entities.VerificationContext("acf_baseplate")
	VerificationCtx:StartClientData(ACF.GetAllClientData(true))

	Menu:AddTitle("#acf.menu.baseplates.settings")
	Menu:AddLabel("#acf.menu.baseplates.desc")

					    	Menu:AddSimpleClassUserVar(VerificationCtx, "",                                     "BaseplateType", "Name", "Icon")
	local SizeX           = Menu:AddNumberUserVar(     VerificationCtx, "#acf.menu.baseplates.plate_width",     "Width")
	local SizeY           = Menu:AddNumberUserVar(     VerificationCtx, "#acf.menu.baseplates.plate_length",    "Length")
	local SizeZ			  = Menu:AddNumberUserVar(     VerificationCtx, "#acf.menu.baseplates.plate_thickness", "Thickness")
						    Menu:AddBooleanUserVar(    VerificationCtx, "#acf.menu.baseplates.disable_alt_e",   "DisableAltE")
	local GForceTicks     = Menu:AddNumberUserVar(     VerificationCtx, "#acf.menu.baseplates.gforce_ticks",    "GForceTicks")
	local GForceTicksInfo = Menu:AddHelp("#acf.menu.baseplates.gforce_ticks_info")

	local BaseplateBase     = Menu:AddCollapsible("#acf.menu.baseplates.baseplate_info", nil, "icon16/shape_square_edit.png")
	local BaseplateName     = BaseplateBase:AddTitle()
	local BaseplateDesc     = BaseplateBase:AddLabel()

	local PreviewSettings = {
		FOV = 120,
		Height = 120,
		AngOffset = Angle(0, -90, 0),
	}
	local BaseplatePreview = BaseplateBase:AddModelPreview("models/holograms/cube.mdl", true, "Primary")
	BaseplatePreview:UpdateSettings(PreviewSettings)
	BaseplatePreview:UpdateModel("models/holograms/cube.mdl", "hunter/myplastic")

	BaseplateName.ACF_OnUpdate = function(self, KeyChanged, _, Value) if KeyChanged == "BaseplateType" then self:SetText(Value.Name) end end
	BaseplateDesc.ACF_OnUpdate = function(self, KeyChanged, _, Value) if KeyChanged == "BaseplateType" then self:SetText(Value.Description) end end
	GForceTicks.ACF_OnUpdate   = function(self, KeyChanged, _, Value)
		if KeyChanged == "BaseplateType" then
			self:SetVisible(Value == BaseplateTypes.Get("Aircraft"))
			self:GetParent():InvalidateLayout()
		end
	end
	GForceTicksInfo.ACF_OnUpdate = GForceTicks.ACF_OnUpdate

	local function UpdatePreviewSize()
		local X, Y, Z = SizeX:GetValue(), SizeY:GetValue(), SizeZ:GetValue()
		BaseplatePreview:SetModelScale(Vector(Y, X, Z)) -- Yes, X and Y are swapped on purpose...
	end
	local function ProducerSelfUpdate(Self, _, Producer) if Self == Producer then UpdatePreviewSize() end end
	SizeX.ACF_OnUpdate = ProducerSelfUpdate
	SizeY.ACF_OnUpdate = ProducerSelfUpdate
	SizeZ.ACF_OnUpdate = ProducerSelfUpdate
	UpdatePreviewSize()

	local BaseplateConvertInfo = Menu:AddCollapsible("#acf.menu.baseplates.convert")
	local BaseplateConvertText = ""
	for I = 1, 6 do
		BaseplateConvertText = BaseplateConvertText .. language.GetPhrase("acf.menu.baseplates.convert_info" .. I)
	end
	BaseplateConvertInfo:AddLabel(BaseplateConvertText)
end

ACF.AddMenuItem(50, "#acf.menu.entities", "#acf.menu.baseplates", "shape_square", CreateMenu)