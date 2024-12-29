local ACF		= ACF
local CrewTypes = ACF.Classes.CrewTypes
local CrewModels = ACF.Classes.CrewModels

local function CreateMenu(Menu)

	ACF.SetToolMode("acf_menu", "Spawner", "Component")

	ACF.SetClientData("PrimaryClass", "acf_crew")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("Crews")

	local Instructions = Menu:AddCollapsible("Instructions", false)
	Instructions:AddLabel("Crews will be necessary for a well functioning vehichle. Place them in your vehichle for protection and parent them.")
	Instructions:AddLabel("Test")

	local CrewJob		= Menu:AddComboBox()
	local CrewJobDesc	= Menu:AddLabel()
	local CrewModel	= Menu:AddComboBox()
	local CrewModelDesc	= Menu:AddLabel()

	local Base			= Menu:AddCollapsible("Crew Information")
	local CrewPreview = Base:AddModelPreview(nil, true)
	local ReplaceOthers = Base:AddCheckBox("Can Replace Others")
	local ReplaceSelf = Base:AddCheckBox("Can Be Replaced")

	ReplaceOthers:SetClientData("ReplaceOthers", "OnChange")
	ReplaceSelf:SetClientData("ReplaceSelf", "OnChange")

	ReplaceOthers:SetChecked(true)
	ReplaceSelf:SetChecked(true)

	ACF.SetClientData("ReplaceOthers", true)
	ACF.SetClientData("ReplaceSelf", true)

	function CrewJob:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index	= Index
		self.Selected		= Data

		CrewJobDesc:SetText(Data.Description or "No description provided.")

		ACF.SetClientData("CrewTypeID", Data.ID)
	end

	function CrewModel:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index	= Index
		self.Selected		= Data

		CrewModelDesc:SetText(Data.Description or "No description provided.")

		-- TODO: FIX ONCE TWISTED'S DONE
		CrewPreview:UpdateModel("models/chairs_playerstart/standingpose.mdl")
		CrewPreview:UpdateSettings({FOV = 100})

		ACF.SetClientData("CrewModelID", Data.ID)
	end

	ACF.LoadSortedList(CrewJob, CrewTypes.GetEntries(), "ID")
	ACF.LoadSortedList(CrewModel, CrewModels.GetEntries(), "ID")
end

ACF.AddMenuItem(61, "Entities", "Crew", "user_female", CreateMenu)