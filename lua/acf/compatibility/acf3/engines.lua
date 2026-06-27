-- This was for the autoregisterv2 conversion: migrate legacy flat engine dupe data (a top-level Engine
-- short id, e.g. "5.7-V8") into the nested ACF_UserData field set keyed by FQN.
ACF.Entities.RegisterCompatPatch("acf_engine", 2026062801, function(Data)
	if Data.ACF_UserData then return end

	local Old    = Data.Data or {}
	local Engine = Old.Engine or Data.Engine or Data.Id or "5.7-V8"
	local FQN    = "ACF.Engines." .. tostring(Engine)

	if not ACF.Classes.GetSubtypeByName("ACF.Engines.BaseEngine", FQN) then
		FQN = "ACF.Engines.5.7-V8"
	end

	Data.ACF_UserData = {
		Engine = {Type = FQN, Data = {}},
	}
end)
