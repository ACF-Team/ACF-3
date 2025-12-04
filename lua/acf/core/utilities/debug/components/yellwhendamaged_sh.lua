local FunDebuggingFunctions = ACF.FunDebuggingFunctions
local RequestedYellEnts = {}

local function ProcessLastTyped_YellAbout(Player, Request)
	local LUT = {}
	local Pieces = string.Split(Request, " ")
	for _, Piece in ipairs(Pieces) do
		if Piece == '*' then
			LUT['*'] = true
			break
		end
		local Idx = tonumber(Piece)
		if Idx then LUT[Idx] = true end
	end

	if SERVER then
		if #Pieces == 0 then
			RequestedYellEnts[Player] = nil
		else
			RequestedYellEnts[Player] = LUT
		end
		Player:ChatPrint("Now tracking: " .. table.concat(table.GetKeys(LUT), ", "))
	else
		if #Pieces == 0 then
			RequestedYellEnts = nil
		else
			RequestedYellEnts = LUT
		end
	end
end

if SERVER then
	concommand.Add("acf_yellwhendamaged", function(Player, _, _, Request)
		if Player == NULL then print("Cannot use this command from a dedicated server!") return end
		if not FunDebuggingFunctions:GetBool() then Player:ChatPrint("Fun debugging functions aren't enabled...") return end
		ProcessLastTyped_YellAbout(Player, Request)
	end, nil, "ACF damage notification for testing", FCVAR_USERINFO)

	local function DoYell(Entity, _, _)
		for Player, LUT in pairs(RequestedYellEnts) do
			if LUT['*'] or LUT[Entity:EntIndex()] then
				Player:ChatPrint("Damage occurred on " .. tostring(Entity))
			end
		end
	end

	local function EvaluateCurrentDebuggingState(Value)
		if (tonumber(Value) or 0) >= 1 then
			hook.Add("ACF_OnDamageEntity", "ACF_FunDebuggingFuncs_YellWhenDamaged", DoYell)
		else
			hook.Remove("ACF_OnDamageEntity", "ACF_FunDebuggingFuncs_YellWhenDamaged")
		end
	end

	cvars.AddChangeCallback("acf_fundebuggingfuncs", function(_, _, Value)
		EvaluateCurrentDebuggingState(Value)
	end)

	EvaluateCurrentDebuggingState(FunDebuggingFunctions:GetString())
end