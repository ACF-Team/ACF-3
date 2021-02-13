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
			if not isstring(Tool) then return end
			if not isstring(Stage) then return end
			if not isstring(Op) then return end

			ACF.SetClientData(Key:format(Tool), Value:format(Stage, Op))
		end
	end
end

do -- Generic Spawner/Linker operation creator
	local Entities  = {}
	local SpawnText = "Spawn a new %s or update an existing one."

	local function GetPlayerEnts(Player)
		local Ents = Entities[Player]

		if not Ents then
			Ents = {}
			Entities[Player] = Ents
		end

		return Ents
	end

	local function CanUpdate(Entity, ClassName)
		if not IsValid(Entity) then return false end

		return Entity:GetClass() == ClassName
	end

	local function SpawnEntity(Player, ClassName, Trace, Data)
		if not ClassName or ClassName == "N/A" then return false end

		local Entity = Trace.Entity

		if CanUpdate(Entity, ClassName) then
			local Result, Message = ACF.UpdateEntity(Entity, Data)

			ACF.SendMessage(Player, Result and "Info" or "Error", Message)

			return true
		end

		local Position = Trace.HitPos + Trace.HitNormal * 128
		local Angles   = Trace.HitNormal:Angle():Up():Angle()

		local Success, Result = ACF.CreateEntity(ClassName, Player, Position, Angles, Data)

		if Success then
			local PhysObj = Result:GetPhysicsObject()

			Result:DropToFloor()

			if IsValid(PhysObj) then
				PhysObj:EnableMotion(false)
			end
		else
			ACF.SendMessage(Player, "Error", "Couldn't create entity: " .. Result)
		end

		return Success
	end

	function ACF.CreateMenuOperation(Name, Primary, Secondary)
		if not isstring(Name) then return end
		if not isstring(Primary) then return end

		Secondary = ACF.CheckString(Secondary)

		local function UnselectEntity(Tool, Player, Entity)
			local Ents = GetPlayerEnts(Player)

			Entity:RemoveCallOnRemove("ACF_ToolLinking")
			Entity:SetColor(Ents[Entity])

			Ents[Entity] = nil

			if not next(Ents) then
				Tool:SetMode("Spawner", Name)
			end
		end

		local function SelectEntity(Tool, Player, Entity)
			if not IsValid(Entity) then return false end

			local Ents = GetPlayerEnts(Player)

			if not next(Ents) then
				Tool:SetMode("Linker", Name)
			end

			Ents[Entity] = Entity:GetColor()
			Entity:SetColor(Color(0, 255, 0))
			Entity:CallOnRemove("ACF_ToolLinking", function()
				UnselectEntity(Tool, Player, Entity)
			end)

			return true
		end

		do -- Spawner stuff
			local function GetClassName(Player, Data)
				local PrimaryClass   = Data.PrimaryClass
				local SecondaryClass = Data.SecondaryClass

				if not SecondaryClass then return PrimaryClass end
				if SecondaryClass == "N/A" then return PrimaryClass end

				local OnKeybind = Player:KeyDown(IN_SPEED) or Player:KeyDown(IN_RELOAD)

				return OnKeybind and SecondaryClass or PrimaryClass
			end

			ACF.RegisterOperation("acf_menu", "Spawner", Name, {
				OnLeftClick = function(Tool, Trace)
					if Trace.HitSky then return false end

					local Player    = Tool:GetOwner()
					local Data      = ACF.GetAllClientData(Player)
					local ClassName = GetClassName(Player, Data)

					return SpawnEntity(Player, ClassName, Trace, Data)
				end,
				OnRightClick = function(Tool, Trace)
					local Player = Tool:GetOwner()

					return SelectEntity(Tool, Player, Trace.Entity)
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
			local function LinkEntities(Tool, Player, Entity, Ents)
				local Total, Done = 0, 0
				local Unlink = Player:KeyDown(IN_RELOAD)
				local Action = Unlink and Entity.Unlink or Entity.Link

				for K in pairs(Ents) do
					local EntAction = Unlink and K.Unlink or K.Link
					local Success = false

					if EntAction then
						Success = EntAction(K, Entity)
					elseif Action then
						Success = Action(Entity, K)
					end

					Total = Total + 1

					if Success then
						Done = Done + 1
					end

					UnselectEntity(Tool, Player, K)
				end

				-- TODO: Add list of reasons for failed links
				if Done > 0 then
					local Status = (Unlink and "unlinked " or "linked ") .. Done .. " out of " .. Total

					ACF.SendMessage(Player, "Info", "Successfully ", Status, " entities to ", tostring(Entity), ".")
				else
					local Status = Total .. " entities could be " .. (Unlink and "unlinked" or "linked")

					ACF.SendMessage(Player, "Error", "None of the ", Status, " to ", tostring(Entity), ".")
				end
			end

			ACF.RegisterOperation("acf_menu", "Linker", Name, {
				OnRightClick = function(Tool, Trace)
					local Player = Tool:GetOwner()
					local Entity = Trace.Entity

					if Trace.HitWorld then Tool:Holster() return true end
					if not IsValid(Entity) then return false end

					local Ents = GetPlayerEnts(Player)

					if not Player:KeyDown(IN_SPEED) then
						LinkEntities(Tool, Player, Entity, Ents)
						return true
					end

					if not Ents[Entity] then
						SelectEntity(Tool, Player, Entity)
					else
						UnselectEntity(Tool, Player, Entity)
					end

					return true
				end,
				OnHolster = function(Tool)
					local Player = Tool:GetOwner()
					local Ents = GetPlayerEnts(Player)

					if not next(Ents) then return end

					for Entity in pairs(Ents) do
						UnselectEntity(Tool, Player, Entity)
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
