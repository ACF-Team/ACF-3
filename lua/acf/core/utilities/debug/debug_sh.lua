local ACF	= ACF
ACF.Debug	= {}

local CVar	= CreateConVar("acf_developer", 0, FCVAR_REPLICATED, "Extra wrapper convar for debugoverlay, requires 'developer 1' as well. 1: Both 2: Server 3: Client", 0, 3)

for k in pairs(debugoverlay) do
	ACF.Debug[k] = function(...)
		local var = CVar:GetInt()

		if var == 0 then return end
		if SERVER and var == 3 then return end
		if CLIENT and var == 2 then return end

		debugoverlay[k](...)
	end
end

local FunDebuggingFunctions = CreateConVar("acf_fundebuggingfuncs", "0", {FCVAR_CHEAT, FCVAR_REPLICATED}, "Fun ACF debugging functions, probably not a good idea to enable this unless you know what you're doing", 0, 1)
ACF.FunDebuggingFunctions = FunDebuggingFunctions