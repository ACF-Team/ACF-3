local ACF       = ACF
local ModelData = ACF.ModelData
local Models    = ModelData.Models
local Network   = ACF.Networking
local Standby   = {}
local Callbacks = {}

function ModelData.IsOnStandby(Model)
	local Path = ModelData.GetModelPath(Model)

	return Standby[Path] or false
end

function ModelData.GetModelData(Model)
	local Path = ModelData.GetModelPath(Model)

	if not Path then return end
	if Standby[Path] then return end
	if not IsValid(ModelData.Entity) then return end

	local Data = Models[Path]

	if Data then return Data end

	Network.Send("ACF_ModelData", Path)
end

function ModelData.QueuePanelRefresh(Model, Panel, Callback)
	if not IsValid(Panel) then return end
	if not isfunction(Callback) then return end

	local Path = ModelData.GetModelPath(Model)

	if not Path then return end
	if Models[Path] then return end

	local Data = Callbacks[Path]

	if Data then
		Data[Panel] = Callback
	else
		Callbacks[Path] = {
			[Panel] = Callback
		}
	end
end

hook.Add("ACF_OnAddonLoaded", "ACF_ModelData", function()
	local function ProcessReceived()
		for Model, Data in pairs(Standby) do
			if Data == true then continue end -- Information hasn't been received yet

			Standby[Model] = nil
			Models[Model]  = Data

			hook.Run("ACF_OnReceivedModelData", Model, Data)
		end

		hook.Remove("OnEntityCreated", "ACF_ModelData")
	end

	local function CheckEntity(Entity)
		if Entity:EntIndex() ~= ModelData.EntIndex then return end

		print("[CLIENT] Found ModelData entity", Entity)

		ModelData.Entity   = Entity
		ModelData.EntIndex = nil

		ProcessReceived()
	end

	Network.CreateReceiver("ACF_ModelData_Entity", function(Data)
		local Index  = Data.Index
		local Entity = ents.GetByIndex(Index)

		if not IsValid(Entity) then
			ModelData.EntIndex = Index

			hook.Add("OnEntityCreated", "ACF_ModelData", CheckEntity)

			return print("[CLIENT] Entity doesn't exist yet, queueing", Index)
		end

		ModelData.Entity   = Entity
		ModelData.EntIndex = nil

		ProcessReceived()

		print("[CLIENT] Received ModelData entity", Entity)
	end)

	Network.CreateSender("ACF_ModelData", function(Queue, Model)
		Standby[Model] = true
		Queue[Model]   = true

		hook.Run("ACF_OnRequestedModelData", Model)
	end)

	Network.CreateReceiver("ACF_ModelData", function(Data)
		for Model, Info in pairs(Data) do
			if not IsValid(ModelData.Entity) then
				Standby[Model] = Info
			else
				Standby[Model] = nil
				Models[Model]  = Info

				hook.Run("ACF_OnReceivedModelData", Model, Info)
			end
		end
	end)

	hook.Remove("ACF_OnAddonLoaded", "ACF_ModelData")
end)

hook.Add("ACF_OnReceivedModelData", "ACF_ModelData_PanelRefresh", function(Model)
	local Data = Callbacks[Model]

	if not Data then return end

	for Panel, Callback in pairs(Data) do
		if IsValid(Panel) then
			Callback(Panel, Model)
		end

		Data[Panel] = nil
	end

	Callbacks[Model] = nil
end)
