local ACF		= ACF
local CrewTypes = ACF.Classes.CrewTypes
local CrewModels = ACF.Classes.CrewModels
local CrewPoses = ACF.Classes.CrewPoses

local table_empty = {}

-- todo: outfitter, fittr support?
-- local MODEL_SOURCE_STANDARD = 0

local function OpenPmSelector(PlayerModelTxtbox, PlayerModelBodygroups, PlayerModelSkin)
	local Selector = vgui.Create("DFrame")
	Selector:SetSize(ScrW() / 2.25, ScrH() / 1.5)
	Selector:MakePopup()
	Selector:Center()
	local StartTime = SysTime()
	function Selector:Paint(w, h)
		Derma_DrawBackgroundBlur(self, StartTime)
		DFrame.Paint(self, w, h)
	end
	Selector:SetIcon("icon16/user_suit.png")
	Selector:SetTitle("ACF - Crew Playermodel Selector")

	local Sheet = Selector:Add("DPropertySheet")
	Sheet:Dock(FILL)

	do
		local PlayermodelsPanel = Sheet:Add("DPanel")
		Sheet:AddSheet("Standard Playermodels", PlayermodelsPanel, "icon16/user.png")

		local ModelView = PlayermodelsPanel:Add("DModelPanel")
		ModelView:Dock(LEFT)
		ModelView:SetSize(400, 0)
		ModelView:SetFOV(36)
		ModelView:SetCamPos(Vector(-25, -50, 0))
		ModelView:SetDirectionalLight(BOX_RIGHT, Color( 255, 160, 80, 255 ))
		ModelView:SetDirectionalLight(BOX_LEFT, Color( 80, 160, 255, 255 ))
		ModelView:SetAmbientLight(Vector( -64, -64, -64 ))
		ModelView:SetAnimated(true)
		ModelView.Angles = angle_zero
		ModelView:SetLookAt(Vector( -100, 0, -22 ))

		local ModelListPnl = PlayermodelsPanel:Add("DPanel")
		ModelListPnl:Dock(FILL)
		ModelListPnl:DockPadding( 8, 8, 8, 8 )

		local SearchBar = ModelListPnl:Add( "DTextEntry" )
		SearchBar:Dock(TOP)
		SearchBar:DockMargin(0, 0, 0, 8)
		SearchBar:SetUpdateOnType(true)
		SearchBar:SetPlaceholderText("#spawnmenu.quick_filter")

		local ModelInfoPanel = ModelListPnl:Add("DPanel")
		ModelInfoPanel.Paint = function() end
		ModelInfoPanel:Dock(FILL)

		local PanelSelect = ModelInfoPanel:Add("DPanelSelect")
		PanelSelect:Dock(FILL)

		local ExtraModelInfo = ModelInfoPanel:Add("DScrollPanel")
		ExtraModelInfo:Dock(BOTTOM)
		ExtraModelInfo:SetSize(0, 150)

		for name, model in SortedPairs(player_manager.AllValidModels()) do
			local Icon = vgui.Create("SpawnIcon")
			Icon:SetModel(model)
			Icon:SetSize(64, 64)
			Icon:SetTooltip(name)
			Icon.playermodel = name
			Icon.model_path = model
			PanelSelect:AddPanel(Icon)
		end

		local SetModel, SetModelBodygroups, SetModelSkin

		function SetModel(Model)
			util.PrecacheModel(Model)
			ModelView:SetModel(Model)
			PlayerModelTxtbox:SetValue(Model)
			ModelView.Entity:SetPos(Vector( -100, 0, -61 ))

			ExtraModelInfo:Clear()
			local SkinSlider = ExtraModelInfo:Add("DNumSlider")
			SkinSlider:Dock(TOP)
			SkinSlider:SetText("Skin")
			SkinSlider:SetDark(true)
			SkinSlider:SetTall(48)
			SkinSlider:SetDecimals(0)
			SkinSlider:SetMax(ModelView.Entity:SkinCount() - 1)
			SkinSlider:SetValue(PlayerModelSkin:GetValue())
			SkinSlider.OnValueChanged = function()
				SetModelSkin(SkinSlider:GetValue())
			end

			local function UpdateBodyGroups(k, val)
				ModelView.Entity:SetBodygroup(k, math.Round(val))

				local str = string.Explode("", PlayerModelBodygroups:GetText())
				if #str < k + 1 then for i = 1, k + 1 do str[i] = str[i] or 0 end end
				str[k + 1] = math.Round(val)
				PlayerModelBodygroups:SetValue(table.concat(str, ""))
			end

			local Groups = string.Explode("", PlayerModelBodygroups:GetText())
			for k = 0, ModelView.Entity:GetNumBodyGroups() - 1 do
				if ModelView.Entity:GetBodygroupCount(k) <= 1 then continue end

				local BodyGroup = ExtraModelInfo:Add("DNumSlider")
				BodyGroup:Dock(TOP)
				BodyGroup:SetText(string.NiceName(ModelView.Entity:GetBodygroupName(k)))
				BodyGroup:SetDark(true)
				BodyGroup:SetTall(32)
				BodyGroup:SetDecimals(0)
				BodyGroup:SetMax(ModelView.Entity:GetBodygroupCount(k) - 1)
				BodyGroup:SetValue(Groups[k + 1] or 0)
				BodyGroup.OnValueChanged = function(_, value) UpdateBodyGroups(k, value) end

				ModelView.Entity:SetBodygroup(k, Groups[k + 1] or 0)
			end
		end

		function SetModelBodygroups(Bodygroups)
			ModelView.Entity:SetBodyGroups(Bodygroups or "")
			PlayerModelBodygroups:SetValue(Bodygroups)
		end

		function SetModelSkin(Skin)
			Skin = math.Round(Skin or 0)
			ModelView.Entity:SetSkin(Skin)
			PlayerModelSkin:SetValue(Skin)
		end

		function PanelSelect:OnActivePanelChanged(_, New)
			SetModel(New.model_path)
		end

		function ModelView:DragMousePress()
			self.PressX, self.PressY = input.GetCursorPos()
			self.Pressed = true
		end

		function ModelView:DragMouseRelease() self.Pressed = false end

		function ModelView:LayoutEntity(ent)
			if self.bAnimated then self:RunAnimation() end

			if self.Pressed then
				local mx, my = input.GetCursorPos()
				self.Angles = self.Angles - Angle(0, ((self.PressX or mx) - mx) / 2, 0)

				self.PressX, self.PressY = mx, my
			end

			ent:SetAngles(self.Angles)
		end

		SetModel(PlayerModelTxtbox:GetText())
		SetModelBodygroups(PlayerModelBodygroups:GetText())
		SetModelSkin(PlayerModelSkin:GetValue())
	end
