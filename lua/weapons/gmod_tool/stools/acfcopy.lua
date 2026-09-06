local ACF           = ACF
local Messages      = ACF.Utilities.Messages
local Serialization = ACF.Classes.Serialization
local CopiedData    = {}
local Disabled      = {}

TOOL.Category = (ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction"
TOOL.Name     = "#tool.acfcopy.name"
TOOL.Command  = nil
TOOL.ConfigName = ""
TOOL.Information = {
	{ name = "left" },
	{ name = "left_spawn", icon2 = "gui/info" },
	{ name = "right" },
	{ name = "info" },
}

if CLIENT then
	TOOL.BuildCPanel = ACF.CreateCopyMenu
end

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

		if DisabledData then
			DisabledData[Data] = State
		end
	end)

	hook.Add("ACF_OnLoadPlayer", "ACF Copy Data", function(Player)
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

	-- DataStore is gone on dev; the copyable data is the serialized class fields.
	local Serialized = Serialization.Serialize(Entity.ACF_ClassDef, Entity.ACF_LiveData)

	for Key, Value in pairs(Serialized) do
		if Value ~= nil then
			Count = Count + 1

			Data[Key] = Value
			List[Count] = {
				Key = Key,
				Value = Value,
			}
		end
	end

	if not GetDisabledData(Player, Class) then
		Disabled[Player][Class] = {}
	end

	return util.TableToJSON(List)
end

local function GetSpawnData(Player, Class)
	local Saved = GetCopyData(Player, Class)

	if not Saved then return end

	local Ignored = GetDisabledData(Player, Class) or {}
	local Data    = {}

	for K, V in pairs(Saved) do
		-- Omit disabled keys entirely: on update the deserializer keeps the target's current value,
		-- on spawn it falls back to the class default.
		if not Ignored[K] then
			Data[K] = V
		end
	end

	return Data
end

local function CreateNewEntity(Player, Trace)
	local Class = ACF.GetClientData(Player, "CopyClass")

	if not Class then return false end

	local Data     = GetSpawnData(Player, Class)
	local Position = Trace.HitPos + Trace.HitNormal * 128
	local Angles   = Trace.HitNormal:Angle():Up():Angle()
	local Message  = ""

	local Success, Result = ACF.Entities.Spawn(Class, Player, Position, Angles, Data)

	if not Success then
		Message = "#tool.acfcopy.create_fail " .. tostring(Result)
	else
		local PhysObj = Result:GetPhysicsObject()

		ACF.DropToFloor(Result)

		if IsValid(PhysObj) then
			PhysObj:EnableMotion(false)
		end

		Message = "#tool.acfcopy.create_succeed"
	end

	Messages.SendChat(Player, Result and "Info" or "Error", Message)

	return true
end

local function IsUpdatable(Entity)
	return isfunction(Entity.Update) or isfunction(Entity.ACF_UpdateEntityData)
end

function TOOL:LeftClick(Trace)
	if Trace.HitSky then return false end
	if CLIENT then return true end

	local Entity = Trace.Entity
	local Player = self:GetOwner()

	if not IsValid(Entity) then return CreateNewEntity(Player, Trace) end
	if not IsUpdatable(Entity) then
		Messages.SendChat(Player, "Error", "#tool.acfcopy.unsupported")
		return false
	end

	local Class = Entity:GetClass()
	local Data  = GetSpawnData(Player, Class)

	if not Data then
		Messages.SendChat(Player, "Error", "#tool.acfcopy.no_info_copied")
		return false
	end

	local Result, Message = ACF.Entities.Update(Entity, Data)

	if not Result then
		Message = "#tool.acfcopy.update_fail " .. tostring(Message)
	end

	Messages.SendChat(Player, Result and "Info" or "Error", Message)

	return true
end

function TOOL:RightClick(Trace)
	if Trace.HitSky then return false end
	if CLIENT then return true end

	local Entity = Trace.Entity

	-- print(Entity, Entity.ACF_ClassDef, Entity.ACF_LiveData)
	if not IsValid(Entity) then return false end
	if not Entity.ACF_ClassDef or not Entity.ACF_LiveData then return false end

	local Player = self:GetOwner()
	local List = SaveCopyData(Player, Entity)
	net.Start("ACF_SendCopyData")
		net.WriteString(Entity:GetClass())
		net.WriteString(List)
	net.Send(Player)

	return true
end
