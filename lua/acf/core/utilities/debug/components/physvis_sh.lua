local FunDebuggingFunctions = ACF.FunDebuggingFunctions
if SERVER then ACF_PHYSICSVISTEST_LASTREQUESTEDENTS = ACF_PHYSICSVISTEST_LASTREQUESTEDENTS or {} end
local RequestedEnts = SERVER and ACF_PHYSICSVISTEST_LASTREQUESTEDENTS or nil

local function ProcessLastTyped(Player, Request)
	local LUT = {}
	local Pieces = string.Split(Request, " ")
	for _, Piece in ipairs(Pieces) do
		local Idx = tonumber(Piece)
		if Idx then LUT[Idx] = true end
	end

	if SERVER then
		if #Pieces == 0 then
			RequestedEnts[Player] = nil
		else
			RequestedEnts[Player] = LUT
		end
		Player:ChatPrint("Now tracking: " .. table.concat(table.GetKeys(LUT), ", "))
	else
		if #Pieces == 0 then
			RequestedEnts = nil
		else
			RequestedEnts = LUT
		end
	end
end

if SERVER then
	concommand.Add("acf_physicsvistest", function(Player, _, _, Request)
		if Player == NULL then print("Cannot use this command from a dedicated server!") return end
		if not FunDebuggingFunctions:GetBool() then Player:ChatPrint("Fun debugging functions aren't enabled...") return end
		ProcessLastTyped(Player, Request)
	end, nil, "ACF physics visualizer for testing", FCVAR_USERINFO)
end

if SERVER then
	util.AddNetworkString("ACF_PhysVisData")
	local LastUpdateTime = 0
	local function DoPhysVis()
		-- Just in case. We do the convar listener too, but I just wanna be careful, since
		-- this is a rather intensive tool that shouldnt run by default
		if not FunDebuggingFunctions:GetBool() then return end

		local Now = CurTime()
		local Delta = Now - LastUpdateTime
		if Delta > 0.05 then
			for Player, LUT in pairs(RequestedEnts) do
				if IsValid(Player) then
					net.Start("ACF_PhysVisData")
					net.WriteUInt(table.Count(LUT), 6)
					for EntIdx in pairs(LUT) do
						local Ent = Entity(EntIdx)
						if not IsValid(Ent) then net.WriteBool(false) continue end

						net.WriteBool(true)
						net.WriteUInt(EntIdx, MAX_EDICT_BITS)
						local PhysicsObjects = math.min(Ent:GetPhysicsObjectCount(), 63)
						net.WriteUInt(PhysicsObjects, 6)
						for i = 1, PhysicsObjects do
							local PhysObj = Ent:GetPhysicsObjectNum(i - 1)
							if not IsValid(PhysObj) then net.WriteBool(false) continue end
							net.WriteBool(true)
							net.WriteUInt(i, 6)
							net.WriteVector(Ent:WorldToLocal(PhysObj:GetPos()))
							net.WriteAngle(Ent:WorldToLocalAngles(PhysObj:GetAngles()))
							net.WriteVector(PhysObj:GetVelocity())
							net.WriteVector(PhysObj:GetAngleVelocity())
							net.WriteFloat(PhysObj:GetMass())
							local IS, ES = PhysObj:GetStress()
							net.WriteFloat(IS)
							net.WriteFloat(ES)
							net.WriteUInt(PhysObj:GetContents(), 32)
							local LD, AD = PhysObj:GetDamping()
							net.WriteFloat(LD)
							net.WriteFloat(AD)
							net.WriteFloat(PhysObj:GetEnergy())
							net.WriteVector(PhysObj:GetInertia())
							net.WriteVector(PhysObj:GetMassCenter())
							net.WriteString(PhysObj:GetMaterial())
							net.WriteFloat(PhysObj:GetSpeedDamping())
							net.WriteFloat(PhysObj:GetRotDamping())
							net.WriteAngle(PhysObj:GetShadowAngles())
							net.WriteVector(PhysObj:GetShadowPos())
							net.WriteFloat(PhysObj:GetSurfaceArea() or -1)
							net.WriteFloat(PhysObj:GetVolume() or -1)
							net.WriteBool(PhysObj:IsAsleep())
							net.WriteBool(PhysObj:IsCollisionEnabled())
							net.WriteBool(PhysObj:IsDragEnabled())
							net.WriteBool(PhysObj:IsGravityEnabled())
							net.WriteBool(PhysObj:IsMotionEnabled())
							net.WriteBool(PhysObj:IsMoveable())
							net.WriteBool(PhysObj:IsPenetrating())
						end
					end
					net.Send(Player)
				end
			end
			LastUpdateTime = Now
		end
	end

	local function EvaluateCurrentDebuggingState(Value)
		if (tonumber(Value) or 0) >= 1 then
			hook.Add("Think", "ACF_FunDebuggingFuncs_PhysVis", DoPhysVis)
		else
			hook.Remove("Think", "ACF_FunDebuggingFuncs_PhysVis")
		end
	end

	cvars.AddChangeCallback("acf_fundebuggingfuncs", function(_, _, Value)
		EvaluateCurrentDebuggingState(Value)
	end)

	EvaluateCurrentDebuggingState(FunDebuggingFunctions:GetString())
