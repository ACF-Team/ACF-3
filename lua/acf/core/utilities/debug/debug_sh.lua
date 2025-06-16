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
				else
					local EntID = tonumber(TargetOverride)
					if EntID ~= nil then Targets = {Entity(EntID)} end
				end
			end

			local DetonatedAtLeastOnce = false
			for _, T in ipairs(Targets) do
				if IsValid(T) and T.Detonate then
					DetonDetonatedAtLeastOnceated = true
					T:Detonate()
				end
			end
			if not DetonatedAtLeastOnce then
				Player:ChatPrint("No target or target cannot be detonated")
			end
		end
	},
	-- needs more work, now doesnt work at all right now
	shoot = {
		Callback = function(Player, Target, Args)
			local Now = Args[2] == "now"

			if IsValid(Target) and Target.Shoot then
				if Target.CanFire then
					local oldFiring = Target.Firing
					Target.Firing = true
					if Target.CurrentShot > 0 then
						Target:Shoot()
						Target.Firing = oldFiring
						return
					elseif Now then
						if Target.State == "Loading" and Target.ReloadTimer then
							Target.ReloadTimer:Cancel(true)
						else
							Target:Load(true)
						end
					else
						Target.Firing = oldFiring
						Player:ChatPrint("Target cannot shoot right now.")
					end
				elseif Target.CanShoot then
					return Target:Shoot()
				else
					Player:ChatPrint("Don't know how to shoot this target.")
				end
			else
				Player:ChatPrint("No target.")
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