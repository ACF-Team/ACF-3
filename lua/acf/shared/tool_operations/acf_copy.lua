local CopiedData = {}
local Disabled = {}
local ACF = ACF

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

	hook.Add("PlayerInitialSpawn", "ACF Copy Data", function(Player)
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

ACF.RegisterOperation("acfcopy", "Main", "CopyPaste", {
	OnLeftClick = function(Tool, Trace)
		if Trace.HitSky then return false end

		local Entity = Trace.Entity
		local Player = Tool:GetOwner()

		if not IsValid(Entity) then return false end
		if not isfunction(Entity.Update) then
			ACF.SendMessage(Player, "Error", "This entity doesn't support updating!")
			return false
		end

		local Class = Entity:GetClass()
		local Saved = GetCopyData(Player, Class)

		if not Saved then
			ACF.SendMessage(Player, "Error", "No information has been copied for '", Class, "' entities!")
			return false
		end

		local DisabledData = GetDisabledData(Player, Class)
		local Data = {}

		for K, V in pairs(Saved) do
			local Value = V

			if DisabledData[K] then
				Value = Entity[K]
			end

			Data[K] = Value
		end

		local Result, Message = ACF.UpdateEntity(Entity, Data)

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
	name = "right",
	text = "Copy the relevant information from an ACF entity.",
})

ACF.RegisterToolInfo("acfcopy", "Main", "CopyPaste", {
	name = "info",
	text = "You can toggle the copied information you want to apply/ignore when updating an ACF entity on the tool menu.",
})
