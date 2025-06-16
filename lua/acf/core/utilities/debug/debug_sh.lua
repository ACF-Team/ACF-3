local ACF	= ACF
ACF.Debug	= {}

local CVar	= CreateConVar("acf_developer", 0, FCVAR_REPLICATED, "Extra wrapper convar for debugoverlay, requires 'developer 1' as well. Only applies to ACF", 0, 1)

for k in pairs(debugoverlay) do
	ACF.Debug[k] = function(...)
		if CVar:GetBool() == false then return end

		debugoverlay[k](...)
	end
end

local FunDebuggingFunctions = CreateConVar("acf_fundebuggingfuncs", "0", {FCVAR_CHEAT, FCVAR_REPLICATED}, "Fun ACF debugging functions, probably not a good idea to enable this unless you know what you're doing", 0, 1)

local EntityImpulses = {
	detonate = {
		Callback = function(Player, Target, _)
			if IsValid(Target) and Target.Detonate then return Target:Detonate() end
			Player:ChatPrint("No target or target cannot be detonated")
		end
	}
}
if SERVER then
	concommand.Add("acf_fundebug_entimpulse", function(Player, Cmd, Args)
		if not IsValid(Player) then return end
		if not FunDebuggingFunctions:GetBool() then Player:ChatPrint("Fun debugging functions aren't enabled...") return end
		local Target = Player:GetEyeTrace().Entity
		local Method = EntityImpulses[string.lower(Args[1])]
		if not Method then return end
		Method.Callback(Player, Target, Args)
	end, function(_, _, Args)
		if Args[2] == nil then
			local Arg = string.lower(Args[1] or "")
			local Recommendations = {}
			for k, _ in pairs(EntityImpulses) do
				if string.StartsWith(Arg, k) then
					Recommendations[#Recommendations + 1] = k
				end
			end
			return Recommendations
		else
			local Impulse = EntityImpulses[string.lower(Args[1])]
			if not Impulse then return end
			if not Impulse.Autocomplete then return end
			return Impulse.Autocomplete(Args)
		end
	end,
	"Runs an entity impulse on the current lookentity or via entity index depending on if the impulse type supports it. Requires acf_fundebuggingfuncs",
	{FCVAR_CHEAT})
end