local ACF       = ACF
local ModelData = ACF.ModelData
local Models    = ModelData.Models
local Network   = ACF.Networking
local Standby   = {}
local Callbacks = {}

--- Returns the current state of the requested model information
-- @param Model The model to check.
-- @return True if the model has been requested and the client is waiting for it.
function ModelData.IsOnStandby(Model)
	local Path = ModelData.GetModelPath(Model)

	if not Path then return false end

	return Standby[Path] or false
end

--- Queues a function to be called for an object when the model data is received.
-- If the object is valid, the callback will be called with it as the first argument.
-- Otherwise, the callback won't be called at all.
-- @param Model The model to queue the callback for.
-- @param Object Anything that won't fail the IsValid check, usually panels or entities.
-- @param Callback The function to call when the model data is received.
function ModelData.QueueRefresh(Model, Object, Callback)
	if not IsValid(Object) then return end
	if not isfunction(Callback) then return end

	local Path = ModelData.GetModelPath(Model)

	if not Path then return end
	if Models[Path] then return end

	local Data = Callbacks[Path]

	if Data then
		Data[Object] = Callback
	else
		Callbacks[Path] = {
			[Object] = Callback
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

hook.Add("ACF_OnLoadAddon", "ACF_ModelData", function()
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

	hook.Remove("ACF_OnLoadAddon", "ACF_ModelData")
end)

hook.Add("ACF_OnReceivedModelData", "ACF_ModelData_PanelRefresh", function(Model)
	local Data = Callbacks[Model]

	if not Data then return end

	for Object, Callback in pairs(Data) do
		if IsValid(Object) then
			Callback(Object, Model)
		end

		Data[Object] = nil
	end

	Callbacks[Model] = nil
end)
