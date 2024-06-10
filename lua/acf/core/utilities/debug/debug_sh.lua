local ACF	= ACF
ACF.Debug	= {}

local CVar	= CreateConVar("acf_developer", 0, FCVAR_REPLICATED, "Extra wrapper convar for debugoverlay, requires 'developer 1' as well. Only applies to ACF", 0, 1)

for k in pairs(debugoverlay) do
	ACF.Debug[k] = function(...)
		if CVar:GetBool() == false then return end

		debugoverlay[k](...)
	end
end