local Entities = ACF.Entities
Entities.CompatPatches = Entities.CompatPatches or {}


-- ACF-3 and ACF-2 compatibility patches should be defined in date order, as to allow building off of each patch.
-- This works because ACF-3 is a direct fork of ACF-2 (with no breaking changes in ACF-2 as its no longer developed)
-- so its a clean and straightforward series of changes.
-- For ACE, they've done concurrent development alongside us. So ACE compat patches will need to run first.
-- The format for ACF-2/3 patches should be YYYYmmDDrr (year 4 digit, month 2 digit, day 2 digit, revision 2 digit)
-- For ACE patches, it should be incremental based on the classname, starting at -100000
function Entities.RegisterCompatPatch(ClassName, Revision, Fn)
	local List = Entities.CompatPatches[ClassName]
	if not List then
		List = {}
		Entities.CompatPatches[ClassName] = List
	end
	List[Revision] = {Revision = Revision, Fn = Fn}
end

function Entities.RunCompatPatches(ClassName, FullEntityData, AfterRevision)
	local List = Entities.CompatPatches[ClassName]
	if not List then return end
	for _, Patch in SortedPairsByMemberValue(List, "Revision") do
		if AfterRevision == nil or Patch.Revision >= AfterRevision then
			Patch.Fn(FullEntityData)
			if FullEntityData.Class ~= ClassName then
				-- The compat patch changed its class.
				Entities.RunCompatPatches(FullEntityData.Class, FullEntityData, Patch.Revision)
				return
			end
		end
	end
end

-- For links that used to be saved as entity modifiers
function Entities.MoveLinkModToUserData(Data, ModName, Field, SingleEntry, SubKey)
	local EntityMods = Data.EntityMods
	if not istable(EntityMods) or EntityMods[ModName] == nil then return end

	local Mod = EntityMods[ModName]
	EntityMods[ModName] = nil

	if SubKey and istable(Mod) then Mod = Mod[SubKey] end
	if not istable(Mod) then return end

	local UserData = istable(Data.ACF_UserData) and Data.ACF_UserData or {}
	Data.ACF_UserData = UserData

	local Existing = UserData[Field]

	if SingleEntry then
		if Existing ~= nil then return end

		local _, Index = next(Mod)
		if isnumber(Index) then UserData[Field] = Index end

		return
	end

	if Existing ~= nil and not istable(Existing) then return end

	local Indices, Seen = Existing or {}, {}

	for _, Index in ipairs(Indices) do Seen[Index] = true end

	for _, Index in pairs(Mod) do
		if isnumber(Index) and not Seen[Index] then
			Seen[Index] = true
			Indices[#Indices + 1] = Index
		end
	end

	UserData[Field] = Indices
end

-- For regular duplicator, monkeypatch
-- For advdupe2 though, we get a hook!
-- If only the basegame was nice enough to provide this...

local function RunPatch(FullEntityData)
	if not FullEntityData then return end
	Entities.RunCompatPatches(FullEntityData.Class, FullEntityData)
end

local OldDuplicator_CreateEntityFromTable = duplicator.CreateEntityFromTable
function duplicator.CreateEntityFromTable(Player, EntTable)
	RunPatch(EntTable)
	return OldDuplicator_CreateEntityFromTable(Player, EntTable)
end

-- Any Adv. Duplicator 2 from ~2 years ago will have this
-- If they're more out of date than that, not really our problem in my opinion.
hook.Add("AdvDupe2_PreCreateEntity", "ACF_AdvDupe2_PreCreateEntity", function(EntTable, _)
	RunPatch(EntTable)
end)