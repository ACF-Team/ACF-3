local util     = util
local hook     = hook
local isstring = isstring
local istable  = istable
local Classes  = ACF.Classes


function Classes.AddSimple(ID, Destiny, Data)
	if not isstring(ID) then return end
	if not istable(Destiny) then return end
	if not istable(Data) then return end

	local Class = Destiny[ID]

	if not Class then
		Class = {
			ID = ID,
		}

		Destiny[ID] = Class
	end

	for K, V in pairs(Data) do
		Class[K] = V
	end

	hook.Run("ACF_OnNewSimpleClass", ID, Class)

	return Class
end

function Classes.AddSimpleFunctions(Namespace, Entries)
	if not istable(Namespace) then return end
	if not istable(Entries) then return end

	-- Getter
	function Namespace.Get(ID)
		return isstring(ID) and Entries[ID] or nil
	end

	function Namespace.GetEntries()
		local Result = {}

		for _, V in pairs(Entries) do
			Result[V.ID] = V
		end

		return Result
	end

	function Namespace.GetList()
		local Result = {}
		local Count  = 0

		for _, V in pairs(Entries) do
			Count = Count + 1

			Result[Count] = V
		end

		return Result
	end

	-- Aliases
	function Namespace.AddAlias(ID, Alias)
		if not isstring(ID) then return end
		if not isstring(Alias) then return end

		Entries[Alias] = Entries[ID]
	end

	function Namespace.IsAlias(ID)
		local Data = isstring(ID) and Entries[ID]

		return Data and Data.ID ~= ID or false
	end
end

hook.Add("ACF_OnNewSimpleClass", "ACF Precache Model", function(_, Class)
	if not isstring(Class.Model) then return end

	util.PrecacheModel(Class.Model)
end)
