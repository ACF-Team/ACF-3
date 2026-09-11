local ACF      = ACF
local Entities = ACF.Entities
local Messages = ACF.Utilities.Messages

util.AddNetworkString("ACF_MenuCommit")
util.AddNetworkString("ACF_MenuCopy")
util.AddNetworkString("ACF_MenuLinkState")
util.AddNetworkString("ACF_MenuLinkClear")

ACF.Menu = ACF.Menu or {}

local NextCommit = {} -- [Player] = next allowed CurTime

local function CanCommit(Player)
	if not IsValid(Player) then return false end

	local Weapon = Player:GetActiveWeapon()
	if not IsValid(Weapon) or Weapon:GetClass() ~= "gmod_tool" then return false end

	local Now = CurTime()
	if (NextCommit[Player] or 0) > Now then return false end
	NextCommit[Player] = Now + 0.05

	return true
end

-- =============================================================================================
-- Spawn / update
-- =============================================================================================

local function DoSpawn(Player, ClassName, Data)
	local Trace = Player:GetEyeTrace()
	if Trace.HitSky then return end

	local Entity = Trace.Entity

	if IsValid(Entity) and Entity:GetClass() == ClassName then
		local Result, Message = Entities.Update(Entity, Data)
		Messages.SendChat(Player, Result and "Info" or "Error", Message)
		return
	end

	local Position = Trace.HitPos + Trace.HitNormal * 128
	local Angles   = Trace.HitNormal:Angle():Up():Angle()

	local Success, Result = Entities.Spawn(ClassName, Player, Position, Angles, Data)

	if not Success then
		Messages.SendChat(Player, "Error", "Couldn't create entity: " .. tostring(Result))
		return
	end

	local PhysObj = Result:GetPhysicsObject()

	if Result.ACF_PostMenuSpawn then
		Result:ACF_PostMenuSpawn(Trace)
	else
		ACF.DropToFloor(Result)
	end

	Result:SetSpawnEffect(true)

	if IsValid(PhysObj) then
		PhysObj:EnableMotion(false)
	end
end

-- =============================================================================================
-- Link / unlink (ported from operations/acf_menu.lua; state kept per player, no ClientData)
-- =============================================================================================

local Green      = Color(0, 255, 0)
local NameFormat = "%s [ID: %s]"
local PlayerEnts = {}

local function GetPlayerEnts(Player)
	local Ents = PlayerEnts[Player]
	if not Ents then Ents = {} PlayerEnts[Player] = Ents end
	return Ents
end

local function CountSelected(Player)
	local N = 0
	for _ in pairs(GetPlayerEnts(Player)) do N = N + 1 end
	return N
end

-- Tells the client how many entities it currently has selected, so the tool's instruction HUD can
-- switch between "spawn" and "link" guidance. Sent whenever the selection changes.
local function SendLinkState(Player)
	if not IsValid(Player) then return end

	net.Start("ACF_MenuLinkState")
		net.WriteUInt(CountSelected(Player), 16)
	net.Send(Player)
end

local function GetName(Entity)
	return NameFormat:format(Entity.Name or Entity:GetClass(), Entity:EntIndex())
end

local function UnselectEntity(Entity, Player)
	local Ents = GetPlayerEnts(Player)
	if not Ents[Entity] then return end

	if IsValid(Entity) then
		Entity:RemoveCallOnRemove("ACF_ToolLinking")
		Entity:SetColor(Ents[Entity])
	end

	Ents[Entity] = nil
end

local function UnselectAll(Player)
	for Entity in pairs(GetPlayerEnts(Player)) do
		UnselectEntity(Entity, Player)
	end
end

local function SelectEntity(Entity, Player)
	if not ACF.Check(Entity) then return false end

	local Ents = GetPlayerEnts(Player)

	Ents[Entity] = Entity:GetColor()
	Entity:CallOnRemove("ACF_ToolLinking", function(Removed)
		UnselectEntity(Removed, Player)
		SendLinkState(Player)
	end)
	Entity:SetColor(Green)

	return true
end

