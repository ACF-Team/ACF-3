-- Please see lua\acf\menu\tool_functions.lua for more information on how this ACF tool works
local ACF = ACF

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

		local OnKeybind = Player:KeyDown(IN_SPEED)

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
	--- @param Secondary string | nil The type of entity to be spawned on shift + right click (purely aesthetical)
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

					-- The call to SelectEntity will switch the mode to the linker
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


ACF.CreateMenuOperation("Weapon", "weapon", "ammo crate")
ACF.CreateMenuOperation("Missile", "rack", "ammo crate")
ACF.CreateMenuOperation("Engine", "engine", "fuel tank")
ACF.CreateMenuOperation("Component", "component")
ACF.CreateMenuOperation("Gearbox", "gearbox")
ACF.CreateMenuOperation("Sensor", "sensor")