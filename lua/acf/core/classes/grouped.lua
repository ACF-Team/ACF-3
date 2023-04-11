local util     = util
local hook     = hook
local isstring = isstring
local istable  = istable
local Classes  = ACF.Classes


function Classes.AddGroup(ID, Destiny, Data)
	if not isstring(ID) then return end
	if not istable(Destiny) then return end
	if not istable(Data) then return end

	local Group = Destiny[ID]

	if not Group then
		Group = {
			ID     = ID,
			Lookup = {},
			Items  = {},
			Count  = 0,
		}

		Destiny[ID] = Group
	end

	for K, V in pairs(Data) do
		Group[K] = V
	end

	hook.Run("ACF_OnNewClassGroup", ID, Group)

	return Group
end

function Classes.AddGroupItem(ID, GroupID, Destiny, Data)
	if not isstring(ID) then return end
	if not isstring(GroupID) then return end
	if not istable(Destiny) then return end
	if not istable(Data) then return end
	if not Destiny[GroupID] then return end

	local Group = Destiny[GroupID]
	local Class = Group.Lookup[ID]

	if not Class then
		Class = {
			ID      = ID,
			Class   = Group,
			ClassID = GroupID,
		}

		Group.Count              = Group.Count + 1
		Group.Lookup[ID]         = Class
		Group.Items[Group.Count] = Class
	end

	for K, V in pairs(Data) do
		Class[K] = V
	end

	hook.Run("ACF_OnNewGroupedClass", ID, Group, Class)

	return Class
end

function Classes.GetGroup(Namespace, ID)
	if not istable(Namespace) then return end
	if not isstring(ID) then return end

	local Class = Namespace.Get(ID)

	if Class then return Class end

	local Groups = Namespace.GetList()

	for _, Group in ipairs(Groups) do
		local Item = Namespace.GetItem(Group.ID, ID)

		if Item then return Group end
	end
end

function Classes.AddGroupedFunctions(Namespace, Entries)
	if not istable(Namespace) then return end
	if not istable(Entries) then return end

	Classes.AddSimpleFunctions(Namespace, Entries)

	-- Getters
	function Namespace.GetItem(ClassID, ID)
		local Group = isstring(ClassID) and Entries[ClassID]

		if not Group then return end

		return isstring(ID) and Group.Lookup[ID] or nil
	end

	function Namespace.GetItemEntries(ClassID)
		local Group = isstring(ClassID) and Entries[ClassID]

		if not Group then return end

		local Result = {}

		for _, V in pairs(Group.Lookup) do
			Result[V.ID] = V
		end

		return Result
	end

	function Namespace.GetItemList(ClassID)
		local Group = isstring(ClassID) and Entries[ClassID]

		if not Group then return end

		local Result = {}

		for K, V in ipairs(Group.Items) do
			Result[K] = V
		end

		return Result
	end

	-- Aliases
	function Namespace.AddItemAlias(GroupID, ID, Alias)
		local Group = isstring(GroupID) and Entries[GroupID]

		if not Group then return end
		if not isstring(ID) then return end
		if not isstring(Alias) then return end

		local Lookup = Group.Lookup

		Lookup[Alias] = Lookup[ID]
	end

	function Namespace.IsItemAlias(GroupID, ID)
		local Group = isstring(GroupID) and Entries[GroupID]

		if not Group then return false end

		local Data = isstring(ID) and Group.Lookup[ID]

		return Data and Data.ID ~= ID or false
	end
end

hook.Add("ACF_OnNewClassGroup", "ACF Precache Model", function(_, Group)
	if not isstring(Group.Model) then return end

	util.PrecacheModel(Group.Model)
end)

hook.Add("ACF_OnNewGroupedClass", "ACF Precache Model", function(_, _, Class)
	if not isstring(Class.Model) then return end

	util.PrecacheModel(Class.Model)
end)
