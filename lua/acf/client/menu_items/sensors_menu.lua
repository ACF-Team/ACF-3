local Sensors = ACF.Classes.Sensors
local Selected = {}
local Sorted = {}

local function LoadSortedList(Panel, List, Member)
	local Choices = Sorted[List]

	if not Choices then
		Choices = {}

		local Count = 0
		for _, V in pairs(List) do
			Count = Count + 1
			Choices[Count] = V
		end

		table.SortByMember(Choices, Member, true)

		Sorted[List] = Choices
		Selected[Choices] = 1
	end

	Panel:Clear()

	for _, V in pairs(Choices) do
		Panel:AddChoice(V.Name, V)
	end

	Panel:ChooseOptionID(Selected[Choices])
end

local function CreateMenu(Menu)
	ACF.WriteValue("PrimaryClass", "N/A")
	ACF.WriteValue("SecondaryClass", "N/A")

	ACF.SetToolMode("acf_menu2", "Main", "Spawner")

	if not next(Sensors) then
		Menu:AddTitle("No Sensors Registered")
		Menu:AddLabel("No sensors have been registered. If this is incorrect, check your console for errors and contact the server owner.")
		return
	end

	local SensorClass = Menu:AddComboBox()
	local SensorList = Menu:AddComboBox()
	local SensorName = Menu:AddTitle()
	local SensorDesc = Menu:AddLabel()

	function SensorClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Choices = Sorted[Sensors]
		Selected[Choices] = Index

		ACF.WriteValue("SensorClass", Data.ID)

		LoadSortedList(SensorList, Data.Items, "ID")
	end

	function SensorList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local ClassData = SensorClass.Selected
		local Choices = Sorted[ClassData.Items]
		Selected[Choices] = Index

		ACF.WriteValue("Sensor", Data.ID)

		SensorName:SetText(Data.Name)
		SensorDesc:SetText(Data.Description or "No description provided.")

		Menu:ClearTemporal(self)
		Menu:StartTemporal(self)

		if Data.CreateMenu then
			Data:CreateMenu(Menu)
		end

		Menu:EndTemporal(self)
	end

	LoadSortedList(SensorClass, Sensors, "ID")
end

ACF.AddOptionItem("Entities", "Sensors", "transmit", CreateMenu)
