local FunDebuggingFunctions = ACF.FunDebuggingFunctions
local EntityImpulses = {
	detonate = {
		Callback = function(Player, Target, Args)
			local Targets
			local TargetOverride = string.lower(Args[2] or "")
			if string.Trim(TargetOverride) == "" then
				Targets = {Target}
			else
				if TargetOverride == "all" then
					Targets = ents.FindByClass("acf_*")
				elseif TargetOverride == "owned" then
					Targets = {}
					for _, Ent in ipairs(ents.GetAll()) do
						if IsValid(Ent) and Ent:CPPIGetOwner() == Player then
							Targets[#Targets + 1] = Ent
						end
					end
				elseif TargetOverride:match("^[0-9,]*$") then
					local EntIDs = string.Split(TargetOverride, ",")
					Targets = {}
					for I, EntID in ipairs(EntIDs) do
						EntID = string.Trim(EntID)
						Targets[I] = Entity(tonumber(EntID))
					end
				end
			end

			local DetonatedAtLeastOnce = false
			for _, T in ipairs(Targets) do
				if IsValid(T) and T.Detonate then
					DetonatedAtLeastOnce = true
					T:Detonate()
				end
			end
			if not DetonatedAtLeastOnce then
				Player:ChatPrint("No target or target cannot be detonated")
			end
		end
	}
}
if SERVER then
	concommand.Add("acf_entimpulse", function(Player, _, Args)
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