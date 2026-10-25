local ACF      = ACF
local Registry = ACF.ImplicitLinkRegistry or {}
local BySource = Registry.BySource or {} -- Source class -> { ImplicitLinkData, ... }
local ByTarget = Registry.ByTarget or {} -- Target class -> { ImplicitLinkData, ... }
local Fields   = Registry.Fields or {}   -- Source class -> Field -> { Class linked into it -> true }

ACF.ImplicitLinkRegistry = Registry
Registry.BySource        = BySource
Registry.ByTarget        = ByTarget
Registry.Fields          = Fields

-- Entities joining a CFW contraption link to the pools they implicitly link to and are checked by the pools linking to them

do -- MARK: Registration
	--- @class ACF.ImplicitLinkData
	--- @field Source string Class holding the link, filled in on registration
	--- @field Target string Class being linked to, filled in on registration
	--- @field Field string Field on the source holding its links, which may also hold links to other classes
	--- @field Single boolean? Only one entity is linked, and only when one candidate stands out
	--- @field Filter (fun(Source: table, Candidate: table): boolean)? Candidates failing this are never considered
	--- @field Rank (fun(Source: table, Candidate: table): number)? Single links go to the unique highest ranked candidate

	local function Replace(Index, Class, Data)
		local List = Index[Class] or {}

		Index[Class] = List

		for I, Existing in ipairs(List) do
			if Existing.Source == Data.Source and Existing.Target == Data.Target then
				table.remove(List, I)

				break
			end
		end

		List[#List + 1] = Data
	end

	--- Makes every Source entity link to the Target entities on its CFW contraption.
	--- The class link and check functions still decide whether each link is allowed, same as a manual link.
	--- @param Source string The class holding the link in Options.Field, which may be either side of the registered class link
	--- @param Target string The class being linked to
	--- @param Options ACF.ImplicitLinkData
	function ACF.RegisterClassImplicitLink(Source, Target, Options)
		local Data = table.Copy(Options)

		Data.Source = Source
		Data.Target = Target

		-- Checked once every file has registered its links, since the class link may come later or from another file
		timer.Simple(0, function()
			local Links   = ACF.ClassLinks
			local Forward = Links[Source] and Links[Source][Target]
			local Reverse = Links[Target] and Links[Target][Source]

			if not (Forward and Forward.Link) and not (Reverse and Reverse.Link) then
				ErrorNoHalt(("ACF: Implicit link from %s to %s has no class link, register one with ACF.RegisterClassLink\n"):format(Source, Target))
			end
		end)

		Replace(BySource, Data.Source, Data)
		Replace(ByTarget, Data.Target, Data)

		local SourceFields = Fields[Data.Source] or {}
		local Classes      = SourceFields[Data.Field] or {}

		Fields[Data.Source]      = SourceFields
		SourceFields[Data.Field] = Classes
		Classes[Data.Target]     = true
	end

	--- Returns the fields a class holds implicit links in. Explicit links to the same classes go in them too.
	--- @param Class string The class holding the links
	--- @return table<string, true> # A new set of field names
	function ACF.GetImplicitLinkFields(Class)
		local Result = {}

		for Field in pairs(Fields[Class] or {}) do
			Result[Field] = true
		end

		return Result
	end
end

do -- MARK: Resolution
	local Pending    = {} -- Entities waiting to be resolved, in no particular order since links have none
	local Processing = false

	local function Involved(Class) return BySource[Class] ~= nil or ByTarget[Class] ~= nil end

	local function PickBest(Entity, Data, Candidates)
		local Rank = Data.Rank

		-- Without a rank, several candidates for a single link are ambiguous and the player has to pick
		if not Rank then return {} end

		local Best, BestScore, Tied

		for Candidate in pairs(Candidates) do
			local Score = Rank(Entity, Candidate)

			if not BestScore or Score > BestScore then
				Best, BestScore, Tied = Candidate, Score, false
			elseif Score == BestScore then
				Tied = true
			end
		end

		if Tied then return {} end

		return { [Best] = true }
	end

	local function GetCandidates(Entity, Data, Contraption)
		local Owner  = Entity:CPPIGetOwner()
		local Filter = Data.Filter
		local Result = {}
		local Count  = 0

		for Candidate in pairs(Contraption:EntitiesByClass(Data.Target)) do
			if IsValid(Candidate) and Candidate:CPPIGetOwner() == Owner and (not Filter or Filter(Entity, Candidate)) then
				Result[Candidate] = true
				Count = Count + 1
			end
		end

		if Data.Single and Count > 1 then return PickBest(Entity, Data, Result) end

		return Result
	end

	local function ResolveSource(Entity, Data, Contraption)
		-- Single only limits how many get linked, the field itself may still be a set such as crew Targets
		local Links    = ACF.GetFieldLinkEntities(Entity[Data.Field])
		local Explicit = false

		for Linked in pairs(Links) do
			if not ACF.IsImplicitLink(Entity, Linked) then
				Explicit = true

				break
			end
		end

		local Candidates = Explicit and {} or GetCandidates(Entity, Data, Contraption)

		-- Partners on another contraption are mid merge, leaving drops them otherwise
		for Linked in pairs(Links) do
			if ACF.IsImplicitLink(Entity, Linked) and Linked:GetClass() == Data.Target and not Candidates[Linked]
				and (Explicit or Linked:CFW_GetContraption() == Contraption) then
				ACF.PerformClassUnlink(Entity, Linked)
			end
		end

		for Candidate in pairs(Candidates) do
			if not Links[Candidate] then
				ACF.PerformClassLink(Entity, Candidate, false, true)
			end
		end
	end

	-- Links the entity to the pools it implicitly links to, then lets the pools linking to it consider it
	local function ResolveEntity(Entity)
		if not IsValid(Entity) then return end

		local Contraption = Entity:CFW_GetContraption()

		if not Contraption then return end

		local Class = Entity:GetClass()

		for _, Data in ipairs(BySource[Class] or {}) do
			ResolveSource(Entity, Data, Contraption)
		end

		for _, Data in ipairs(ByTarget[Class] or {}) do
			for Source in pairs(Contraption:EntitiesByClass(Data.Source)) do
				ResolveSource(Source, Data, Contraption)
			end
		end
	end

	local function Enqueue(Entity)
		if IsValid(Entity) then Pending[Entity] = true end
	end

	-- Links made while processing queue their ends, so links depending on other links settle in the same call
	local function Process()
		if Processing then return end

		Processing = true

		local Entity = next(Pending)

		while Entity do
			Pending[Entity] = nil

			ProtectedCall(ResolveEntity, Entity)

			Entity = next(Pending)
		end

		Processing = false
	end

	local function Resolve(A, B)
		Enqueue(A)
		Enqueue(B)
		Process()
	end

	-- A tick later, since unlink callers often loop over the link table and updates are not finished yet
	local function ResolveLater(A, B)
		timer.Simple(0, function() Resolve(A, B) end)
	end

	hook.Add("cfw.contraption.entityAdded", "ACF_ImplicitLinks", function(_, Entity)
		if Involved(Entity:GetClass()) then Resolve(Entity) end
	end)

	hook.Add("cfw.contraption.entityRemoved", "ACF_ImplicitLinks", function(Contraption, Entity)
		local Class = Entity:GetClass()

		if not Involved(Class) then return end

		-- Implicit links only hold within a contraption
		for Linked in pairs(ACF.GetImplicitLinks(Entity)) do
			if Contraption.ents[Linked] then ACF.PerformClassUnlink(Entity, Linked) end
		end

		-- Sources left behind may now have a single candidate where there were several
		for _, Data in ipairs(ByTarget[Class] or {}) do
			for Source in pairs(Contraption:EntitiesByClass(Data.Source)) do
				Enqueue(Source)
			end
		end

		Process()
	end)

	-- Each end drops what the explicit link will turn off anyway: implicit links to the other end's class, and the rest of the field it goes in
	-- If the link then fails, the unlinks bring them back a tick later
	hook.Add("ACF_PreClassLink", "ACF_ImplicitLinks", function(Source, Target)
		for _, Pair in ipairs({ { Source, Target }, { Target, Source } }) do
			local Entity, OtherClass = Pair[1], Pair[2]:GetClass()
			local InTheWay           = { [OtherClass] = true }

			for _, Classes in pairs(Fields[Entity:GetClass()] or {}) do
				if Classes[OtherClass] then table.Merge(InTheWay, Classes) end
			end

			for Linked in pairs(ACF.GetImplicitLinks(Entity)) do
				if InTheWay[Linked:GetClass()] then ACF.PerformClassUnlink(Entity, Linked) end
			end
		end
	end)

	-- New links can satisfy filters reading other links, and explicit ones turn their source's implicit ones off
	hook.Add("ACF_OnClassLink", "ACF_ImplicitLinks", function(A, B)
		if Involved(A:GetClass()) or Involved(B:GetClass()) then Resolve(A, B) end
	end)

	-- Links dropped by a failed check stay down, since linking runs the same check
	hook.Add("ACF_OnClassUnlink", "ACF_ImplicitLinks", function(A, B)
		if Involved(A:GetClass()) or Involved(B:GetClass()) then ResolveLater(A, B) end
	end)

	-- A reconfigured entity can become compatible with entities it never linked to, so no unlink would bring it back
	hook.Add("ACF_OnUpdateEntity", "ACF_ImplicitLinks", function(Class, Entity)
		if Involved(Class) then ResolveLater(Entity) end
	end)
end
