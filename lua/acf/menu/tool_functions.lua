local ACF = ACF

ACF.Tools = ACF.Tools or {}

-- DISCLAIMER
-- Usually you have a few operations, and each operation has its own set of stages.
-- For whatever reason, the reverse is done here. So each stage has its own set of operations.

--- Special datatype annotations -----------------------------------------------------------

--- This represents the actual tool class gmod uses, with the propperties we add
--- @class Tool
--- @field Mode string The Mode of the tool (kind of like the name) (e.g. "acf_menu"/"acf_copy")
--- @field Stage number The current stage index of the tool
--- @field Operation number The current operation index of the tool
--- @field StageData Stage The data for the current stage TODO:
--- @field OpData Operation The data for the current operation TODO:

--- Represents an entry in the tool information display for a given operation in a given stage of a given tool  
--- (see https://wiki.facepunch.com/gmod/Tool_Information_Display)  
--- name text, icon1 and icon2 are the only things that actually end up displayed in the tool binds display
--- PLEASE read the wiki page on name (the way it interacts with the icons is not intuitive)
--- @class ToolInfo
--- @field name string A unique? name for the entry (READ THE WIKI TO SEE HOW IT WORKS) (e.g. "left"/"right_shift")
--- @field text string The description to display (e.g. "Left click to select.")
--- @field icon string A path to the first icon (e.g. "gui/lmb.png")
--- @field icon2 string A second icon path, for key combination icons (e.g. "gui/info.png")
--- @field stage number The index of the stage in the tool
--- @field op number The index of the operation in the stage above

--- A table representing a tool.
--- @class ToolData
--- @field Stages table<string, Stage> A table to hold stages by name
--- @field Indexed table<number, Stage> A table to hold indexed stages
--- @field Information table<number, ToolInfo> A table holding information entries for the tool TODO: Figure out this
--- @field InfoLookup table<string, ToolInfo> A lookup table for information entries by name
--- @field InfoCount number A counter to keep track of the number of information entries
--- @field Count number A counter to keep track of the number of stages

--- Represents a stage within a tool.
--- @class Stage
--- @field Name string The name of the stage
--- @field Index number The index of the stage within the tool
--- @field Ops table<string, Operation> A table to hold operations by name
--- @field Indexed table<number, Operation> A table to hold indexed operations
--- @field Count number A counter to keep track of the number of operations


--- Represents an operation within a stage of a tool.
--- @class Operation
--- @field Name string The name of the operation.
--- @field Index number The index of the operation within the stage.
--- @field OnLeftClick function A function to handle the left click action.
--- @field OnRightClick function A function to handle the right click action.
--- @field OnReload function A function to handle the reload action.
--- @field OnDeploy function A function to handle the deploy action.
--- @field OnHolster function A function to handle the holster action.
--- @field OnThink function A function to handle the think action.

--------------------------------------------------------------------------------------------

--- A table to manage the data and behavior of tools.
--- @type table<string, ToolData>
local Tools = ACF.Tools

--- Retrieves or initializes the data structure for a given tool.
--- Ensures that the tool has a consistent data structure and registers default operations and information.
--- @param Tool string The name of the tool. (e.g. "acf_copy"/"acf_menu")
--- @return ToolData # The data structure for the specified tool.
local function GetToolData(Tool)
	if not Tools[Tool] then
		-- Partial initialization?
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
	--- Registers a stage for a tool.
	--- @param Data ToolData The data structure for the tool.
	--- @param Name string The name of the stage.
	--- @return Stage Stage The stage data structure.
	local function RegisterStage(Data, Name)
		local Stage = Data.Stages[Name]

		if not Stage then
			local Count = Data.Count

			Stage = {
				Ops = {}, -- Stores operations
				Count = 0, -- Stores count of operations
				Name = Name, -- Name of stage
				Indexed = {}, -- Array version of Ops
				Index = Count, -- Current index of this stage within the tool
			}

			-- Index new stage in the tool data
			Data.Stages[Name] = Stage
			Data.Indexed[Count] = Stage

			Data.Count = Count + 1 -- Track # of stages
		end

		return Stage
	end

	--- Registers and returns (if successful), an operation for a tool within a specific stage.
	--- @param Tool string The name of the tool.
	--- @param StageName string The name of the stage.
	--- @param OpName string The name of the operation.
	--- @param ToolFuncs table<string, function> A table of functions representing the operation.
	--- @return Operation | nil Operation The registered operation
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
	--- Retrieves the information table for a tool, initializing it if necessary.
	--- @param Tool string The name of the tool.
	--- @return table Information The information table for the specified tool.
	local function GetInformation(Tool)
		local Data = Tools[Tool]

		-- If the tool information doesn't exist, initialize it (Partial initialization?)
		if not Data.Information then
			Data.Information = {}
			Data.InfoLookup = {}
			Data.InfoCount = 0
		end

		return Data.Information
	end

	--- This function will add entries to the tool's Information table  
	--- This function is only intended to work on the client  
	--- For more reference about the values you can give it see:  
	--- https://wiki.facepunch.com/gmod/Tool_Information_Display  
	--- Note: name, stage and op will be assigned automatically for the returned ToolInfo
	--- @param Tool string # The name of the tool 
	--- @param Stage string # The name of the stage
	--- @param Op string # The name of the operation
	--- @param Info table # The information for the tool
	--- @return ToolInfo | nil New # The updated/newly created tool info
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

		-- Do nothing if a stage wasn't already defined
		if not Stages then return end

		local Ops = Stages.Ops[Op]

		-- Do nothing if the operation wasn't already defined for this stage
		if not Ops then return end

		-- Gather tool information
		local StageIdx, OpIdx = Stages.Index, Ops.Index
		local Name = Info.name .. "_" .. StageIdx .. "_" .. OpIdx
		local ToolInfo = GetInformation(Tool) -- Equivalent to Data.Information (?) TODO: check this
		local New = Data.InfoLookup[Name] -- Preexisting info entry

		-- If an information entry didn't already exist for this stage and operation, make one.
		if not New then
			local Count = Data.InfoCount + 1

			New = {}

			Data.InfoLookup[Name] = New
			Data.InfoCount = Count

			ToolInfo[Count] = New
		end

		-- Update the information entry based on Info (This is done so we can partially update it multiple times)
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
	-- If you have `acf_tool_category 0` in console (default), the ACF tools go under the "Construction" tool category.
	-- If you have `acf_tool_category 1` in console, the ACF tools go under a new "ACF" tool category
	local Category = GetConVar("acf_tool_category")

	if SERVER then
		util.AddNetworkString("ACF_ToolNetVars")

		-- If the player picks up a gmod tool, restore the mode of every tool (e.g. "acf_menu"/"acf_copy")
		-- Why is this done???
		hook.Add("PlayerCanPickupWeapon", "ACF Tools", function(Player, Weapon)
			if Weapon:GetClass() ~= "gmod_tool" then return end

			for Name in pairs(Tools) do
				local Tool = Player:GetTool(Name)

				if Tool then
					Tool:RestoreMode()
				end
			end
		end)
	elseif CLIENT then
		-- When the client receives tool net vars, update the 
		net.Receive("ACF_ToolNetVars", function()
			-- Check UpdateNetVar below for what these mean
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

	--- Sends any new tool net var updates over the network
	--- Mainly used to convey operation or stage changes
	--- Example values:
	--- @param Tool Tool The tool instance, used to get the mode and owner
	--- @param Name string The name of the net var (e.g. "Stage"/"Operation")
	--- @param Value any The value of the net var (e.g. 0/1/2/3/...)
	local function UpdateNetvar(Tool, Name, Value)
		net.Start("ACF_ToolNetVars")
			net.WriteString(Tool.Mode)
			net.WriteString(Name)
			net.WriteInt(Value, 8)
		net.Send(Tool:GetOwner())
	end

	--- Loads tool functions onto a tool. Used by the acf menu tool and acf copy tool
	--- @param Tool Tool The tool to load functions onto
	function ACF.LoadToolFunctions(Tool)
		if not Tool then return end
		if not Tools[Tool.Mode] then return end

		local Mode = Tool.Mode
		local Data = Tools[Mode]
		Data.Tool = Tool

		--- Sets the stage of the tool (also resets the operation to 0)  
		--- Only available on client
		--- @param self Tool The tool
		--- @param Stage number The index of the stage (see ToolData.Indexed)
		function Tool:SetStage(Stage)
			if CLIENT then return end
			if not Stage then return end
			if not Data.Indexed[Stage] then return end

			-- Set the tool's stage and stage data, then network to client
			self.Stage = Stage
			self.StageData = Data.Indexed[Stage]

			UpdateNetvar(self, "Stage", Stage)

			-- Resets the operation to 0 because we switched to a new stage
			self:SetOperation(0)
		end

		--- Gets the current stage of the tool
		--- @param self Tool
		--- @return number
		function Tool:GetStage()
			return self.Stage
		end

		--- Sets the operation of the tool
		--- @param self Tool
		--- @param Op any
		function Tool:SetOperation(Op)
			if CLIENT then return end
			if not Op then return end
			if not self.StageData.Indexed[Op] then return end

			self.Operation = Op
			self.OpData = self.StageData.Indexed[Op]
			-- print(("OpData for stage [%s]"):format(self:GetStage()))
			-- PrintTable(self.OpData)

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

			--- Handle tool binds and dont apply effect if you're aiming at the sky

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
				-- Both must be specified strings
				if not StageName then return end
				if not OpName then return end

				-- Look up the stage and operation by name if they exist. Then access their indices and set stage and operation.
				local Stage = Data.Stages[StageName]

				if not Stage then return end

				local Op = Stage.Ops[OpName]

				if not Op then return end

				-- TODO: do we realy need to use indices? figure this out later lol...
				self:SetStage(Stage.Index)
				self:SetOperation(Op.Index)
			end

			--- Restores the tool's mode to its last known state.
			--- This includes setting the appropriate stage and operation based on previously saved client data.
			function Tool:RestoreMode()
				--- The ToolMode variable is in the format "Stage:Op", where Stage and Op are the current stage and operation.
				--- self.Mode is the current acf tool itself (e.g. "acf_menu"/"acf_copy")
				local ToolMode = ACF.GetClientString(self:GetOwner(), "ToolMode:" .. self.Mode)

				if ToolMode then
					-- Explode the ToolMode string to get stage and operation as an array, then unpack as a vararg
					local Stage, Op = unpack(string.Explode(":", ToolMode), 1, 2)

					self:SetMode(Stage, Op)
				end
			end

			--- The rest of these bind into tool hooks (https://wiki.facepunch.com/gmod/TOOL_Hooks)

			--- Handles left clicks and calls the "OnLeftClick" method for the current operation if defined.
			--- @param Trace any The eye trace to pass to the callback
			--- @return boolean # Used to block tool from being used when no valid operation exists.
			function Tool:LeftClick(Trace)
				if self.OpData then
					local OnLeftClick = self.OpData.OnLeftClick

					if OnLeftClick then
						return OnLeftClick(self, Trace)
					end
				end

				return false
			end

			--- Handles right clicks and calls the "OnRightClick" method for the current operation if defined.
			function Tool:RightClick(Trace)
				if self.OpData then
					local OnRightClick = self.OpData.OnRightClick

					if OnRightClick then
						return OnRightClick(self, Trace)
					end
				end

				return false
			end

			--- Handles reloads (usually "r" key) and calls the "OnReload" method for the current operation if defined.
			function Tool:Reload(Trace)
				if self.OpData then
					local OnReload = self.OpData.OnReload

					if OnReload then
						return OnReload(self, Trace)
					end
				end

				return false
			end

			--- Handles deploys (when you switch to the acf tool or start using it) and calls the "OnDeploy" method if defined.
			function Tool:Deploy()
				self:RestoreMode()

				if self.OpData then
					local OnDeploy = self.OpData.OnDeploy

					if OnDeploy then
						OnDeploy(self)
					end
				end
			end

			--- Handles deploys (when you switch to another tool and holster the acf tool) and calls the "OnDeploy" method if defined.
			function Tool:Holster()
				if self.OpData then
					local OnHolster = self.OpData.OnHolster

					if OnHolster then
						OnHolster(self)
					end
				end
			end

			--- Handles thinks (happen repeatedly while the tool is equipped) and calls the "OnThink" method if defined.
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
		-- When the client specifies a new tool mode, switch to the new stage and operation.
		hook.Add("ACF_OnClientDataUpdate", "ACF ToolMode", function(Player, Key, Value)
			--- Check if the key is of the form (e.g. "ToolMode:acf_menu"/"ToolMode:acf_copy")
			local Header, Name = unpack(string.Explode(":", Key), 1, 2)
			if Header ~= "ToolMode" then return end

			local Tool = Player:GetTool(Name)

			if not Tool then return end
			if not Tool.SetMode then return end

			--- Set the stage and operation (if you're curious, check Tool:RestoreMode above.)
			local Stage, Op = unpack(string.Explode(":", Value), 1, 2)

			Tool:SetMode(Stage, Op)
		end)
	elseif CLIENT then
		-- Format of tool data for use with SetClientData
		local Key = "ToolMode:%s" -- (e.g. "ToolMode:acf_menu")
		local Value = "%s:%s" -- (e.g. "Spawner":"Weapon")

		--- Used by the client to network the current state of a tool, its stage and its operation. 
		--- @param Tool string The name of the tool (e.g. "acf_menu"/"acf_copy")
		--- @param Stage string The stage of the tool (e.g. "Spawner"/"Main")
		--- @param Op string The operation of the tool (e.g. "Weapon"/"Sensor"/etc.)
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

	--- Creates a menu operation  
	--- Mostly serves as a wrapper for (https://wiki.facepunch.com/gmod/Tool_Information_Display)  
	--- Internally links the helpers SpawnEntity and SelectEntity to your left and right mouse  
	--- To actually define an entity's linking or spawn behaviour, use the entity files (e.g. init.lua)  
	--- @param Name string The name of the link type performed by the toolgun (e.g. Weapon, Engine, etc.)
	--- @param Primary string The type of the entity to be spawned on left click (purely aesthetical)
	--- @param Secondary string The type of entity to be spawned on shift + right click (purely aesthetical)
	function ACF.CreateMenuOperation(Name, Primary, Secondary)
		if not isstring(Name) then return end
		if not isstring(Primary) then return end

		Secondary = ACF.CheckString(Secondary)

		do -- Spawner stuff
			-- These basically setup the tool information display you see on the top left of your screen
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
