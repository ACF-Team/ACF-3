-- Behaviour of the requirements, conditions an entity needs met to work, their player facing text is registered with ACF.Diagnostics
local ACF         = ACF
local Hints       = ACF.Hints
local Diagnostics = ACF.Diagnostics

local Requirements = {}

Hints.Requirements = Requirements

--- Registers a requirement, set on an entity with ENT:SetRequirement and shown as a warning in its overlay.
--- Its text goes to ACF.Diagnostics and its behaviour is kept here.
--- Behaviour fields: Draw (called with ACF.Debug, Entity, Data and Lifetime to show the owner the cause).
--- @param Id string Unique identifier
--- @param Text table The Diagnostics fields, such as Title, Detail and Help
--- @param Behaviour table|nil The behaviour fields
--- @return table|nil # The registered behaviour
function Hints.RegisterRequirement(Id, Text, Behaviour)
	if not Diagnostics.Register("Warning", Id, Text) then return end

	Behaviour        = Behaviour or {}
	Behaviour.Id     = Id
	Requirements[Id] = Behaviour

	return Behaviour
end