local function LinkEntities(Player, Target)
	local Ents   = GetPlayerEnts(Player)
	local OnKey  = Player:KeyDown(IN_RELOAD)
	local Action = OnKey and "unlink" or "link"
	local Done, Failed = 0, {}

	for Source in pairs(Ents) do
		if not ACF.Check(Source) then continue end

		-- Prefer the selected entity's own Link/Unlink (called Source:Link(Target)); fall back to the
		-- target's method (Target:Link(Source)). Mirrors the old linker's dispatch.
		local Result, Message = false, nil

		if OnKey then
			if Source.Unlink then Result, Message = Source:Unlink(Target)
			elseif Target.Unlink then Result, Message = Target:Unlink(Source) end
		else
			if Source.Link then Result, Message = Source:Link(Target)
			elseif Target.Link then Result, Message = Target:Link(Source) end
		end

		if Result then
			Done = Done + 1
		else
			Failed[#Failed + 1] = GetName(Source) .. ": " .. (Message or "No reason given.")
		end

		UnselectEntity(Source, Player)
	end

	if Done > 0 then
		Messages.SendChat(Player, "Info", ("Successfully %sed %d entit%s to %s."):format(Action, Done, Done == 1 and "y" or "ies", GetName(Target)))
	end

	if #Failed > 0 then
		Messages.SendChat(Player, "Error", ("Couldn't %s some entities to %s:\n%s"):format(Action, GetName(Target), table.concat(Failed, "\n")))
	end
end

local function DoLink(Player)
	local Trace  = Player:GetEyeTrace()
	local Entity = Trace.Entity

	if Trace.HitWorld then
		UnselectAll(Player)
		SendLinkState(Player)
		return
	end

	if not ACF.Check(Entity) then return end

	if Player:KeyDown(IN_SPEED) then
		-- Toggle selection of the aimed entity.
		if GetPlayerEnts(Player)[Entity] then
			UnselectEntity(Entity, Player)
		else
			SelectEntity(Entity, Player)
		end
		SendLinkState(Player)
		return
	end

	-- Not holding shift: link everything selected to the aimed entity. If nothing is selected yet,
	-- start a selection with it (mirrors the old spawner->linker hand-off).
	if not next(GetPlayerEnts(Player)) then
		SelectEntity(Entity, Player)
		SendLinkState(Player)
		return
	end

	LinkEntities(Player, Entity)
	SendLinkState(Player)
end

-- =============================================================================================
-- Page functions
-- =============================================================================================

local function DoFunc(Player, PageID, ActionIndex)
	local Page = ACF.Menu.GetPage and ACF.Menu.GetPage(PageID)
	if not Page or not Page.Actions then return end

	local Action = Page.Actions[ActionIndex]
	if not Action or not Action.Func then return end

	Action.Func(Player, Player:GetEyeTrace())
end

-- =============================================================================================
-- Receiver
-- =============================================================================================

net.Receive("ACF_MenuCommit", function(_, Player)
	local Kind = net.ReadString()

	-- Read the payload BEFORE the CanCommit gate so the message is always fully consumed.
	local ClassName, Data, PageID, ActionIndex

	if Kind == "spawn" then
		ClassName = net.ReadString()
		Data      = net.ReadTable()
	elseif Kind == "func" then
		PageID      = net.ReadString()
		ActionIndex = net.ReadUInt(8)
	end

	if not CanCommit(Player) then return end

	if Kind == "spawn" then
		DoSpawn(Player, ClassName, Data)
	elseif Kind == "func" then
		DoFunc(Player, PageID, ActionIndex)
	elseif Kind == "link" then
		DoLink(Player)
	end
end)

-- Clearing a selection is always safe and cheap, so it skips the commit rate-limit/tool checks (it's
-- also fired on holster, when the active weapon may already have changed).
net.Receive("ACF_MenuLinkClear", function(_, Player)
	if not IsValid(Player) then return end
	if not next(GetPlayerEnts(Player)) then return end

	UnselectAll(Player)
	SendLinkState(Player)
end)

hook.Add("PlayerDisconnected", "ACF_Menu_Commit", function(Player)
	NextCommit[Player] = nil
	PlayerEnts[Player] = nil
end)

--- Server->client: push an existing entity's serialized config to a player (future copy feature).
function ACF.Menu.SendCopy(Player, Entity)
	if not IsValid(Player) or not IsValid(Entity) then return end

	local Class = ACF.Classes.GetTypeByName(Entity:GetClass())
	if not Class or not Entity.ACF_LiveData then return end -- only ACF entities carry live config

	local Data = ACF.Classes.Serialization.Serialize(Class, Entity.ACF_LiveData)

	net.Start("ACF_MenuCopy")
		net.WriteString(Entity:GetClass())
		net.WriteTable(Data)
	net.Send(Player)
end
