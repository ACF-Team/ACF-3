local Classes  = ACF.Classes
local Entities = Classes.Entities
Entities.CompatPatches = Entities.CompatPatches or {}

function Entities.RegisterCompatPatch(ClassName, Revision, Fn)
	local List = Entities.CompatPatches[ClassName]
	if not List then
		List = {}
		Entities.CompatPatches[ClassName] = List
	end
	List[Revision] = {Revision = Revision, Fn = Fn}
end

function Entities.RunCompatPatches(ClassName, FullEntityData)
	local List = Entities.CompatPatches[ClassName]
	if not List then return end
	for _, Patch in SortedPairsByMemberValue(List, "Revision") do
		Patch.Fn(FullEntityData)
	end
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