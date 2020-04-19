local GetToolData = ACF.GetToolData
local GetEntityClass = ACF.GetEntityClass
local SendMessage = ACF.SendMessage
local Entities = {}

local function GetPlayerEnts(Player)
	local Ents = Entities[Player]

	if not Ents then
		Ents = {}
		Entities[Player] = Ents
	end

	return Ents
end

local function UnselectEntity(Tool, Player, Entity)
	local Ents = GetPlayerEnts(Player)

	Entity:RemoveCallOnRemove("ACF_ToolLinking")
	Entity:SetColor(Ents[Entity])

	Ents[Entity] = nil

	if not next(Ents) then
		Tool:SetMode("Main", "Spawner")
	end
end

local function SelectEntity(Tool, Player, Entity)
	local Ents = GetPlayerEnts(Player)

	if not next(Ents) then
		Tool:SetMode("Main", "Linker")
	end

	Ents[Entity] = Entity:GetColor()
	Entity:SetColor(Color(0, 255, 0))
	Entity:CallOnRemove("ACF_ToolLinking", function()
		UnselectEntity(Tool, Player, Entity)
	end)
end

local function CanTool(Player, Entity)
	if not IsValid(Entity) then return false end
	if not CPPI then return true end

	return Entity:CPPICanTool(Player, "#Tool.acf_menu2.name")
end

do -- Spawner operation
	local function CanUpdate(Player, Entity, ClassName)
		if not CanTool(Player, Entity) then return false end
		if Entity:GetClass() ~= ClassName then return false end
		if not isfunction(Entity.Update) then return false end

		return true
	end

	local function SpawnEntity(Player, ClassName, Trace, Data)
		if not ClassName or ClassName == "N/A" then return false end

		local Entity = Trace.Entity

		if CanUpdate(Player, Entity, ClassName) then
			Entity:Update(Data)
			return true
		end

		-- Couldn't update the entity, aborting spawn
		if IsValid(Entity) then return false end

		local Class = GetEntityClass(ClassName)

		if not Class then
			SendMessage(Player, "Error", ClassName, " is not a registered ACF entity class.")
			return false
		end

		local Position = Trace.HitPos + Trace.HitNormal * 128
		local Angles = Trace.HitNormal:Angle():Up():Angle()

		Entity = Class.Spawn(Player, Position, Angles, Data)

		if not IsValid(Entity) then
			SendMessage(Player, "Error", ClassName, " entity couldn't be created.")
			return false
		end

		Entity:Activate()
		Entity:DropToFloor()

		if CPPI then
			Entity:CPPISetOwner(Player)
		end

		undo.Create(ClassName)
			undo.AddEntity(Entity)
			undo.SetPlayer(Player)
		undo.Finish()

		local PhysObj = Entity:GetPhysicsObject()

		if IsValid(PhysObj) then
			PhysObj:EnableMotion(false)
			PhysObj:Sleep()
		end

		return true
	end

	ACF.RegisterOperation("acf_menu2", "Main", "Spawner", {
		OnLeftClick = function(Tool, Trace)
			if Trace.HitSky then return false end

			local Player = Tool:GetOwner()
			local Data = GetToolData(Player)
			local ClassName = Data.PrimaryClass

			return SpawnEntity(Player, ClassName, Trace, Data)
		end,
		OnRightClick = function(Tool, Trace)
			local Player = Tool:GetOwner()
			local Data = GetToolData(Player)
			local ClassName = Data.SecondaryClass

			if not Player:KeyDown(IN_SPEED) and SpawnEntity(Player, ClassName, Trace, Data) then
				return true
			end

			if not CanTool(Player, Trace.Entity) then return false end

			SelectEntity(Tool, Player, Trace.Entity)

			return true
		end,
	})

	ACF.RegisterToolInfo("acf_menu2", "Main", "Spawner", {
		name = "left",
		text = "Spawn or update the selected primary entity.",
	})

	ACF.RegisterToolInfo("acf_menu2", "Main", "Spawner", {
		name = "right",
		text = "If valid, spawn or update the selected secondary entity.",
	})

	ACF.RegisterToolInfo("acf_menu2", "Main", "Spawner", {
		name = "right_shift",
		text = "(Hold Shift) Select the entity you want to link or unlink.",
		icon2 = "gui/info",
	})
end

do -- Linker operation
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

		if Done > 0 then
			local Status = (Unlink and "unlinked " or "linked ") .. Done .. " out of " .. Total

			SendMessage(Player, "Info", "Successfully ", Status, " entities to ", tostring(Entity), ".")
		else
			local Status =  Total .. " entities could be " .. (Unlink and "unlinked" or "linked")

			SendMessage(Player, "Error", "None of the ", Status, " to ", tostring(Entity), ".")
		end
	end

	ACF.RegisterOperation("acf_menu2", "Main", "Linker", {
		OnRightClick = function(Tool, Trace)
			local Player = Tool:GetOwner()
			local Entity = Trace.Entity

			if Trace.HitWorld then Tool:Holster() return true end
			if not CanTool(Player, Entity) then return false end

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

	ACF.RegisterToolInfo("acf_menu2", "Main", "Linker", {
		name = "right",
		text = "Link all the selected entities to an entity.",
	})

	ACF.RegisterToolInfo("acf_menu2", "Main", "Linker", {
		name = "right_r",
		text = "Unlink all the selected entities from an entity.",
		icon2 = "gui/r.png",
	})

	ACF.RegisterToolInfo("acf_menu2", "Main", "Linker", {
		name = "right_shift",
		text = "Select another entity to link.",
		icon2 = "gui/info",
	})

	ACF.RegisterToolInfo("acf_menu2", "Main", "Linker", {
		name = "right_world",
		text = "(Hit the World) Unselected all selected entities.",
		icon2 = "gui/info",
	})
end
