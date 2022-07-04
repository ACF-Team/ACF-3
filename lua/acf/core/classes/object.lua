local util     = util
local hook     = hook
local isstring = isstring
local istable  = istable
local Classes  = ACF.Classes
local Stored   = {}
local Queued   = {}


local function CreateInstance(Class)
	local New = {}

	setmetatable(New, { __index = table.Copy(Class) })

	if New.OnCalled then
		New:OnCalled()
	end

	return New
end

local function QueueBaseClass(ID, Base)
	if not Queued[Base] then
		Queued[Base] = { [ID] = true }
	else
		Queued[Base][ID] = true
	end
end

local function AttachMetaTable(Class, Base)
	local OldMeta = getmetatable(Class) or {}

	if Base then
		local BaseClass = Stored[Base]

		if BaseClass then
			Class.BaseClass = BaseClass
			OldMeta.__index = BaseClass
		else
			QueueBaseClass(Class.ID, Base)
		end
	end

	OldMeta.__call = function()
		return CreateInstance(Class)
	end

	setmetatable(Class, OldMeta)

	timer.Simple(0, function()
		if Class.OnLoaded then
			Class:OnLoaded()
		end

		hook.Run("ACF_OnClassLoaded", Class.ID, Class)

		Class.Loaded = true
	end)
end

function Classes.AddObject(ID, Base, Destiny)
	if not isstring(ID) then return end
	if not istable(Destiny) then return end
	if not Stored[ID] then Stored[ID] = {} end

	local Class = Stored[ID]

	Class.ID = ID

	AttachMetaTable(Class, Base)

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

hook.Add("ACF_OnClassLoaded", "ACF Model Precache", function(_, Class)
	if not isstring(Class.Model) then return end

	util.PrecacheModel(Class.Model)
end)
