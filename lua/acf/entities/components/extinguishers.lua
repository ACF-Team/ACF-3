local ACF     = ACF
local Classes = ACF.Classes

local InfoText = "Radius : %s m\nMass : %s\nCost : %s"

function ACF.CreateExtinguisherMenu(_, Menu, Ctx)
	local Info      = Menu:AddLabel("")
	local Slider    = Menu:AddSlider("Agent (kg)", 2, 10, 1)
	local AgentMass = Ctx:Get("AgentMass") or 3

	local function UpdateText()
		local Reach = ACF.GetExtinguisherReach(AgentMass) * ACF.InchToMeter
		local Mass  = ACF.GetExtinguisherMass(AgentMass, 1)

		Info:SetText(InfoText:format(math.Round(Reach, 2), ACF.FormatMass(Mass), ACF.FormatCost(AgentMass * ACF.ExtinguisherCost)))

		if Menu.ComponentPreview then
			Menu.ComponentPreview:SetModelScale(ACF.GetExtinguisherSize(AgentMass))
		end
	end

	function Slider:OnValueChanged(Value)
		AgentMass = math.Round(Value, 1)

		self:SetValue(AgentMass)

		Ctx:Set("AgentMass", AgentMass)

		UpdateText()
	end

	Slider:SetValue(AgentMass)

	UpdateText() -- The slider only reports a change, and it may already sit at this value
end

Classes.DefineClass("ACF.Components.Extinguisher", "ACF.Components.BaseComponent", function(CLASS)
	CLASS.Name        = "Fire Extinguisher"
	CLASS.Description = "Puts out fuel, engine and small-arms ammo fires within its radius. Discharges when it or a linked component catches fire or gets too hot. Can't stop main-gun ammo or battery fires, and armor blocks it. Single use, refilled by supply crates."
	CLASS.Icon        = "icon16/fire.png"
	CLASS.Model       = "models/acf/core/s_ammo_cyl.mdl"
	CLASS.Material    = "phoenix_storms/mat/mat_phx_metallic"
	CLASS.Color       = Color(170, 25, 25)
	CLASS.Entity      = "acf_extinguisher"
	CLASS.CreateMenu  = ACF.CreateExtinguisherMenu
end)