else
	local PhysData = {}
	net.Receive("ACF_PhysVisData", function()
		table.Empty(PhysData)
		local Ents = net.ReadUInt(6)
		for _ = 1, Ents do
			local Valid = net.ReadBool()
			if not Valid then continue end

			local LUT = {}
			PhysData[net.ReadUInt(MAX_EDICT_BITS)] = LUT
			local Objects = net.ReadUInt(6)
			for PhysIdx = 1, Objects do
				local ValidPhys = net.ReadBool()
				local Obj = {
					ValidPhys = ValidPhys,
					Index = ValidPhys and net.ReadUInt(6),
					Position = ValidPhys and net.ReadVector(),
					Angles = ValidPhys and net.ReadAngle(),
					Velocity = ValidPhys and net.ReadVector(),
					AngularVelocity = ValidPhys and net.ReadVector(),
					Mass = ValidPhys and net.ReadFloat(),
					InternalStress = ValidPhys and net.ReadFloat(),
					ExternalStress = ValidPhys and net.ReadFloat(),
					Contents = ValidPhys and net.ReadUInt(32),
					LinearDamping = ValidPhys and net.ReadFloat(),
					AngularDamping = ValidPhys and net.ReadFloat(),
					Energy = ValidPhys and net.ReadFloat(),
					AngularInertia = ValidPhys and net.ReadVector(),
					MassCenter = ValidPhys and net.ReadVector(),
					Material = ValidPhys and net.ReadString(),
					SpeedDamping = ValidPhys and net.ReadFloat(),
					RotationDamping = ValidPhys and net.ReadFloat(),
					ShadowPosition = ValidPhys and net.ReadVector(),
					ShadowAngles = ValidPhys and net.ReadAngle(),
					SurfaceArea = ValidPhys and net.ReadFloat(),
					Volume = ValidPhys and net.ReadFloat(),
				}

				local Flags = ""
				if ValidPhys and net.ReadBool() then Flags = Flags .. "asleep" end
				if ValidPhys and net.ReadBool() then Flags = Flags .. " collisions" end
				if ValidPhys and net.ReadBool() then Flags = Flags .. " drag" end
				if ValidPhys and net.ReadBool() then Flags = Flags .. " gravity" end
				if ValidPhys and net.ReadBool() then Flags = Flags .. " motion" end
				if ValidPhys and net.ReadBool() then Flags = Flags .. " moveable" end
				if ValidPhys and net.ReadBool() then Flags = Flags .. " penetrating" end
				Obj.Flags = string.Trim(Flags)

				LUT[PhysIdx] = Obj
			end
		end
	end)

	surface.CreateFont("ACF_DebugFixedLarge", {
		font = "Consolas",
		size = 18,
		weight = 900
	})

	surface.CreateFont("ACF_DebugFixedSmall", {
		font = "Consolas",
		size = 13,
		weight = 900
	})

	local function DrawOneLine(Key, Value, MaxKeyLen, X, Y, YOff)
		local Text = Key .. string.rep(' ', math.max(MaxKeyLen - #Key, 0)) .. ": " .. tostring(Value)
		surface.SetFont("ACF_DebugFixedSmall")
		local W, H = surface.GetTextSize(Text)
		X, Y = X, Y + 24 + (YOff * 13)
		surface.SetDrawColor(0, 0, 0, 150)
		local Pad = 2
		surface.DrawRect(X - Pad, Y - (H / 2), W + (Pad * 2), H)
		draw.SimpleTextOutlined(Text, "ACF_DebugFixedSmall", X, Y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, color_black)
		return YOff + 1
	end

	local BeamColor = Color(255, 61, 61)

	hook.Add("PostDrawTranslucentRenderables", "ACF_FunDebuggingFuncs_PhysVis", function()
		if not FunDebuggingFunctions:GetBool() then return end

		for EntIdx, EntPhys in pairs(PhysData) do
			local Ent = Entity(EntIdx)
			if not IsValid(Ent) then continue end

			for _, PhysObj in ipairs(EntPhys) do
				local Pos = Ent:LocalToWorld(PhysObj.Position)

				render.SetColorMaterial()
				ACF.DrawOutlineBeam(2, BeamColor, Pos, Pos + PhysObj.Velocity)
			end
		end
	end)
	local Collapsed = {}
	local WasHeld
	hook.Add("HUDPaint", "ACF_FunDebuggingFuncs_PhysVis", function()
		if not FunDebuggingFunctions:GetBool() then return end

		local X, Y = input.GetCursorPos()
		local Down = input.IsButtonDown(MOUSE_LEFT)
		local Clicked = WasHeld == false and Down == true
		WasHeld = Down
		for EntIdx, EntPhys in pairs(PhysData) do
			local Ent = Entity(EntIdx)
			if not IsValid(Ent) then continue end

			for _, PhysObj in ipairs(EntPhys) do
				local IsCollapsed = Collapsed[EntIdx] and Collapsed[EntIdx][PhysObj.Index] == true
				local Pos = Ent:LocalToWorld(PhysObj.Position)
				local ScreenPos = Pos:ToScreen()
				local W, H = draw.SimpleTextOutlined("[" .. (IsCollapsed and "+" or "-") .. "][Entity #" .. EntIdx .. "][PhysObj #" .. PhysObj.Index .. "]", "ACF_DebugFixedLarge", ScreenPos.x, ScreenPos.y, color_White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, color_black)

				if Clicked and X >= ScreenPos.x and X <= ScreenPos.x + W and Y >= (ScreenPos.y - (H / 2)) and Y <= (ScreenPos.y + H - (H / 2)) then
					-- Collapse now
					if not Collapsed[EntIdx] then Collapsed[EntIdx] = {} end
					Collapsed[EntIdx][PhysObj.Index] = not Collapsed[EntIdx][PhysObj.Index]
				end

				local OffsetY = 0
				if not IsCollapsed then
					for Key, Value in SortedPairs(PhysObj) do
						OffsetY = DrawOneLine(Key, Value, 20, ScreenPos.x, ScreenPos.y, OffsetY)
					end
				end
			end
		end
	end)
end