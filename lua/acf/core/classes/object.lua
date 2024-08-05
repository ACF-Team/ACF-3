local util     = util
local hook     = hook
local isstring = isstring
local istable  = istable
local Classes  = ACF.Classes
local Stored   = {}
local Queued   = {}

--- Creates a new instance of the provided class  
--- If the class has an "OnCalled" method defined, it will run that.
--- @param Class table The class to create an instance of
--- @return table # The newly created instance
local function CreateInstance(Class)
	local New = {}

	-- This simulates "instantiation" among other things (https://www.lua.org/pil/13.4.1.html)
	setmetatable(New, { __index = table.Copy(Class) })

	if New.OnCalled then
		New:OnCalled()
	end

	return New
end

--- Used to queue classes that are waiting for their base classes to be loaded
--- @param ID string The id of the class to queue
--- @param Base string The base class
local function QueueBaseClass(ID, Base)
	if not Queued[Base] then
		Queued[Base] = { [ID] = true }
	else
		Queued[Base][ID] = true
	end
end

--- Updates/Initializes a metatable for a class and "parents" it to a base class
--- @param Class table The class to be initialized/updated
--- @param Base string The base class of the provided class
local function AttachMetaTable(Class, Base)
	local OldMeta = getmetatable(Class) or {}

	if Base then
		local BaseClass = Stored[Base] -- Retrieve the base class from ID

		if BaseClass then
			Class.BaseClass = BaseClass -- Class' base class becomes BaseClass
			OldMeta.__index = BaseClass -- Class inherits from BaseClass
		else
			QueueBaseClass(Class.ID, Base)
		end
	end

	-- Update the "constructor" of the class to create an instance of the updated class
	OldMeta.__call = function()
		return CreateInstance(Class)
	end

	setmetatable(Class, OldMeta)

	-- A tick later, classes will be guaranteed to have been loaded.
	timer.Simple(0, function()
		if Class.OnLoaded then
			Class:OnLoaded()
		end

		hook.Run("ACF_OnLoadClass", Class.ID, Class)

		Class.Loaded = true
	end)
end

--- Creates a new object with the given ID, as a subclass of the Base class provided
--- @param ID string The ID of the new sub class to add
--- @param Base string The ID of the base class the sub class will inherit from
--- @param Destiny table A table that the new object will be indexed into, with the ID as key
--- @return table | nil # The created object
function Classes.AddObject(ID, Base, Destiny)
	if not isstring(ID) then return end
	if not istable(Destiny) then return end
	if not Stored[ID] then Stored[ID] = {} end

	local Class = Stored[ID]

	Class.ID = ID

	AttachMetaTable(Class, Base) -- Attach a metatable to "Class" with "Base" as parent

	-- If this class is a base class for other class(es), attach metatables to all its sub classes with itself as base class.
	if Queued[ID] then
		for K in pairs(Queued[ID]) do
			AttachMetaTable(Stored[K], ID)
		end

		Queued[ID] = nil
	end

	if Destiny then
		Destiny[ID] = Class
	end

	return Class
end

hook.Add("ACF_OnLoadClass", "ACF Model Precache", function(_, Class)
	if not isstring(Class.Model) then return end

	util.PrecacheModel(Class.Model)
end)
