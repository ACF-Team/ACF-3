local util     = util
local hook     = hook
local isstring = isstring
local istable  = istable
local Classes  = ACF.Classes

--- Registers a group
--- @param ID string The ID of the group
--- @param Destiny table The table to store the group in
--- @param Data table The data of the group
--- @return table | nil Group The created group
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

	hook.Run("ACF_OnCreateGroup", ID, Group)

	return Group
end

--- Registers a group item under a group
--- @param ID string The ID of the item to add to the group
--- @param GroupID string The ID of the group previously created using Class.AddGroup
--- @param Destiny string The table to store the group item in (should be the same as the group)
--- @param Data table The data of the group item
--- @return table | nil Class The created group item
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

	hook.Run("ACF_OnCreateGroupItem", ID, Group, Class)

	return Class
end

--- Gets a group given its ID and the namespace it's stored in  
--- If no such group exists, it will instead check for a group that has a group item with the given ID
--- @param Namespace string The namespace to lookup the group in
--- @param ID string The ID of the group, or the ID of a group item
--- @return table | nil # The group if found
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

--- Indexes the groups stored in Entries into a new Namespace, with helper functions
--- @param Namespace table The table that will receive the new functions
--- @param Entries table The table storing groups
function Classes.AddGroupedFunctions(Namespace, Entries)
	if not istable(Namespace) then return end
	if not istable(Entries) then return end

	-- Note that all the functions for simple class namespaces apply too.
	Classes.AddSimpleFunctions(Namespace, Entries)

	-- Getters

	--- Gets a group item from a group in the namespace
	--- @param ClassID string The ID of the group
	--- @param ID string The ID of the group item
	--- @return table | nil # A group item
	function Namespace.GetItem(ClassID, ID)
		local Group = isstring(ClassID) and Entries[ClassID]

		if not Group then return end

		return isstring(ID) and Group.Lookup[ID] or nil
	end

	--- Gets all the group items for a given group in the namespace  
	--- If aliases exist in the namespace, they will be ignored in the returned table
	--- @param ClassID string The ID of the group to explore
	--- @return table<string,table> # A table mapping item's IDs to themselves
	function Namespace.GetItemEntries(ClassID)
		local Group = isstring(ClassID) and Entries[ClassID]

		if not Group then return end

		local Result = {}

		for _, V in pairs(Group.Lookup) do
			Result[V.ID] = V
		end

		return Result
	end

	--- Gets the stored entries table
	--- Returns the original reference
	--- Allows the class system to restore itself later
	--- @return table # The stored entries table
	function Namespace.GetStored() return Entries end

	--- Gets all the group items for a given group in the namespace  
	--- If aliases exist in the namespace, they will be included in the returned table
	--- @param ClassID string The ID of the group to explore
	--- @return table<number, table> # An "array" (e.g. {class1,class2,...}) containing group items.
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

	--- Adds an alias to a group item
	--- @param GroupID string # The ID of the group the group item belongs to
	--- @param ID string # The ID of the group item to make an alias of
	--- @param Alias string # The alias to apply to the given group item
	--- @param Overrides? table # An optional table of overrides to alter the behavior of the alias
	function Namespace.AddItemAlias(GroupID, ID, Alias, Overrides)
		local Group = isstring(GroupID) and Entries[GroupID]

		if not Group then return end
		if not isstring(ID) then return end
		if not isstring(Alias) then return end

		local Lookup = Group.Lookup

		-- NOTE: This is commented out to prevent cyclic references with the regular duplicator
		-- Try to add this back in if it seems to be useful for something
		-- Lookup[Alias] = Lookup[ID]

		if istable(Overrides) then
			-- Make a shallow copy of the table, then apply overrides
			Lookup[Alias] = {}

			for Key, Value in pairs(Lookup[ID]) do
				Lookup[Alias][Key] = Value
			end

			for Key, Value in pairs(Overrides) do
				Lookup[Alias][Key] = Value
			end
		else
			Lookup[Alias] = Lookup[ID]
		end
	end

	--- Checks whether an ID is an alias of a group item
	--- @param GroupID string # The ID of the group the group item belongs to
	--- @param ID string # The ID to check
	--- @return boolean # Whether the ID is an alias of a group item
	function Namespace.IsItemAlias(GroupID, ID)
		local Group = isstring(GroupID) and Entries[GroupID]

		if not Group then return false end

		local Data = isstring(ID) and Group.Lookup[ID]

		return Data and Data.ID ~= ID or false
	end
end

hook.Add("ACF_OnCreateGroup", "ACF Precache Model", function(_, Group)
	if not isstring(Group.Model) then return end

	util.PrecacheModel(Group.Model)
end)

hook.Add("ACF_OnCreateGroupItem", "ACF Precache Model", function(_, _, Class)
	if not isstring(Class.Model) then return end

	util.PrecacheModel(Class.Model)
end)
