local ACF = ACF

ACF.Tools = ACF.Tools or {}

local Tools = ACF.Tools

local function GetToolData(Tool)
	if not Tools[Tool] then
		Tools[Tool] = {
			Indexed = {},
			Stages = {},
			Count = 0,
		}

		ACF.RegisterOperation(Tool, "Main", "Idle", {})
		ACF.RegisterToolInfo(Tool, "Main", "Idle", {
			name = "info",
			text = "Select an option on the menu."
		})
	end

	return Tools[Tool]
end

do -- Tool Stage/Operation Registration function
	local function RegisterStage(Data, Name)
		local Stage = Data.Stages[Name]

		if not Stage then
			local Count = Data.Count

			Stage = {
				Ops = {},
				Count = 0,
				Name = Name,
				Indexed = {},
				Index = Count,
			}

			Data.Stages[Name] = Stage
			Data.Indexed[Count] = Stage

			Data.Count = Count + 1
		end

		return Stage
	end

	function ACF.RegisterOperation(Tool, StageName, OpName, ToolFuncs)
		if not Tool then return end
		if not OpName then return end
		if not StageName then return end
		if not istable(ToolFuncs) then return end

		local Data = GetToolData(Tool)
		local Stage = RegisterStage(Data, StageName)
		local Operation = Stage.Ops[OpName]
		local Count = Stage.Count

		if not Operation then
			Operation = {}

			Stage.Ops[OpName] = Operation
			Stage.Indexed[Count] = Operation
			Stage.Count = Count + 1
		end

		for K, V in pairs(ToolFuncs) do
			Operation[K] = V
		end

		Operation.Name = OpName
		Operation.Index = Count

		return Operation
	end
end

do -- Tool Information Registration function
	local function GetInformation(Tool)
		local Data = Tools[Tool]

		if not Data.Information then
			Data.Information = {}
			Data.InfoLookup = {}
			Data.InfoCount = 0
		end

		return Data.Information
	end

	-- This function will add entries to the tool's Information table
	-- For more reference about the values you can give it see:
	-- https://wiki.facepunch.com/gmod/Tool_Information_Display
	-- Note: name, stage and op will be assigned automatically
	function ACF.RegisterToolInfo(Tool, Stage, Op, Info)
		if SERVER then return end
		if not Tool then return end
		if not Stage then return end
		if not Op then return end
		if not istable(Info) then return end
		if not Info.name then return end
		if not Info.text then return end

		local Data = GetToolData(Tool)
		local Stages = Data.Stages[Stage]

		if not Stages then return end

		local Ops = Stages.Ops[Op]

		if not Ops then return end

		local StageIdx, OpIdx = Stages.Index, Ops.Index
		local Name = Info.name .. "_" .. StageIdx .. "_" .. OpIdx
		local ToolInfo = GetInformation(Tool)
		local New = Data.InfoLookup[Name]

		if not New then
			local Count = Data.InfoCount + 1

			New = {}

			Data.InfoLookup[Name] = New
			Data.InfoCount = Count

			ToolInfo[Count] = New
		end

		for K, V in pairs(Info) do
			New[K] = V
		end

		New.name = Name
		New.stage = StageIdx
		New.op = OpIdx

		return New
	end
end

