local ACF = ACF

local GridMaterial = CreateMaterial("acf_bp_vis_grid2", "UnlitGeneric", {
	["$basetexture"] = "hunter/myplastic",
	["$model"] = 1,
	["$translucent"] = 1,
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1
})

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
						    Menu:AddNumberUserVar(     VerificationCtx, "#acf.menu.baseplates.plate_thickness", "Thickness")
						    Menu:AddBooleanUserVar(    VerificationCtx, "#acf.menu.baseplates.disable_alt_e",   "DisableAltE")
	local GForceTicks     = Menu:AddNumberUserVar(     VerificationCtx, "#acf.menu.baseplates.gforce_ticks",    "GForceTicks")
	local GForceTicksInfo = Menu:AddHelp("#acf.menu.baseplates.gforce_ticks_info")

	local BaseplateBase     = Menu:AddCollapsible("#acf.menu.baseplates.baseplate_info", nil, "icon16/shape_square_edit.png")
	local BaseplateName     = BaseplateBase:AddTitle()
	local BaseplateDesc     = BaseplateBase:AddLabel()

	BaseplateName.ACF_OnUpdate = function(self, KeyChanged, _, Value) if KeyChanged == "BaseplateType" then self:SetText(Value.Name) end end
	BaseplateDesc.ACF_OnUpdate = function(self, KeyChanged, _, Value) if KeyChanged == "BaseplateType" then self:SetText(Value.Description) end end
	GForceTicks.ACF_OnUpdate   = function(self, KeyChanged, _, Value)
		if KeyChanged == "BaseplateType" then
			self:SetVisible(Value == ACF.Classes.BaseplateTypes.Get("Aircraft"))
			self:GetParent():InvalidateLayout()
		end
	end
	GForceTicksInfo.ACF_OnUpdate = GForceTicks.ACF_OnUpdate

	local Vis = BaseplateBase:AddPanel("DPanel")
	Vis:SetSize(30, 256)

	function Vis:Paint(ScrW, ScrH)
		local W, H = SizeX:GetValue(), SizeY:GetValue()
		self.CamDistance = math.max(W, H, 60) * 1

		local Z = (math.max(1, ScrH / H) / math.max(1, ScrW / W)) * 2
		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(GridMaterial)
		surface.DrawTexturedRectRotated(ScrW / 2, ScrH / 2, W * Z, H * Z, 0)

		surface.SetDrawColor(255, 70, 70); surface.DrawRect((ScrW / 2) - 1, ScrH / 2, 3, H / 2 * Z)
		surface.SetDrawColor(70, 255, 70); surface.DrawRect(ScrW / 2, (ScrH / 2) - 1, W / 2 * Z, 3)
	end

	local BaseplateConvertInfo = Menu:AddCollapsible("#acf.menu.baseplates.convert")
	local BaseplateConvertText = ""
	for I = 1, 6 do
		BaseplateConvertText = BaseplateConvertText .. language.GetPhrase("acf.menu.baseplates.convert_info" .. I)
	end
	BaseplateConvertInfo:AddLabel(BaseplateConvertText)
end

ACF.AddMenuItem(50, "#acf.menu.entities", "#acf.menu.baseplates", "shape_square", CreateMenu)