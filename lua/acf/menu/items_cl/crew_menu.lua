local ACF		= ACF
local CrewTypes = ACF.Classes.CrewTypes
local CrewModels = ACF.Classes.CrewModels

local table_empty = {}

local function CreateMenu(Menu)
	ACF.SetToolMode("acf_menu", "Spawner", "Component")

	ACF.SetClientData("PrimaryClass", "acf_crew")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("#acf.menu.crew.settings")
	Menu:AddPonderAddonCategory("acf", "crew")

	local CrewJob		= Menu:AddComboBox()
	local CrewJobDesc	= Menu:AddLabel()
	local CrewModel		= Menu:AddComboBox()
	local CrewModelDesc	= Menu:AddLabel()

	local Base			= Menu:AddCollapsible("#acf.menu.crew.crew_info", nil, "icon16/group_edit.png")
	local CrewName		= Base:AddTitle()
	local CrewPreview	= Base:AddModelPreview(nil, true)
	local ReplaceOthers	= Base:AddCheckBox("#acf.menu.crew.replace_others")
	local ReplaceSelf	= Base:AddCheckBox("#acf.menu.crew.replace_self")

	ReplaceOthers:SetClientData("ReplaceOthers", "OnChange")
	ReplaceSelf:SetClientData("ReplaceSelf", "OnChange")

	ReplaceOthers:SetChecked(true)
	ReplaceSelf:SetChecked(true)

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
	for I = 1, 5 do
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
	end

	ACF.LoadSortedList(CrewJob, CrewTypes.GetEntries(), "ID")
	ACF.LoadSortedList(CrewModel, CrewModels.GetEntries(), "ID")
end

ACF.AddMenuItem(61, "#acf.menu.entities", "#acf.menu.crew", "user_female", CreateMenu)