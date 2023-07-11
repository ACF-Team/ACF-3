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

			if not IsValid( LocalPlayer() ) then return end

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
			if not isstring(Tool) then return end
			if not isstring(Stage) then return end
			if not isstring(Op) then return end

			ACF.SetClientData(Key:format(Tool), Value:format(Stage, Op))
		end
	end
end

do -- Generic Spawner/Linker operation creator
	local Entities   = ACF.Classes.Entities
	local Messages   = ACF.Utilities.Messages
	local SpawnText  = "Spawn a new %s or update an existing one."
	local Green      = Color(0, 255, 0)
	local NameFormat = "%s[ID: %s]"
	local PlayerEnts = {}

	local function GetPlayerEnts(Player)
		local Ents = PlayerEnts[Player]

		if not Ents then
			Ents = {}
			PlayerEnts[Player] = Ents
		end

		return Ents
	end

	local function CanUpdate(Entity, Class)
		if not IsValid(Entity) then return false end

		return Entity:GetClass() == Class
	end

	local function GetClassName(Player, Data)
		local PrimaryClass   = Data.PrimaryClass
		local SecondaryClass = Data.SecondaryClass

		if not SecondaryClass then return PrimaryClass end
		if SecondaryClass == "N/A" then return PrimaryClass end

		local OnKeybind = Player:KeyDown(IN_SPEED) or Player:KeyDown(IN_RELOAD)

		return OnKeybind and SecondaryClass or PrimaryClass
	end

	local function SpawnEntity(Tool, Trace)
		if Trace.HitSky then return false end

		local Player = Tool:GetOwner()
		local Data   = ACF.GetAllClientData(Player)
		local Class  = GetClassName(Player, Data)

		if not Class or Class == "N/A" then return false end

		local Entity = Trace.Entity

		if CanUpdate(Entity, Class) then
			local Result, Message = Entities.Update(Entity, Data)

			Messages.SendChat(Player, Result and "Info" or "Error", Message)

			return true
		end

		local Position = Trace.HitPos + Trace.HitNormal * 128
		local Angles   = Trace.HitNormal:Angle():Up():Angle()

		local Success, Result = Entities.Spawn(Class, Player, Position, Angles, Data)

		if Success then
			local PhysObj = Result:GetPhysicsObject()

			Result:DropToFloor()

			if IsValid(PhysObj) then
				PhysObj:EnableMotion(false)
			end
		else
			Messages.SendChat(Player, "Error", "Couldn't create entity: " .. Result)
		end

		return Success
	end

	local function UnselectEntity(Entity, Name, Tool)
		local Player   = Tool:GetOwner()
		local Ents     = GetPlayerEnts(Player)
		local EntColor = Ents[Entity]

		Entity:RemoveCallOnRemove("ACF_ToolLinking")
		Entity:SetColor(EntColor)

		Ents[Entity] = nil

		if not next(Ents) then
			Tool:SetMode("Spawner", Name)
		end
	end

	local function SelectEntity(Entity, Name, Tool)
		if not IsValid(Entity) then return false end

		local Player = Tool:GetOwner()
		local Ents   = GetPlayerEnts(Player)

		if not next(Ents) then
			Tool:SetMode("Linker", Name)
		end

		Ents[Entity] = Entity:GetColor()

		Entity:CallOnRemove("ACF_ToolLinking", UnselectEntity, Name, Tool)
		Entity:SetColor(Green)

		return true
	end

	local function GetName(Entity)
		local Name  = Entity.Name or Entity:GetClass()
		local Index = Entity:EntIndex()

		return NameFormat:format(Name, Index)
	end

	local Single = {
		Success = "Successfully %sed %s to %s.",
		Failure = "Couldn't %s %s to %s: %s",
	}

	local Multiple = {
		Success  = "Successfully %sed %s entities to %s.%s",
		Failure  = "Couldn't %s any of the %s entities to %s.%s",
		ErrorEnd = " Printing %s error message(s) to the console.",
		ErrorTop = "The following entities couldn't be %sed to %s:\n%s\n",
		ErrorBit = ">>> %s: %s",
	}

	local function ReportSingle(Player, Action, EntName, Target, Result, Message)
		local Template = Result and Single.Success or Single.Failure
		local Feedback = Template:format(Action, EntName, Target, Message)
		local Type     = Result and "Info" or "Error"

		Messages.SendChat(Player, Type, Feedback)
	end

	local function ReportMultiple(Player, Action, EntName, Failed, Count, Total)
		local Errors   = #Failed
		local Result   = Count > 0
		local Template = Result and Multiple.Success or Multiple.Failure
		local Amount   = Result and Count or Total
		local EndBit   = Errors > 0 and Multiple.ErrorEnd:format(Errors) or ""
		local Feedback = Template:format(Action, Amount, EntName, EndBit)
		local Type     = Result and "Info" or "Error"

		Messages.SendChat(Player, Type, Feedback)

		if Errors > 0 then
			local Error = Multiple.ErrorBit
			local List  = {}

			for Index, Data in ipairs(Failed) do
				List[Index] = Error:format(Data.Name, Data.Message)
			end

			local ErrorList = table.concat(List, "\n")
			local ErrorLog  = Multiple.ErrorTop:format(Action, EntName, ErrorList)

			Messages.SendLog(Player, "Warning", ErrorLog)
		end
	end

	local function LinkEntities(Player, Name, Tool, Entity, Ents)
		local OnKey    = Player:KeyDown(IN_RELOAD)
		local Function = OnKey and Entity.Unlink or Entity.Link
		local Action   = OnKey and "unlink" or "link"
		local EntName  = GetName(Entity)
		local Success  = {}
		local Failed   = {}
		local Total    = 0

		for K in pairs(Ents) do
			local EntFunc = OnKey and K.Unlink or K.Link
			local Result  = false
			local Message

			if EntFunc then
				Result, Message = EntFunc(K, Entity)
			elseif Function then
				Result, Message = Function(Entity, K)
			end

			Total = Total + 1

			if Result then
				Success[#Success + 1] = {
					Name = GetName(K),
				}
			else
				Failed[#Failed + 1] = {
					Message = Message or "No reason given.",
					Name    = GetName(K),
				}
			end

			UnselectEntity(K, Name, Tool)
		end

		if Total > 1 then
			ReportMultiple(Player, Action, EntName, Failed, #Success, Total)
		else
			local Result  = next(Success) and true or false
			local Origin  = table.remove(Result and Success or Failed)
			local Target  = Origin.Name
			local Message = Origin.Message

			ReportSingle(Player, Action, EntName, Target, Result, Message)
		end
	end

	function ACF.CreateMenuOperation(Name, Primary, Secondary)
		if not isstring(Name) then return end
		if not isstring(Primary) then return end

		Secondary = ACF.CheckString(Secondary)

		do -- Spawner stuff
			ACF.RegisterOperation("acf_menu", "Spawner", Name, {
				OnLeftClick  = SpawnEntity,
				OnRightClick = function(Tool, Trace)
					local Entity = Trace.Entity

					return SelectEntity(Entity, Name, Tool)
				end,
			})

			ACF.RegisterToolInfo("acf_menu", "Spawner", Name, {
				name = "left",
				text = SpawnText:format(Primary),
			})

			if Secondary then
				ACF.RegisterToolInfo("acf_menu", "Spawner", Name, {
					name = "left_secondary",
					text = "(Hold Shift or R) " .. SpawnText:format(Secondary),
					icon2 = "gui/info",
				})
			end

			ACF.RegisterToolInfo("acf_menu", "Spawner", Name, {
				name = "right",
				text = "Select the entity you want to link or unlink.",
			})
		end

		do -- Linker stuff
			ACF.RegisterOperation("acf_menu", "Linker", Name, {
				OnRightClick = function(Tool, Trace)
					if Trace.HitWorld then Tool:Holster() return true end

					local Entity = Trace.Entity

					if not IsValid(Entity) then return false end

					local Player = Tool:GetOwner()
					local Ents   = GetPlayerEnts(Player)

					if not Player:KeyDown(IN_SPEED) then
						LinkEntities(Player, Name, Tool, Entity, Ents)

						return true
					end

					if not Ents[Entity] then
						SelectEntity(Entity, Name, Tool)
					else
						UnselectEntity(Entity, Name, Tool)
					end

					return true
				end,
				OnHolster = function(Tool)
					local Player = Tool:GetOwner()
					local Ents   = GetPlayerEnts(Player)

					if not next(Ents) then return end

					for Entity in pairs(Ents) do
						UnselectEntity(Entity, Name, Tool)
					end
				end,
			})

			ACF.RegisterToolInfo("acf_menu", "Linker", Name, {
				name = "right",
				text = "Link all the selected entities to an entity.",
			})

			ACF.RegisterToolInfo("acf_menu", "Linker", Name, {
				name = "right_r",
				text = "Unlink all the selected entities from an entity.",
				icon2 = "gui/r.png",
			})

			ACF.RegisterToolInfo("acf_menu", "Linker", Name, {
				name = "right_shift",
				text = "Select another entity to link.",
				icon2 = "gui/info",
			})

			ACF.RegisterToolInfo("acf_menu", "Linker", Name, {
				name = "right_world",
				text = "(Hit the World) Unselected all selected entities.",
				icon2 = "gui/info",
			})
		end
	end
end
