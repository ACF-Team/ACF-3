local ACF     = ACF
local Classes = ACF.Classes

local BehaviorChoices = {
	{ "Disable steering",  "Disable" },
	{ "Steer to neutral",  "Neutral" },
	{ "Continue steering", "Continue" },
	{ "Wire input",        "Wire" },
}

local WireMethodChoices = {
	{ "A/D",             "AD" },
	{ "Steer (-1 to 1)", "Steer" },
	{ "World angle",     "Angle" },
}

local AIOMethodChoices = {
	{ "A/D",       "AD" },
	{ "Aim angle", "Aim" },
}

-- Fills a combo box with choices and selects the one matching the context's current value, or the first one
local function LoadChoices(Combo, Ctx, Key, Choices)
	local Current  = Ctx:Get(Key)
	local Selected = 1

	Combo:Clear()

	for Index, Choice in ipairs(Choices) do
		Combo:AddChoice(Choice[1], Choice[2])

		if Choice[2] == Current then Selected = Index end
	end

	Combo:ChooseOptionID(Selected)
end

local function AddChoiceCombo(Menu, Ctx, Title, Key, Choices)
	Menu:AddLabel(Title)

	local Combo = Menu:AddComboBox()

	function Combo:OnSelect(_, _, Data)
		Ctx:Set(Key, Data)
	end

	LoadChoices(Combo, Ctx, Key, Choices)

	return Combo
end

local function AddSlider(Menu, Ctx, Title, Key, Min, Max, Decimals, Default)
	local Slider = Menu:AddSlider(Title, Min, Max, Decimals)

	function Slider:OnValueChanged(Value)
		Ctx:Set(Key, math.Round(Value, Decimals))
	end

	Slider:SetValue(Ctx:Get(Key) or Default)

	return Slider
end

function ACF.CreateSteerplateMenu(_, Menu, Ctx)
	Menu:AddLabel("Link the steer plate to a baseplate, then to the wheels it steers. Wheels must be pointing straight ahead of the current steer angle when linked.")

	local UseAIO = Menu:AddCheckBox("Use AIO Controller on linked baseplate for steering input")
	local Method = AddChoiceCombo(Menu, Ctx, "Input Method", "InputMethod", WireMethodChoices)

	-- The AIO controller can't provide a steer scalar or a world angle, but it can provide its aim angle
	local function LoadMethods(IsAIO)
		LoadChoices(Method, Ctx, "InputMethod", IsAIO and AIOMethodChoices or WireMethodChoices)
	end

	UseAIO:SetValue(Ctx:Get("UseAIOController") ~= false)
	LoadMethods(UseAIO:GetChecked())

	function UseAIO:OnChange(Value)
		Ctx:Set("UseAIOController", Value)
		LoadMethods(Value)
	end

	AddSlider(Menu, Ctx, "Max Steer Angle (standstill)", "MaxSteerAngle", 0, 90, 2, 25)
	AddSlider(Menu, Ctx, "Min Steer Angle (top speed)", "MinSteerAngle", 0, 90, 2, 15)
	AddSlider(Menu, Ctx, "Top Speed (km/h)", "TopSpeed", 1, 300, 1, 70)
	AddSlider(Menu, Ctx, "Turn Rate (degrees/s)", "TurnRate", 1, 720, 1, 160)

	AddChoiceCombo(Menu, Ctx, "When Inactive", "InactiveBehavior", BehaviorChoices)
	AddChoiceCombo(Menu, Ctx, "When Braking", "BrakeBehavior", BehaviorChoices)
	AddChoiceCombo(Menu, Ctx, "When In Water", "WaterBehavior", BehaviorChoices)
end

Classes.DefineClass("ACF.Components.Steerplate", "ACF.Components.BaseComponent", function(CLASS)
	CLASS.Name        = "Steer Plate"
	CLASS.Description = "Steers the wheels linked to it by rotating relative to its linked baseplate, driven by an AIO controller or wire inputs."
	CLASS.Model       = "models/hunter/plates/plate025x025.mdl"
	CLASS.Entity      = "acf_steerplate"
	CLASS.Preview     = { FOV = 120 }
	CLASS.CreateMenu  = ACF.CreateSteerplateMenu
	CLASS.LimitConVar = {
		Name   = "_acf_steerplate",
		Amount = 8,
		Text   = "Maximum amount of ACF Steer Plates a player can create."
	}
end)
