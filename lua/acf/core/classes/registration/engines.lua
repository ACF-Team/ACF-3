local Classes = ACF.Classes

Classes.Engines = Classes.Engines or {}

local Engines = Classes.Engines
local Entries = {}


function Engines.RegisterGroup(ID, Data)
	local Group = Classes.AddClassGroup(ID, Entries, Data)

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

function Engines.Register(ID, ClassID, Data)
	local Class = Classes.AddGrouped(ID, ClassID, Entries, Data)

	if not Class.Sound then
		Class.Sound = "vehicles/junker/jnk_fourth_cruise_loop2.wav"
	end

	--if not Class.TorqueCurve then
		--local Name = Class.Type or "GenericPetrol"
		--local Type = Types[Name] or Types.GenericPetrol

		--Class.TorqueCurve = Type.TorqueCurve
	--end

	--ACF.AddEnginePerformanceData(Class)

	return Class
end

Classes.AddGroupedFunctions(Engines, Entries)

do -- Discontinued function
	function ACF_DefineEngine(ID)
		print("Attempted to register engine " .. ID .. " with a discontinued function. Use ACF.RegisterEngine instead.")
	end
end