end

local function CreateMenu(Menu)
	ACF.SetToolMode("acf_menu", "Spawner", "Component")

	ACF.SetClientData("PrimaryClass", "acf_crew")
	ACF.SetClientData("SecondaryClass", "N/A")
	ACF.SetToolMode("acf_menu", "Spawner", "Crew")

	Menu:AddTitle("#acf.menu.crew.settings")
	Menu:AddPonderAddonCategory("acf", "tankbasics")

	local CrewJob		= Menu:AddComboBox()
	local CrewJobDesc	= Menu:AddLabel()
	local CrewModel		= Menu:AddComboBox()
	local CrewModelDesc	= Menu:AddLabel()

	local Base			= Menu:AddCollapsible("#acf.menu.crew.crew_info", nil, "icon16/group_edit.png")
	local CrewName		= Base:AddTitle()
	local CrewPreview	= Base:AddModelPreview(nil, true)
	local ReplaceOthers	= Base:AddCheckBox("#acf.menu.crew.replace_others")
	local ReplaceSelf	= Base:AddCheckBox("#acf.menu.crew.replace_self")
	local UseAnimation	= Base:AddCheckBox("#acf.menu.crew.use_animation")

	ReplaceOthers:SetClientData("ReplaceOthers", "OnChange")
	ReplaceSelf:SetClientData("ReplaceSelf", "OnChange")
	UseAnimation:SetClientData("UseAnimation", "OnChange")

	ReplaceOthers:SetChecked(true)
	ReplaceSelf:SetChecked(true)
	UseAnimation:SetChecked(false)

	-- Thanks March <3
	local _, _, PlayerModel = Base:AddTextEntry("Model")
	PlayerModel:SetClientData("CrewPlayerModel", "OnValueChange")
	PlayerModel.OnLoseFocus = function(self)
		DTextEntry.OnLoseFocus(self)
		self:OnValueChange(self:GetText())
	end
	PlayerModel:SetValue("models/player/dod_german.mdl")

	local SelectBtn = PlayerModel:GetParent():Add("DImageButton")
	SelectBtn:Dock(RIGHT)
	SelectBtn:DockMargin(2, 0, 0, 1)
	SelectBtn:SetText("")
	SelectBtn:SetTooltip("Playermodel Selector...")
	SelectBtn:SetImage("icon16/user_suit.png")
	SelectBtn:SetSize(17, 32)
	PlayerModel:MoveToFront()

	local PoseBase = Base:AddPanel("ACF_Panel")
	local PoseLabel = PoseBase:AddLabel("Pose")
	PoseLabel:Dock(LEFT)
	PoseLabel:DockMargin(5, 5, 0, 5)

	local PlayerPose = PoseBase:AddComboBox()
	function PlayerPose:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index	= Index
		self.Selected		= Data

		ACF.SetClientData("CrewPoseID", Data.ID)
	end

	local _, _, PlayerModelBodygroups = Base:AddTextEntry("Bodygroups")
	PlayerModelBodygroups:SetClientData("CrewPlayerModelBodygroups", "OnValueChange")
	PlayerModelBodygroups.OnLoseFocus = function(self)
		DTextEntry.OnLoseFocus(self)
		self:OnValueChange(self:GetText())
	end
	PlayerModelBodygroups:SetValue("")

	local PlayerModelSkin = Base:AddNumberWang("Skin", 0, 63) -- I don't remember max skins in the engine? Should this be dynamic?
	PlayerModelSkin:SetClientData("CrewPlayerModelSkin", "OnValueChanged")
	PlayerModelSkin:SetValue(0)

	SelectBtn.DoClick = function() OpenPmSelector(PlayerModel, PlayerModelBodygroups, PlayerModelSkin) end

	local Priority = Base:AddNumberWang("#acf.menu.crew.priority", ACF.CrewRepPrioMin, ACF.CrewRepPrioMax)
	Priority:SetClientData("CrewPriority", "OnValueChanged")
	Priority:SetValue(1)

	local ReplacedOnlyLower = Base:AddCheckBox("#acf.menu.crew.replaced_only_lower")
	ReplacedOnlyLower:SetClientData("ReplacedOnlyLower", "OnChange")

	local Limits = Base:AddLabel()
	local Whitelist = Base:AddLabel()
	local Pose = Base:AddLabel()
	local Mass = Base:AddLabel()
	local Leans = Base:AddLabel()
	local GEfficiencies = Base:AddLabel()
	local GDamages = Base:AddLabel()
	local ExtraNotes = Base:AddLabel()

	local Instructions = Menu:AddCollapsible("#acf.menu.crew.instructions", false, "icon16/user_comment.png")
	for I = 1, 4 do
		Instructions:AddLabel(language.GetPhrase("acf.menu.crew.instructions.desc" .. I))
	end

	local EffFocusInfo = Menu:AddCollapsible("#acf.menu.crew.efficiency", false, "icon16/user_comment.png")
	for I = 1, 6 do
		EffFocusInfo:AddLabel(language.GetPhrase("acf.menu.crew.efficiency.desc" .. I))
	end

	local EffTypesInfo = Menu:AddCollapsible("#acf.menu.crew.types", false, "icon16/user_comment.png")
	for I = 1, 5 do
		EffTypesInfo:AddLabel(language.GetPhrase("acf.menu.crew.types.desc" .. I))
	end

	function CrewJob:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index	= Index
		self.Selected		= Data

		CrewName:SetText(Data.Name)
		CrewJobDesc:SetText(Data.Description or "#acf.menu.no_description_provided")

		Limits:SetText(language.GetPhrase("acf.menu.crew.max_per_contraption"):format(Data.LimitConVar.Amount))

		local wl = {}
		for K in pairs(Data.LinkHandlers or table_empty) do
			wl[#wl + 1] = K
		end
		Whitelist:SetText(language.GetPhrase("acf.menu.crew.links_to"):format(table.concat(wl, ", ")))

		Mass:SetText(language.GetPhrase("acf.menu.crew.mass_text"):format(Data.Mass))

		if not Data.LeanInfo then Leans:SetText("#acf.menu.crew.lean_no_info")
		else
			Leans:SetText(language.GetPhrase("acf.menu.crew.lean_stats"):format(Data.LeanInfo.Min, Data.LeanInfo.Max))
		end

		if not Data.GForceInfo.Efficiencies then GEfficiencies:SetText("#acf.menu.crew.gforce_no_info")
		else
			GEfficiencies:SetText(language.GetPhrase("acf.menu.crew.gforce_stats"):format(Data.GForceInfo.Efficiencies.Min, Data.GForceInfo.Efficiencies.Max))
		end

		if not Data.GForceInfo.Damages then GDamages:SetText("#acf.menu.crew.damage_no_info")
		else
			GDamages:SetText(language.GetPhrase("acf.menu.crew.damage_stats"):format(Data.GForceInfo.Damages.Min, Data.GForceInfo.Damages.Max))
		end

		ExtraNotes:SetText(Data.ExtraNotes or "#acf.menu.crew.no_extra_notes")

		if CrewModel.Selected and CrewJob.Selected then Pose:SetText(language.GetPhrase("acf.menu.crew.model_efficiency"):format(CrewModel.Selected.BaseErgoScores[CrewJob.Selected.ID] or 1)) end

		ACF.SetClientData("CrewTypeID", Data.ID)
	end

	function CrewModel:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index	= Index
		self.Selected		= Data

		CrewModelDesc:SetText(Data.Description or "#acf.menu.no_description_provided")

		CrewPreview:UpdateModel(Data.Model)
		CrewPreview:UpdateSettings(Data.Preview)

		if CrewModel.Selected and CrewJob.Selected then Pose:SetText(language.GetPhrase("acf.menu.crew.model_efficiency"):format(CrewModel.Selected.BaseErgoScores[CrewJob.Selected.ID] or 1)) end

		ACF.SetClientData("CrewModelID", Data.ID)
		ACF.LoadSortedList(PlayerPose, CrewPoses.GetItemEntries(Data.ID), "Name")
	end

	ACF.LoadSortedList(CrewJob, CrewTypes.GetEntries(), "ID", "Icon")
	ACF.LoadSortedList(CrewModel, CrewModels.GetEntries(), "ID")
end

ACF.AddMenuItem(61, "#acf.menu.entities", "#acf.menu.crew", "user_female", CreateMenu)