do -- Tool Functions Loader
	local Category = GetConVar("acf_tool_category")

	if SERVER then
		util.AddNetworkString("ACF_ToolNetVars")

		hook.Add("PlayerCanPickupWeapon", "ACF Tools", function(Player, Weapon)
			if Weapon:GetClass() ~= "gmod_tool" then return end

			for Name in pairs(Tools) do
				local Tool = Player:GetTool(Name)

				if Tool then
					Tool:RestoreMode()
				end
			end
		end)
	else
		net.Receive("ACF_ToolNetVars", function()
			local ToolName = net.ReadString()
			local Name = net.ReadString()
			local Value = net.ReadInt(8)

			local Data = Tools[ToolName]
			local Tool = LocalPlayer():GetTool(ToolName)

			if not Data then return end
			if not Tool then return end

			if Name == "Stage" then
				Tool.Stage = Value
				Tool.StageData = Data.Indexed[Value]
			elseif Name == "Operation" then
				Tool.Operation = Value
				Tool.OpData = Tool.StageData.Indexed[Value]
				Tool.DrawToolScreen = Tool.OpData.DrawToolScreen
			end
		end)
	end

	local function UpdateNetvar(Tool, Name, Value)
		net.Start("ACF_ToolNetVars")
			net.WriteString(Tool.Mode)
			net.WriteString(Name)
			net.WriteInt(Value, 8)
		net.Send(Tool:GetOwner())
	end

	function ACF.LoadToolFunctions(Tool)
		if not Tool then return end
		if not Tools[Tool.Mode] then return end

		local Mode = Tool.Mode
		local Data = Tools[Mode]
		Data.Tool = Tool

		function Tool:SetStage(Stage)
			if CLIENT then return end
			if not Stage then return end
			if not Data.Indexed[Stage] then return end

			self.Stage = Stage
			self.StageData = Data.Indexed[Stage]

			UpdateNetvar(self, "Stage", Stage)

			self:SetOperation(0)
		end

		function Tool:GetStage()
			return self.Stage
		end

		function Tool:SetOperation(Op)
			if CLIENT then return end
			if not Op then return end
			if not self.StageData.Indexed[Op] then return end

			self.Operation = Op
			self.OpData = self.StageData.Indexed[Op]

			UpdateNetvar(self, "Operation", Op)
		end

		function Tool:GetOperation()
			return self.Operation
		end

		if CLIENT then
			Tool.Category = Category:GetBool() and "ACF" or "Construction"

			if Data.Information then
				Tool.Information = {}

				for K, V in ipairs(Data.Information) do
					Tool.Information[K] = V

					language.Add("Tool." .. Mode .. "." .. V.name, V.text)
				end
			end

			function Tool:LeftClick(Trace)
				return not Trace.HitSky
			end

			function Tool:RightClick(Trace)
				return not Trace.HitSky
			end

			function Tool:Reload(Trace)
				return not Trace.HitSky
			end
		else
			-- Helper function, allows you to set both stage and op at the same time with their names
			function Tool:SetMode(StageName, OpName)
				if not StageName then return end
				if not OpName then return end

				local Stage = Data.Stages[StageName]

				if not Stage then return end

				local Op = Stage.Ops[OpName]

				if not Op then return end

				self:SetStage(Stage.Index)
				self:SetOperation(Op.Index)
			end

			function Tool:RestoreMode()
				local ToolMode = ACF.GetClientString(self:GetOwner(), "ToolMode:" .. self.Mode)

				if ToolMode then
					local Stage, Op = unpack(string.Explode(":", ToolMode), 1, 2)

					self:SetMode(Stage, Op)
				end
			end

			function Tool:LeftClick(Trace)
				if self.OpData then
					local OnLeftClick = self.OpData.OnLeftClick

					if OnLeftClick then
						return OnLeftClick(self, Trace)
					end
				end

				return false
			end

			function Tool:RightClick(Trace)
				if self.OpData then
					local OnRightClick = self.OpData.OnRightClick

					if OnRightClick then
						return OnRightClick(self, Trace)
					end
				end

				return false
			end

			function Tool:Reload(Trace)
				if self.OpData then
					local OnReload = self.OpData.OnReload

					if OnReload then
						return OnReload(self, Trace)
					end
				end

				return false
			end

			function Tool:Deploy()
				self:RestoreMode()

				if self.OpData then
					local OnDeploy = self.OpData.OnDeploy

					if OnDeploy then
						OnDeploy(self)
					end
				end
			end

			function Tool:Holster()
				if self.OpData then
					local OnHolster = self.OpData.OnHolster

					if OnHolster then
						OnHolster(self)
					end
				end
			end

			function Tool:Think()
				if self.OpData then
					local OnThink = self.OpData.OnThink

					if OnThink then
						OnThink(self)
					end
				end
			end
		end
	end
end

do -- Clientside Tool interaction
	if SERVER then
		hook.Add("ACF_OnClientDataUpdate", "ACF ToolMode", function(Player, Key, Value)
			local Header, Name = unpack(string.Explode(":", Key), 1, 2)

			if Header ~= "ToolMode" then return end

			local Tool = Player:GetTool(Name)

			if not Tool then return end
			if not Tool.SetMode then return end

			local Stage, Op = unpack(string.Explode(":", Value), 1, 2)

			Tool:SetMode(Stage, Op)
		end)
	else
		local Key = "ToolMode:%s"
		local Value = "%s:%s"

		function ACF.SetToolMode(Tool, Stage, Op)
			if not ACF.CheckString(Tool) then return end
			if not ACF.CheckString(Stage) then return end
			if not ACF.CheckString(Op) then return end

			ACF.SetClientData(Key:format(Tool), Value:format(Stage, Op))
		end
	end
end
