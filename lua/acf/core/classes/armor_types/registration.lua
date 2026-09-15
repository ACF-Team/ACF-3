local hook     = hook
local isstring = isstring
local Classes  = ACF.Classes

Classes.ArmorTypes = Classes.ArmorTypes or {}

local ArmorTypes = Classes.ArmorTypes
local Entries    = Classes.GetOrCreateEntries(ArmorTypes)

--- Registers an armor type.
--- Armor types stay keyed by a plain ID rather than a fully qualified class name, because that ID is
--- what a convex stores as its material and what gets networked, so it has to survive serialization.
--- @param ID string The ID of the armor type.
--- @param Base string|nil ID of an armor type to inherit unset fields from.
--- @return table|nil Class The registered armor type.
function ArmorTypes.Register(ID, Base)
	if not isstring(ID) then return end

	local Class = Entries[ID] or {}

	Class.ID    = ID
	Entries[ID] = Class

	if Base then
		local BaseClass = Entries[Base]

		if BaseClass then
			Class.BaseClass = BaseClass

			setmetatable(Class, { __index = BaseClass })
		end
	end

	-- Callers define OnLoaded on the returned table, so it cannot be run until this returns.
	timer.Simple(0, function()
		if Class.OnLoaded then Class:OnLoaded() end

		hook.Run("ACF_OnLoadClass", ID, Class)

		Class.Loaded = true
	end)

	return Class
end

--- Gets the armor type with the given ID.
--- @param ID string
--- @return table|nil
function ArmorTypes.Get(ID)
	return isstring(ID) and Entries[ID] or nil
end

--- Gets every armor type, keyed by ID.
--- @return table<string, table>
function ArmorTypes.GetEntries()
	local Result = {}

	for _, V in pairs(Entries) do
		Result[V.ID] = V
	end

	return Result
end

--- Gets the stored entries table itself, so the registry can restore itself on a reload.
--- @return table
function ArmorTypes.GetStored()
	return Entries
end

--- Gets every armor type as an array.
--- @return table<number, table>
function ArmorTypes.GetList()
	local Result = {}
	local Count  = 0

	for _, V in pairs(Entries) do
		Count = Count + 1
		Result[Count] = V
	end

	return Result
end
