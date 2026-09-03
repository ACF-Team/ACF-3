local ACF = ACF

-- Kept in sync with acf_propeller/init.lua (calibration constants) so the menu can preview thrust.
local CT_PER_BLADE = 0.0322
local CQ_PER_BLADE = 0.0023
local THRUST_EXP   = 0.85
local AIR_DENSITY  = 1.225
local PREVIEW_RPM  = 2700 -- nominal shaft RPM used for the static readout

local function Estimate(Blades, Diameter)
	local N  = PREVIEW_RPM / 60
	local CT = CT_PER_BLADE * (Blades ^ THRUST_EXP)
	local CQ = CQ_PER_BLADE * Blades
	local T  = CT * AIR_DENSITY * N * N * Diameter ^ 4
	local Q  = CQ * AIR_DENSITY * N * N * Diameter ^ 5
	return T, Q
end

ACF.Menu.RegisterPage({
	ID       = "acf_propeller",
	Category = "#acf.menu.entities",
	Name     = "Propellers",
	Icon     = "cog",
	Order    = 520,

	Contexts = { Propeller = "acf_propeller" },

	Actions = {
		{
			Bind    = "left",
			Context = "Propeller",
			Preview = true,
			Desc    = "Spawn a new propeller, or update the one you're aiming at.",
		},
		{
			Bind = "right",
			Commit = "link",
			Desc = "Select a gearbox, then a propeller, to link them (hold R to unlink).",
		},
	},

	Build = function(Menu, Contexts)
		local Prop = Contexts.Propeller

		Menu:AddTitle("Propeller")
		Menu:AddLabel("A drivetrain effector: link it to a gearbox and it converts shaft torque into forward thrust along its own facing.")

		-- Blade count + overall size, generated (number sliders) from the field metadata.
		Menu:AddField(Prop, "Blades",   { Title = "Blade Count" })
		Menu:AddField(Prop, "Diameter", { Title = "Diameter (m)" })

		local Base = Menu:AddCollapsible("Performance", nil, "icon16/cog_edit.png")
		Base:AddLabel("Bigger diameter is powerful but its torque draw (D^5) outruns its thrust (D^4), so it needs a low-RPM, high-torque drivetrain and gets heavy. More blades add thrust in a smaller disc, but cost efficiency and mass.")
		local Readout = Base:AddLabel("")

		local Preview = Base:AddModelPreview("models/maxofs2d/hover_propeller.mdl", true, "Primary")
		Preview:UpdateSettings({ FOV = 100, Height = 100 })

		local function Refresh()
			local Blades   = Prop:Get("Blades") or 3
			local Diameter = Prop:Get("Diameter") or 2
			local T, Q = Estimate(Blades, Diameter)
			Readout:SetText(("At %d RPM: ~%d N thrust, ~%d Nm torque draw."):format(PREVIEW_RPM, math.Round(T), math.Round(Q)))
		end

		Prop:OnChange("PropellerThrustPreview", nil, Refresh)
		Refresh()
	end,
})
