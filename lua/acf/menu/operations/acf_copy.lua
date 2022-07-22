local ACF        = ACF
local Entities   = ACF.Classes.Entities
local CopiedData = {}
local Disabled   = {}


local function GetDisabledData(Player, Class)
	return Disabled[Player][Class]
end

if SERVER then
	util.AddNetworkString("ACF_SendCopyData")
	util.AddNetworkString("ACF_SendDisabledData")

	net.Receive("ACF_SendDisabledData", function(_, Player)
		local Class = net.ReadString()
		local Data  = net.ReadString()
		local State = net.ReadBool() or nil

		if not IsValid(Player) then return end

		local DisabledData = GetDisabledData(Player, Class)

		DisabledData[Data] = State
	end)

	hook.Add("ACF_OnPlayerLoaded", "ACF Copy Data", function(Player)
		CopiedData[Player] = {}
		Disabled[Player] = {}
	end)

	hook.Add("PlayerDisconnected", "ACF Copy Data", function(Player)
		CopiedData[Player] = nil
		Disabled[Player] = nil
	end)
end

local function GetCopyData(Player, Class)
	return CopiedData[Player][Class]
end

local function SaveCopyData(Player, Entity)
	local Class = Entity:GetClass()
	local Data  = GetCopyData(Player, Class)
	local List  = {}
	local Count = 0

	if not Data then
		Data = {}

		CopiedData[Player][Class] = Data
	else
		for K in pairs(Data) do
			Data[K] = nil
		end
	end

	for _, V in ipairs(Entity.DataStore) do
		local Value = Entity[V]

		if Value ~= nil then
			Count = Count + 1

			Data[V] = Value
			List[Count] = {
				Key = V,
				Value = Value,
			}
		end
	end

	if not GetDisabledData(Player, Class) then
		Disabled[Player][Class] = {}
	end

	return util.TableToJSON(List)
end

local function GetSpawnData(Player, Entity, Class)
	local Saved = GetCopyData(Player, Class)

	if not Saved then return end

	local Ignored = GetDisabledData(Player, Class)
	local Data    = {}

	for K, V in pairs(Saved) do
		if Ignored[K] then
			Data[K] = Entity and Entity[K]
		else
			Data[K] = V
		end
	end

	return Data
end

local function CreateNewEntity(Player, Trace)
	local Class = ACF.GetClientData(Player, "CopyClass")

	if not Class then return false end

	local Data     = GetSpawnData(Player, nil, Class)
	local Position = Trace.HitPos + Trace.HitNormal * 128
	local Angles   = Trace.HitNormal:Angle():Up():Angle()
	local Message  = ""

	local Success, Result = Entities.Spawn(Class, Player, Position, Angles, Data)

	if not Success then
		Message = "Couldn't create entity: " .. Result
	else
		local PhysObj = Result:GetPhysicsObject()

		Result:DropToFloor()

		if IsValid(PhysObj) then
			PhysObj:EnableMotion(false)
		end

		Message = "Entity created successfully."
	end

	ACF.SendMessage(Player, Result and "Info" or "Error", Message)

	return true
end

ACF.RegisterOperation("acfcopy", "Main", "CopyPaste", {
	OnLeftClick = function(Tool, Trace)
		if Trace.HitSky then return false end

		local Entity = Trace.Entity
		local Player = Tool:GetOwner()

		if not IsValid(Entity) then return CreateNewEntity(Player, Trace) end
		if not isfunction(Entity.Update) then
			ACF.SendMessage(Player, "Error", "This entity doesn't support updating!")
			return false
		end

		local Class = Entity:GetClass()
		local Data  = GetSpawnData(Player, Entity, Class)

		if not Data then
			ACF.SendMessage(Player, "Error", "No information has been copied for '", Class, "' entities!")
			return false
		end

		local Result, Message = Entities.Update(Entity, Data)

		if not Result then
			Message = "Couldn't update entity: " .. Message
		end

		ACF.SendMessage(Player, Result and "Info" or "Error", Message)

		return true
	end,
	OnRightClick = function(Tool, Trace)
		if Trace.HitSky then return false end

		local Entity = Trace.Entity

		if not IsValid(Entity) then return false end
		if not Entity.DataStore then return false end

		local Player = Tool:GetOwner()
		local List = SaveCopyData(Player, Entity)

		net.Start("ACF_SendCopyData")
			net.WriteString(Entity:GetClass())
			net.WriteString(List)
		net.Send(Player)

		return true
	end,
})

ACF.RegisterToolInfo("acfcopy", "Main", "CopyPaste", {
	name = "left",
	text = "Update the ACF entity with the copied information for its class.",
})

ACF.RegisterToolInfo("acfcopy", "Main", "CopyPaste", {
	name = "left_spawn",
	text = "If no entity is hit, a new entity will be created with the copied information.",
	icon2 = "gui/info",
})

ACF.RegisterToolInfo("acfcopy", "Main", "CopyPaste", {
	name = "right",
	text = "Copy the relevant information from an ACF entity.",
})

ACF.RegisterToolInfo("acfcopy", "Main", "CopyPaste", {
	name = "info",
	text = "You can toggle the copied information you want to apply/ignore when updating an ACF entity on the tool menu.",
})
