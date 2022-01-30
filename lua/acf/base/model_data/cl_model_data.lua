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

function ModelData.QueueRefresh(Model, Panel, Callback)
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

function ModelData.GetModelData(Model)
	local Path = ModelData.GetModelPath(Model)

	if not Path then return end
	if Standby[Path] then return end

	local Data = Models[Path]

	if IsValid(ModelData.Entity) and Data then
		return Data
	elseif not Data then
		Network.Send("ACF_ModelData", Path)
	end
end

hook.Add("ACF_OnAddonLoaded", "ACF_ModelData", function()
	local CheckEntity

	local function UpdateEntity(Entity)
		ModelData.Entity = Entity

		for Model, Data in pairs(Standby) do
			if Data == true then continue end -- Information hasn't been received yet

			Standby[Model] = nil
			Models[Model]  = Data

			hook.Run("ACF_OnReceivedModelData", Model, Data)
		end

		Entity:CallOnRemove("ACF_ModelData", function()
			hook.Add("OnEntityCreated", "ACF_ModelData", CheckEntity)
		end)

		hook.Remove("OnEntityCreated", "ACF_ModelData")
	end

	CheckEntity = function(Entity)
		if Entity:EntIndex() ~= ModelData.EntIndex then return end

		UpdateEntity(Entity)
	end

	Network.CreateReceiver("ACF_ModelData_Entity", function(Data)
		local Index    = Data.Index
		local ModelEnt = Entity(Index)

		ModelData.EntIndex = Index

		if not IsValid(ModelEnt) then
			hook.Add("OnEntityCreated", "ACF_ModelData", CheckEntity)

			return
		end

		UpdateEntity(ModelEnt)
	end)

	Network.CreateSender("ACF_ModelData", function(Queue, Model)
		Standby[Model] = true
		Queue[Model]   = true

		hook.Run("ACF_OnRequestedModelData", Model)
	end)

	Network.CreateReceiver("ACF_ModelData", function(Data)
		local Exists = IsValid(ModelData.Entity)

		for Model, Info in pairs(Data) do
			if not Exists then
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
