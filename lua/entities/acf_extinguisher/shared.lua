DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName         = "ACF Fire Extinguisher"
ENT.WireDebugName     = "ACF Fire Extinguisher"
ENT.PluralName        = "ACF Fire Extinguishers"
ENT.IsACFExtinguisher = true
ENT.ACF_Limit         = 4

-- What can be linked to a bottle to set it off when it catches fire or gets too hot
ENT.ACF_WatchedClasses = { acf_ammo = true, acf_fueltank = true, acf_engine = true, acf_crew = true }

local WatchedClasses = ENT.ACF_WatchedClasses

ACF.Entities.AutoRegister(2026091001, function()
	MENU_FIELD("Number", "AgentMass", { Min = 2, Max = 10, Default = 3, Decimals = 1 }) -- kg of agent the bottle lets out
	LINKED_ENTITY_ARRAY_FIELD("Watched", { AcceptableClasses = WatchedClasses })
end, "Fire Extinguisher")

ACF.Diagnostics.Register("Warning", "extinguisher_empty", {
	Title = "Empty",
	Help  = "This extinguisher has already been used. It can be replenished by a supply crate.",
})

ACF.Diagnostics.Register("Warning", "extinguisher_unreached", {
	Title = "Out of Reach",
	Help  = "Some linked components can't be reached by this extinguisher if they catch fire. Move it closer, give it more "
		.. "agent, or clear the armor between them.",
})

--- @return number # gmu out from where it's released that an amount of agent floods at its design concentration.
function ACF.GetExtinguisherReach(Agent)
	local Volume = Agent / ACF.ExtinguisherAgentDensity -- m³

	return (3 * Volume / (4 * math.pi)) ^ (1 / 3) / ACF.InchToMeter
end

--- @return number # kg of a bottle made to hold this much agent, full (1) or empty (0).
function ACF.GetExtinguisherMass(AgentMass, Amount)
	local SHELL_RATIO = 1 -- kg of bottle per kg of agent it holds; vehicle halon bottles weigh about as much empty as their fill

	return AgentMass * (SHELL_RATIO + Amount)
end

--- @return vector # Size of a bottle holding this much agent, three times as long as it's wide.
function ACF.GetExtinguisherSize(AgentMass)
	local Volume   = AgentMass / ACF.ExtinguisherFillDensity * 1e-3 / ACF.InchToMeter ^ 3 -- in³
	local Diameter = (4 * Volume / (3 * math.pi)) ^ (1 / 3)

	return Vector(Diameter, Diameter, Diameter * 3)
end

cleanup.Register("acf_extinguisher")
