local ACF = ACF

ACF.Tools = ACF.Tools or {}

-- DISCLAIMER
-- Usually you have a few operations, and each operation has its own set of stages.
-- For whatever reason, the reverse is done here. So each stage has its own set of operations.

--- Special datatype annotations -----------------------------------------------------------

--- This represents the actual tool class gmod uses, with some additional propperties we set
--- Pretty much represents the current state of the tool (like the current stage and operation)
--- @class Tool
--- @field Mode string The Mode of the tool (kind of like the name) (e.g. "acf_menu"/"acf_copy")
--- @field Stage number The current stage index of the tool
--- @field Operation number The current operation index of the tool
--- @field StageData Stage The data for the current stage
--- @field OpData Operation The data for the current operation
--- @field Information table<number, ToolInfo>

--- Represents an entry in the tool information display for a given operation in a given stage of a given tool  
--- (see https://wiki.facepunch.com/gmod/Tool_Information_Display)  
--- name text, icon1 and icon2 are the only things that actually end up displayed in the tool binds display
--- PLEASE read the wiki page on name (the way it interacts with the icons is not intuitive)
--- @class ToolInfo
--- @field name string A unique? name for the entry (READ THE WIKI TO SEE HOW IT WORKS) (e.g. "left"/"right_shift")
--- @field text string The description to display (e.g. "Left click to select.")
--- @field icon string | nil A path to the first icon (e.g. "gui/lmb.png")
--- @field icon2 string | nil A second icon path, for key combination icons (e.g. "gui/info.png")
--- @field DrawToolScreen function | nil Replaces the tool's DrawToolScreen method (see https://wiki.facepunch.com/gmod/TOOL:DrawToolScreen)
--- @field stage number The index of the stage in the tool
--- @field op number The index of the operation in the stage above

--- A table representing the data a tool can have.  
--- Initialized in GetToolData
--- @class ToolData
--- @field Tool Tool|nil The tool this tooldata belongs to
--- @field Stages table<string, Stage> A table to hold stages by name
--- @field Indexed table<number, Stage> Array counterpart to the Stages field
--- @field Count number The number of stages
--- @field InfoLookup table<string, ToolInfo> A lookup table for information entries by name (stage and operation)
--- @field Information table<number, ToolInfo> Array counterpart to the InfoLookup field
--- @field InfoCount number The number of information entries

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
--- @field DrawToolScreen function | nil A function to handle what should be drawn on the tool's screen (see https://wiki.facepunch.com/gmod/TOOL:DrawToolScreen)

--------------------------------------------------------------------------------------------

--- A table to manage the data and behavior of tools.
--- @type table<string, ToolData>
local Tools = ACF.Tools

--- Retrieves the tool data for a given tool.  
--- If the tool data doesn't already exist, it will initialize it.
--- USE THIS TO INITIALIZE YOUR TOOL DATA.
--- @param Tool string The name of the tool. (e.g. "acf_copy"/"acf_menu")
--- @return ToolData # The data structure for the specified tool.
local function GetToolData(Tool)
	if not Tools[Tool] then
		Tools[Tool] = {
			Indexed = {},
			Stages = {},
			Count = 0,
			InfoLookup = {},
			Information = {},
			InfoCount = 0,
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
	--- Registers and returns a state for a tool.,If the state already existed, it uses that.
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
		local Name = Info.name .. "_" .. StageIdx .. "_" .. OpIdx -- (e.g. "info_0_1")
		local New = Data.InfoLookup[Name] -- Preexisting info entry

		-- If an information entry didn't already exist for this stage and operation, make one.
		if not New then
			local Count = Data.InfoCount + 1

			New = {}

			Data.InfoLookup[Name] = New
			Data.InfoCount = Count
			Data.Information[Count] = New
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
			--- @param self Tool
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