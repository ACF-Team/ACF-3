-- Serverside debug drawing of the violations on an entity, shown to its owner
local ACF         = ACF
local Legality    = ACF.Legality
local Diagnostics = ACF.Diagnostics

local COLOR_DISABLE = Color(255, 50, 50)
local OVERLAP       = 0.2 -- Seconds each drawing outlives the next check, so it never flickers off between them

-- Halo, a label per violation with its countdown and whatever each restriction draws for itself
local function DrawViolations(Debug, Entity, Violations, Life)
	local Now  = CurTime()
	local Line = 0

	for _, Id in ipairs(Diagnostics.GetIds("Error")) do
		local Violation = Violations[Id]
		local Def       = Legality.Checks[Id]

		if Violation and not Def.Silent then
			local Title = Diagnostics.Describe(Id, Violation.Data)
			local Left  = math.ceil(Violation.Expires - Now)
			local Label = Def.Label and Def.Label(Violation.Data)

			if Line == 0 then Debug.Halo(Entity, Life, COLOR_DISABLE) end
			if Left > 0 then Title = Title .. " (" .. Left .. "s)" end

			Debug.EntityText(Entity, Line, Title, Life, COLOR_DISABLE)

			Line = Line + 1

			if Label then
				Debug.EntityText(Entity, Line, Label, Life, COLOR_DISABLE)

				Line = Line + 1
			end

			if Def.Draw then Def.Draw(Debug, Entity, Violation.Data, Life) end
		end
	end
end

-- Draws the violations for the owner as level 0 ACF.Debug calls, each check replaces the last drawing until they clear
function Legality.Draw(Entity, Force)
	local EntTbl     = Entity:GetTable()
	local Violations = EntTbl.ACF_Violations
	local Active     = Violations and next(Violations) ~= nil
	if not Active and not EntTbl.ACF_Drawn then return end

	-- Checks can also run on demand, those reuse the drawing that is still up unless something changed
	local Now = CurTime()
	if Active and not Force and (EntTbl.ACF_RedrawAt or 0) > Now then return end

	local Owner = Entity:CPPIGetOwner()
	if not IsValid(Owner) or not Owner:IsPlayer() then return end

	local Debug     = ACF.Debug
	local Due       = EntTbl.ACF_LegalDue or Now + 1
	local OldLevel  = Debug.GetDeveloperLevel()
	local OldTarget = Debug.SetTarget(Owner)
	local OldGroup, OldChannel = Debug.SetGroup(Entity)

	EntTbl.ACF_RedrawAt = Due
	EntTbl.ACF_Drawn    = Active and Owner:GetInfoNum("acf_legalvisuals", 1) ~= 0 or nil

	Debug.SetDeveloperLevel(0)
	Debug.Clear(Entity)

	if EntTbl.ACF_Drawn then DrawViolations(Debug, Entity, Violations, Due - Now + OVERLAP) end

	Debug.SetDeveloperLevel(OldLevel)
	Debug.SetTarget(OldTarget)
	Debug.SetGroup(OldGroup, OldChannel)
end
