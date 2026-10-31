-- Serverside debug drawing of the unmet requirements of an entity, shown to its owner
-- Drawn on their own channel, so the legality drawings of the same entity are left alone
local ACF         = ACF
local Hints       = ACF.Hints
local Diagnostics = ACF.Diagnostics

local CHANNEL    = 1
local INTERVAL   = 1 -- Seconds between redraws, so drawings follow the entities that change between requirement checks
local OVERLAP    = 0.2 -- Seconds each drawing outlives the next redraw, so it never flickers off between them
local COLOR_WARN = Color(255, 170, 0)

local Tracked = {} -- Entities with an unmet requirement that draws something

local function HasDrawing(Entity)
	local Unmet = Entity.ACF_UnmetRequirements
	if not Unmet then return false end

	local Requirements = Hints.Requirements

	for Id in pairs(Unmet) do
		if Requirements[Id].Draw then return true end
	end

	return false
end

-- Labels go upwards from the line above the entity, the legality labels go downwards from it
local function DrawRequirements(Debug, Entity, Life)
	local Unmet        = Entity.ACF_UnmetRequirements
	local Requirements = Hints.Requirements
	local Line         = -1

	for _, Id in ipairs(Entity.ACF_UnmetOrder) do
		local Def = Requirements[Id]

		if Def.Draw then
			local Data  = Unmet[Id]
			local Title = Diagnostics.Describe(Id, Data)

			Debug.EntityText(Entity, Line, Title, Life, COLOR_WARN)
			Def.Draw(Debug, Entity, Data, Life)

			Line = Line - 1
		end
	end
end

-- Replaces the drawing of the entity's unmet requirements as level 1 ACF.Debug calls, or clears it
local function Draw(Entity)
	local EntTbl = Entity:GetTable()
	local Owner  = Entity:CPPIGetOwner()
	local Show   = IsValid(Owner) and Owner:IsPlayer() and Owner:GetInfoNum("acf_legalvisuals", 1) ~= 0
		and HasDrawing(Entity) and Entity:ACF_ShowRequirements()

	if not (Show or EntTbl.ACF_RequirementsDrawn) then return end
	if not (IsValid(Owner) and Owner:IsPlayer()) then return end

	local Debug                = ACF.Debug
	local OldLevel             = Debug.GetDeveloperLevel()
	local OldTarget            = Debug.SetTarget(Owner)
	local OldGroup, OldChannel = Debug.SetGroup(Entity, CHANNEL)

	EntTbl.ACF_RequirementsDrawn = Show or nil

	Debug.SetDeveloperLevel(1)
	Debug.Clear(Entity, CHANNEL)

	if Show then DrawRequirements(Debug, Entity, INTERVAL + OVERLAP) end

	Debug.SetDeveloperLevel(OldLevel)
	Debug.SetTarget(OldTarget)
	Debug.SetGroup(OldGroup, OldChannel)
end

--- Redraws the unmet requirements of an entity now, called when the set of unmet requirements changes.
--- @param Entity entity
function Hints.DrawRequirements(Entity)
	if HasDrawing(Entity) then Tracked[Entity] = true end

	Draw(Entity)
end

local FLASH_CHANNEL = 2 -- Kept apart from the legality and requirement drawings, which redraw on their own

--- Draws a short lived picture of a problem for the entity's owner, for problems that happen once, such as a refused link.
--- Each flash replaces the last one of the same entity.
--- @param Entity entity
--- @param Life number Seconds the drawing stays up
--- @param DrawFunc function Called with ACF.Debug and Life to draw it
function Hints.Flash(Entity, Life, DrawFunc)
	local Owner = Entity:CPPIGetOwner()
	if not (IsValid(Owner) and Owner:IsPlayer()) or Owner:GetInfoNum("acf_legalvisuals", 1) == 0 then return end

	local Debug                = ACF.Debug
	local OldLevel             = Debug.GetDeveloperLevel()
	local OldTarget            = Debug.SetTarget(Owner)
	local OldGroup, OldChannel = Debug.SetGroup(Entity, FLASH_CHANNEL)

	Debug.SetDeveloperLevel(1)
	Debug.Clear(Entity, FLASH_CHANNEL)

	DrawFunc(Debug, Life)

	Debug.SetDeveloperLevel(OldLevel)
	Debug.SetTarget(OldTarget)
	Debug.SetGroup(OldGroup, OldChannel)
end

timer.Create("ACF Requirement Drawing", INTERVAL, 0, function()
	for Entity in pairs(Tracked) do
		if not IsValid(Entity) then
			Tracked[Entity] = nil
		else
			if not HasDrawing(Entity) then Tracked[Entity] = nil end

			Draw(Entity)
		end
	end
end)
