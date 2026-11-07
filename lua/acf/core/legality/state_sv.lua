-- Serverside legality state: evaluates restrictions, tracks violations and fires Enable/Disable
local ACF         = ACF
local Legality    = ACF.Legality
local Diagnostics = ACF.Diagnostics
local Checks      = Legality.Checks
local Order       = Diagnostics.GetIds("Error")
local TimerSimple = timer.Simple

local Evaluate

-- The id of the highest priority active violation
local function FirstViolation(Violations)
	for _, Id in ipairs(Order) do
		if Violations[Id] then return Id end
	end
end

do -- MARK: Evaluation
	local function RunCheck(Def, Entity, EntTbl)
		if not (Def and Def.Check) then return end
		if Def.Applies and not Def.Applies(Entity, EntTbl) then return end

		local Ok, Data, Timeout = Def.Check(Entity, EntTbl)
		if Ok then return end

		return Data or {}, Timeout
	end

	-- Runs every applicable restriction without changing state, returns the ordered failures
	function Evaluate(Entity)
		local Failures = {}

		if not ACF.LegalChecks then return Failures end
		if Entity.ACF_IsNotLegalityChecked then return Failures end

		local EntTbl = Entity:GetTable()

		for _, Id in ipairs(Order) do
			local Data, Timeout = RunCheck(Checks[Id], Entity, EntTbl)

			if Data then Failures[#Failures + 1] = { Id = Id, Data = Data, Timeout = Timeout } end
		end

		return Failures
	end

	Legality.Evaluate = Evaluate

	--- Title and detail of the first active violation, for telling a player why the entity is disabled.
	--- @param Entity entity
	--- @return string|nil, string|nil # Title and detail, nil when nothing is violated
	function Legality.GetReason(Entity)
		local Violations = Entity.ACF_Violations
		if not Violations then return end

		local Id = FirstViolation(Violations)

		if Id then return Diagnostics.Describe(Id, Violations[Id].Data) end
	end
end

do -- MARK: Violation state
	local function GetViolations(EntTbl)
		local Violations = EntTbl.ACF_Violations

		if not Violations then
			Violations = {}
			EntTbl.ACF_Violations = Violations
		end

		return Violations
	end

	local function ResolveTimeout(Id, Timeout)
		Timeout = tonumber(Timeout) or (Checks[Id] and Checks[Id].Timeout) or ACF.IllegalDisableTime

		return math.max(Timeout, 0)
	end

	-- Adds or updates a violation, returns whether anything the client sees has changed
	local function Raise(Entity, Id, Data, Timeout, Extend)
		local Violations = GetViolations(Entity:GetTable())
		local Existing   = Violations[Id]
		local Expires    = CurTime() + Timeout

		if not Existing then
			Violations[Id] = { Data = Data, Expires = Expires }

			Legality.NotifyOwner(Entity, Id)

			return true
		end

		if Extend then Existing.Expires = math.max(Existing.Expires, Expires) end

		-- Nested tables are compared by value, lists of targets or planes are rebuilt on every check
		if ACF.SameData(Existing.Data, Data) then return false end

		local ReasonChanged = (Existing.Data and Existing.Data.Title) ~= (Data and Data.Title)

		Existing.Data = Data

		if ReasonChanged then Legality.NotifyOwner(Entity, Id) end

		return true
	end

	-- Mirrors the violations onto Entity.Disabled and fires Enable or Disable when the restricted state flips
	local function Apply(Entity, Changed)
		local EntTbl     = Entity:GetTable()
		local Violations = EntTbl.ACF_Violations or {}
		local FirstId    = FirstViolation(Violations)

		local Restricted = FirstId ~= nil
		local Flipped    = Restricted ~= (EntTbl.ACF_Restricted == true)

		if not (Changed or Flipped) then return end

		if Restricted then
			local Title, Detail = Diagnostics.Describe(FirstId, Violations[FirstId].Data)

			EntTbl.Disabled = { Reason = Title, Message = Detail }
		else
			EntTbl.Disabled = nil
		end

		if Flipped then
			EntTbl.ACF_Restricted = Restricted or nil

			if Restricted then
				if EntTbl.Disable then Entity:Disable() end
			elseif EntTbl.Enable then
				Entity:Enable()
			end
		end

		if EntTbl.UpdateOverlay then Entity:UpdateOverlay(true) end
	end

	-- Keeps a single pending re-check per entity
	local function Schedule(Entity, Delay)
		local EntTbl = Entity:GetTable()
		local Due    = CurTime() + Delay

		if EntTbl.ACF_LegalDue and EntTbl.ACF_LegalDue <= Due then return end

		EntTbl.ACF_LegalDue = Due

		TimerSimple(Delay, function()
			if not IsValid(Entity) then return end
			if Entity.ACF_LegalDue ~= Due then return end -- Superseded by an earlier check

			Entity.ACF_LegalDue = nil

			Legality.Check(Entity)
		end)
	end

	--- Re-evaluates the entity, a violation clears once its check passes and its timeout has elapsed.
	--- @param Entity entity
	--- @return boolean # Whether the entity is free of disabling violations
	function Legality.Check(Entity)
		local EntTbl = Entity:GetTable()
		if EntTbl.ACF_IsNotLegalityChecked then return true end

		-- Entities that are destroyed are re polled but not evaluated until they are alive again.
		if ACF.IsDestroyed(Entity) then
			Schedule(Entity, math.Rand(1, 3))

			return not EntTbl.ACF_Restricted
		end

		local Violations = GetViolations(EntTbl)
		local Failing    = {}
		local Changed    = false
		local Now        = CurTime()

		for _, Failure in ipairs(Evaluate(Entity)) do
			local Id = Failure.Id

			Failing[Id] = true

			if Raise(Entity, Id, Failure.Data, ResolveTimeout(Id, Failure.Timeout), Checks[Id] and Checks[Id].Linger) then Changed = true end
		end

		for Id, Violation in pairs(Violations) do
			if not Failing[Id] and Now >= Violation.Expires then
				Violations[Id] = nil
				Changed        = true
			end
		end

		Apply(Entity, Changed)

		if ACF.LegalChecks or next(Violations) then Schedule(Entity, math.Rand(1, 3)) end

		Legality.Draw(Entity, Changed)

		return not EntTbl.ACF_Restricted
	end

	ACF.CheckLegal = Legality.Check -- Public name kept for entities and other addons

	--- Raises a violation caught as it happens, such as a blocked call, which cannot be re-checked so it expires after its timeout.
	--- @param Entity entity
	--- @param Id string A registered restriction id
	--- @param Data table|nil Per-violation data sent to the owner
	--- @param Timeout number|nil Overrides the restriction's timeout
	function Legality.Report(Entity, Id, Data, Timeout)
		if not Checks[Id] then error("Unknown legality restriction '" .. tostring(Id) .. "'") end
		if Entity.ACF_IsNotLegalityChecked then return end -- Check never runs on these, so nothing would clear it

		Data    = Data or {}
		Timeout = ResolveTimeout(Id, Timeout)

		-- Repeats only push the expiry back, detours can report every tick on every contraption member
		local Existing = Entity.ACF_Violations and Entity.ACF_Violations[Id]
		local Now      = CurTime()

		if Existing and (ACF.SameData(Existing.Data, Data) or Now - (Existing.Updated or 0) < 1) then
			Existing.Expires = math.max(Existing.Expires, Now + Timeout)

			return
		end

		local Changed = Raise(Entity, Id, Data, Timeout, true)

		Entity.ACF_Violations[Id].Updated = Now

		Apply(Entity, Changed)
		Schedule(Entity, math.Rand(1, 3))
		Legality.Draw(Entity, Changed)
	end

	--- Adds the active violations to an entity's overlay.
	--- @param Entity entity
	--- @param State table The overlay state being built
	function Legality.AddOverlayLines(Entity, State)
		Diagnostics.AddOverlayLines(State, "Error", Entity.ACF_Violations, "Data")
	end
end
