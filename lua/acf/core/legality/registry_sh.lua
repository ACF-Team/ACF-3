-- Behaviour of the legality restrictions, their player facing text is registered with ACF.Diagnostics
local ACF         = ACF
local Legality    = ACF.Legality
local Diagnostics = ACF.Diagnostics

local Checks = {}

Legality.Checks = Checks

--- Registers a restriction, its text goes to ACF.Diagnostics and its behaviour is kept here.
--- Behaviour fields: Check (returns Ok, Data), Applies, Timeout, Linger (clears Timeout after the last failure), Shame,
--- NotifyDelay, Silent (overlay only), Draw (called with ACF.Debug, Entity, Data and Lifetime to draw the cause) and Label.
--- @param Id string Unique identifier
--- @param Text table The Diagnostics fields, such as Title, Detail and Help
--- @param Behaviour table The behaviour fields
--- @return table|nil # The registered behaviour
function Legality.RegisterRestriction(Id, Text, Behaviour)
	if not Diagnostics.Register("Error", Id, Text) then return end

	Behaviour.Id = Id
	Checks[Id]   = Behaviour

	return Behaviour
end
