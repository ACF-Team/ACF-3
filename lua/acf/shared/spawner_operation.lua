local ACF       = ACF
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
	if not ACF.CheckString(Name) then return end
	if not ACF.CheckString(Primary) then return end

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
		ACF.RegisterOperation("acf_menu", "Spawner", Name, {
			OnLeftClick = function(Tool, Trace)
				if Trace.HitSky then return false end

				local Player    = Tool:GetOwner()
				local Data      = ACF.GetAllClientData(Player)
				local UseSecond = Player:KeyDown(IN_SPEED) or Player:KeyDown(IN_RELOAD)
				local ClassName = UseSecond and Data.SecondaryClass or Data.PrimaryClass

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
