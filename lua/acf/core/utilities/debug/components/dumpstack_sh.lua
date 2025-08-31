-- MARCH: Dumps the call stack along with stack-frame locals
-- Useful for immediate at a glance looking at globals in SRCDS

function ACF.DumpStack(Message, StartAt)
	StartAt = StartAt or 0

	MsgC("\n\n")
	MsgC(Color(129, 177, 240), " [ ACF.DumpStack() call (start at frame " .. StartAt .. ") ] \n")
	if Message then
		MsgC(Color(196, 236, 134), "  - " .. Message .. " \n")
	else
		MsgC(Color(196, 236, 134), "  - No message included. \n")
	end

	MsgC("\n")

	-- We start at 2 since the first one will always be this (and that's not helpful)
	local StartFrame = 2 + StartAt
	local Frame = StartFrame

	local ArrowColor = Color(158, 57, 57)
	local BrackColor = Color(158, 57, 57)
	local BrightColor  = Color(255, 100, 100)
	local DeepColor  = Color(219, 58, 58)
	local MidColor   = Color(241, 119, 119)
	local LightColor = Color(241, 174, 174)

	while true do
		local FuncInfo = debug.getinfo(Frame, "flnSu")
		if not FuncInfo then
			MsgC(BrightColor, string.rep(" ", (Frame - StartFrame) * 4), "(Native to Lua transition - no further stack frames available)")
			break
		end

		local NumParams = FuncInfo.nparams
		local IsVararg = FuncInfo.isvararg

		local Locals = {}
		local LocalIDX = 1
		while true do
			local Name, Value = debug.getlocal(Frame, LocalIDX)
			if Name == nil then break end

			Locals[LocalIDX] = {
				Name = Name,
				Value = Value
			}

			LocalIDX = LocalIDX + 1
		end

		local Upvalues = {}
		-- Upvalues can't be retrieved from C functions
		if FuncInfo.what == "Lua" then
			local UpvalueCount = FuncInfo.nups

			for I = 1, UpvalueCount do
				local Name, Value = debug.getupvalue(FuncInfo.func, I)
				Upvalues[I] = {
					Name = Name,
					Value = Value
				}
			end
		end

		local Hue = (Frame - StartFrame) * 30

		BrackColor:SetHue(Hue)
		BrightColor:SetHue(Hue)
		DeepColor:SetHue(Hue)
		MidColor:SetHue(Hue)
		LightColor:SetHue(Hue)

		local FrameNum                 = Frame - StartFrame
		local FrameStrPaddingLen       = 4 + (FrameNum * 4)
		local FrameNumPaddingStr       = string.rep(" ", FrameStrPaddingLen - 1) -- we subtract 1 for the beginning character
		local FramePaddingStrWithArrow = FrameNumPaddingStr .. "↑"
		local FramePaddingStrWithPipe  = FrameNumPaddingStr .. "│"
		local FramePaddingLenMinus1    = 4 + ((FrameNum - 1) * 4) - 1
		local FramePaddingStrEnd       = string.rep(" ", FramePaddingLenMinus1) .. "└───"

		local FrameNumString = tostring(FrameNum)
		-- Print the stack frame index
		MsgC(ArrowColor, FrameNum == 0 and FrameNumPaddingStr or FramePaddingStrEnd, BrackColor, "[", BrightColor, "Stack Frame #", LightColor, string.rep("0", math.max(0, 3 - #FrameNumString)), FrameNumString, BrackColor, "]", "\n")
		ArrowColor:SetHue(Hue) -- delay arrow hue change

		-- Function type, name, params
		do
			-- Print the function source-type (global, local, method, field)
			MsgC(ArrowColor,  FramePaddingStrWithArrow .. "    ", DeepColor, "Function:     ")
			MsgC(MidColor, (FuncInfo.namewhat ~= nil and #string.Trim(FuncInfo.namewhat) > 0) and ("<" .. FuncInfo.namewhat .. "> ") or "")
			-- Print the function name
			MsgC(MidColor, FuncInfo.name or "<unknown>", DeepColor, "(")
			-- Start compiling argument names
			local ParamNames = {}
			for Param = 1, NumParams do
				ParamNames[#ParamNames + 1] = Locals[Param].Name
			end

			if IsVararg then
				ParamNames[#ParamNames + 1] = "..."
			end

			MsgC(LightColor, table.concat(ParamNames, ", "))
			MsgC(MidColor, ")")
			Msg("\n")
		end

		-- Function source
		do
			MsgC(ArrowColor, FramePaddingStrWithPipe .. "    ", DeepColor, "Source:       ", MidColor, FuncInfo.short_src or FuncInfo.source)
			MsgC(LightColor, FuncInfo.currentline and (", at line " .. FuncInfo.currentline) or "")
			Msg("\n")
		end

		-- Function parameters in stack frame
		do
			MsgC(ArrowColor, FramePaddingStrWithPipe .. "    ", DeepColor, "Parameters:", LightColor, NumParams > 0 and "" or "   [empty]", "\n")
			if NumParams > 0 then
				local MaxParamName = 0
				for ParamI = 1, NumParams do
					local NameLen = #Locals[ParamI].Name
					if NameLen > MaxParamName then MaxParamName = NameLen end
				end
				for ParamI = 1, NumParams do
					local Param = Locals[ParamI]
					MsgC(ArrowColor, FramePaddingStrWithPipe .. "                  ", MidColor, Param.Name .. string.rep(" ", MaxParamName - #Param.Name), DeepColor, " : ", LightColor, tostring(Param.Value), "\n")
				end
			end
		end

		-- Function locals in stack frame
		do
			MsgC(ArrowColor, FramePaddingStrWithPipe .. "    ", DeepColor, "Locals:\n")

			local MaxLocalName = 0
			for LocalI = NumParams + 1, #Locals do
				local NameLen = #Locals[LocalI].Name
				if NameLen > MaxLocalName then MaxLocalName = NameLen end
			end
			for LocalI = NumParams + 1, #Locals do
				local Local = Locals[LocalI]
				MsgC(ArrowColor, FramePaddingStrWithPipe .. "                  ", MidColor, Local.Name .. string.rep(" ", MaxLocalName - #Local.Name), DeepColor, " : ", LightColor, tostring(Local.Value), "\n")
			end
		end

		-- Function upvalues in stack frame
		do
			MsgC(ArrowColor, FramePaddingStrWithPipe .. "    ", DeepColor, "Upvalues:", LightColor, #Upvalues > 0 and "" or "     [empty]", "\n")
			if #Upvalues > 0 then
				local MaxUpvalueName = 0
				for UpvalueI = 1, #Upvalues do
					local NameLen = #Upvalues[UpvalueI].Name
					if NameLen > MaxUpvalueName then MaxUpvalueName = NameLen end
				end
				for UpvalueI = 1, #Upvalues do
					local Upvalue = Upvalues[UpvalueI]
					MsgC(ArrowColor, FramePaddingStrWithPipe .. "                  ", MidColor, Upvalue.Name .. string.rep(" ", MaxUpvalueName - #Upvalue.Name), DeepColor, " : ", LightColor, tostring(Upvalue.Value), "\n")
				end
			end
		end

		-- Dump function parameters and local variables

		-- Give space around the frames
		MsgC(ArrowColor, FramePaddingStrWithPipe, "\n")

		Frame = Frame + 1
	end
end
--[[
local function t(test)
	local v = 5
	ACF.DumpStack()
end
t()]]

if CLIENT then
	local WatchCPU, WatchGC

	local Red   = Color(255, 70, 70)
	local Green = Color(100, 255, 70)
	local function Evaluate(Value)
		WatchCPU, WatchGC = nil, nil

		if Value <= 0 then
			hook.Remove("HUDPaint", "ACF_GCWatch")
			return
		end

		if Value >= 1 then
			WatchCPU = ACF.PerfGraph()
			WatchCPU.Divisor = 1 / 1000
		end

		if Value >= 2 then
			WatchGC  = ACF.PerfGraph()
			WatchGC.Divisor = 1024
		end


		hook.Add("HUDPaint", "ACF_GCWatch", function()
			local WidthOneGraph = ScrW() / 5
			if WatchCPU ~= nil then
				WatchCPU:Add(FrameTime())
				WatchCPU:Draw("FrameTime() [milliseconds]", 24, ScrH() - 120, WidthOneGraph, 96, Red)
			end

			if WatchGC ~= nil then
				WatchGC:Add(collectgarbage("count"))
				WatchGC:Draw("collectgarbage(\"count\") [MB]", 48 + WidthOneGraph, ScrH() - 120, WidthOneGraph, 96, Green)
			end
		end)
	end

	local acf_perfgraphs = CreateClientConVar("acf_perfgraphs", "0", false, false, "Shows performance graphs.\n\n  >= 1: CPU time.\n  >= 2: Lua GC usage")

	cvars.AddChangeCallback("acf_perfgraphs", function(_, _, Value)
		Evaluate(tonumber(Value) or 0)
	end)

	Evaluate(acf_perfgraphs:GetInt())
end