local Hooks    = ACF.Utilities.Hooks
local Gamemode = gmod.GetGamemode()
local Queued   = {}

function Hooks.Add(Key, Function)
	if not isstring(Key) then return end
	if not isfunction(Function) then return end

	if Gamemode then
		Function(Gamemode)
	else
		Queued[Key] = Function
	end
end

hook.Add("PostGamemodeLoaded", "ACF Gamemode Hooks", function()
	Gamemode = gmod.GetGamemode()

	for Key, Function in pairs(Queued) do
		Function(Gamemode)

		Queued[Key] = nil
	end

	Queued = nil
end)
