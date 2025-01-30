local ACF		= ACF
local CrewTypes = ACF.Classes.CrewTypes
local CrewModels = ACF.Classes.CrewModels

local function CreateMenu(Menu)

	ACF.SetToolMode("acf_menu", "Spawner", "Component")

	ACF.SetClientData("PrimaryClass", "acf_crew")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("Crews")

	local Instructions = Menu:AddCollapsible("General Instructions", false)
	Instructions:AddLabel("Crews will be necessary for a well functioning vehicle. Place them in your vehicle for protection and parent them.")
	Instructions:AddLabel("It is recommended to have a commander, driver, gunner, and loader in your vehicle.")
	Instructions:AddLabel("The default limit for crew is 8. Crew will remove themselves if you exceed the type specific limit per contraption as displayed below.")
	Instructions:AddLabel("Linking your seat (singular) to an acf_baseplate makes it immune to damage.")
	Instructions:AddLabel("Please read the crew specific instructions and the stats below for more information.")

	local EffFocusInfo = Menu:AddCollapsible("Efficy/Focus Info", false)
	EffFocusInfo:AddLabel("Each crew has a total efficiency which ranges from 0 to 1. This represents how well they can perform their job.")
	EffFocusInfo:AddLabel("The total efficiency is the product of multiple factors such as lean angle, G-Forces, and model posture efficiency.")
	EffFocusInfo:AddLabel("Different occupations are affected by different efficiencies. For example a loader is affected by load angle while a loader is not.")
	EffFocusInfo:AddLabel("")
	EffFocusInfo:AddLabel("Each crew also has a focus which ranges from 0 to 1. This represents how much effort/focus they can apply to each of their tasks.")
	EffFocusInfo:AddLabel("For example, one loader loading two guns will have a focus of 0.5, since they load each half as fast.")
	EffFocusInfo:AddLabel("")
	EffFocusInfo:AddLabel("The exact efficiencies affecting each crew type or the way their focuses work can be found below.")

	local EffTypesInfo = Menu:AddCollapsible("Efficiency Types", false)
	EffTypesInfo:AddLabel("Model efficiency is based on the posture of the crew model for a given occupation. You can find the multiplier below.")
	EffTypesInfo:AddLabel("Movement efficiency is based on the G forces the crew experiences. Avoid accelerating too fast or crashing into things.")
	EffTypesInfo:AddLabel("Lean angle efficiency is based on the angle of the crew relative to the world. Try to keep them upright.")
	EffTypesInfo:AddLabel("Health efficiency is based on how damaged your crew are. Try to protect them from harm.")
	EffTypesInfo:AddLabel("Space efficiency only applies to loaders and is based on the amount of surrounding open space they have. Try to give them the most room.")

	local CrewJob		= Menu:AddComboBox()
	local CrewJobDesc	= Menu:AddLabel()
	local CrewModel	= Menu:AddComboBox()
	local CrewModelDesc	= Menu:AddLabel()

	local Base			= Menu:AddCollapsible("Crew Information")
	local CrewPreview = Base:AddModelPreview(nil, true)
	local ReplaceOthers = Base:AddCheckBox("I can replace other crew")
	local ReplaceSelf = Base:AddCheckBox("Other crew can replace me")

	ReplaceOthers:SetClientData("ReplaceOthers", "OnChange")
	ReplaceSelf:SetClientData("ReplaceSelf", "OnChange")

	ReplaceOthers:SetChecked(true)
	ReplaceSelf:SetChecked(true)

	local Priority = Base:AddNumberWang("Priority", ACF.CrewRepPrioMin, ACF.CrewRepPrioMax)
	Priority:SetClientData("CrewPriority", "OnValueChanged")
	Priority:SetValue(1)

	local ReplacedOnlyHigher = Base:AddCheckBox("Only higher priorities can replace me")
	ReplacedOnlyHigher:SetClientData("ReplacedOnlyHigher", "OnChange")

	local Limits = Base:AddLabel()
	local Whitelist = Base:AddLabel()
	local Pose = Base:AddLabel()
	local Mass = Base:AddLabel()
	local Leans = Base:AddLabel()
	local GEfficiencies = Base:AddLabel()
	local GDamages = Base:AddLabel()
	local ExtraNotes = Base:AddLabel()

	function CrewJob:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index	= Index
		self.Selected		= Data

		CrewJobDesc:SetText(Data.Description or "No description provided.")

		Limits:SetText("Max Per Contraption: " .. Data.LimitConVar.Amount)

		local wl = {}
		for K, _ in pairs(Data.LinkHandlers or {}) do
			wl[#wl + 1] = K
		end
		Whitelist:SetText("Links to: " .. table.concat(wl, ", "))

		Mass:SetText("Mass: " .. Data.Mass .. " kg")

		if not Data.LeanInfo then Leans:SetText("Efficiency unaffected by Lean angle")
		else
			Leans:SetText("Best efficiency before: " .. Data.LeanInfo.Min .. " degrees lean\nWorst efficiency after: " .. Data.LeanInfo.Max .. " degrees lean")
		end

		if not Data.GForceInfo.Efficiencies then GEfficiencies:SetText("Efficiency unaffected by G-Forces")
		else
			GEfficiencies:SetText("Best Efficiency before: " .. Data.GForceInfo.Efficiencies.Min .. " G\nWorst Efficiency after: " .. Data.GForceInfo.Efficiencies.Max .. " G")
		end

		if not Data.GForceInfo.Damages then GDamages:SetText("Damage not applied by G-Forces")
		else
			GDamages:SetText("Damage starts at: " .. Data.GForceInfo.Damages.Min .. " G\nInstant death at: " .. Data.GForceInfo.Damages.Max .. " G")
		end

		ExtraNotes:SetText(Data.ExtraNotes or "No extra notes provided.")

		if CrewModel.Selected and CrewJob.Selected then Pose:SetText("Model Efficiency Multiplier: " .. (CrewModel.Selected.BaseErgoScores[CrewJob.Selected.ID] or 1)) end

		ACF.SetClientData("CrewTypeID", Data.ID)
	end

	function CrewModel:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index	= Index
		self.Selected		= Data

		CrewModelDesc:SetText(Data.Description or "No description provided.")

		CrewPreview:UpdateModel(Data.Model)
		CrewPreview:UpdateSettings(Data.Preview)

		if CrewModel.Selected and CrewJob.Selected then Pose:SetText("Model Efficiency Multiplier: " .. (CrewModel.Selected.BaseErgoScores[CrewJob.Selected.ID] or 1)) end

		ACF.SetClientData("CrewModelID", Data.ID)
	end

	ACF.LoadSortedList(CrewJob, CrewTypes.GetEntries(), "ID")
	ACF.LoadSortedList(CrewModel, CrewModels.GetEntries(), "ID")
end

ACF.AddMenuItem(61, "Entities", "Crew", "user_female", CreateMenu)