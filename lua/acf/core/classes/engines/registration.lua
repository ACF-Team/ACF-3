local ACF     = ACF
local Classes = ACF.Classes
local Engines = Classes.Engines
local Types   = Classes.EngineTypes
local Entries = {}
local Loaded


local function AddPerformanceData(Engine)
	local Type = Types.Get(Engine.Type)

	if not Type then
		Type = Types.Get("GenericPetrol")

		Engine.Type = "GenericPetrol"
	end

	if not Engine.TorqueCurve then
		Engine.TorqueCurve = Type.TorqueCurve
	end

	ACF.AddEnginePerformanceData(Engine)
end

function Engines.Register(ID, Data)
	local Group = Classes.AddGroup(ID, Entries, Data)

	if not Group.LimitConVar then
		Group.LimitConVar = {
			Name   = "_acf_engine",
			Amount = 16,
			Text   = "Maximum amount of ACF engines a player can create."
		}
	end

	Classes.AddSboxLimit(Group.LimitConVar)

	return Group
end

function Engines.RegisterItem(ID, ClassID, Data)
	local Class = Classes.AddGroupItem(ID, ClassID, Entries, Data)

	if not Class.Sound then
		Class.Sound = "vehicles/junker/jnk_fourth_cruise_loop2.wav"
	end

	if Loaded then
		AddPerformanceData(Class)
	end

	return Class
end

Classes.AddGroupedFunctions(Engines, Entries)

do -- Adding engine performance data
	hook.Add("ACF_OnLoadAddon", "ACF Engine Performance", function()
		Loaded = true

		for Name in pairs(Engines.GetEntries()) do
			for _, Engine in pairs(Engines.GetItemEntries(Name)) do
				AddPerformanceData(Engine)
			end
		end

		hook.Remove("ACF_OnLoadAddon", "ACF Engine Performance")
	end)
end
