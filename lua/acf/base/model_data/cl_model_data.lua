local ACF       = ACF
local ModelData = ACF.ModelData
local Models    = ModelData.Models
local Network   = ACF.Networking
local Standby   = {}

function ModelData.IsOnStandby(Model)
	local Path = ModelData.GetModelPath(Model)

	return Standby[Path] or false
end

function ModelData.GetModelData(Model)
	local Path = ModelData.GetModelPath(Model)

	if not Path then return end
	if Standby[Path] then return end

	local Data = Models[Path]

	if Data then return Data end

	Network.Send("ACF_ModelData", Path)
end

hook.Add("ACF_OnAddonLoaded", "ACF_ModelData", function()
	Network.CreateReceiver("ACF_ModelData_Entity", function(Data)
		local Index  = next(Data)
		local Entity = ents.GetByIndex(Index)

		if not IsValid(Entity) then return end

		ModelData.Entity = Entity
	end)

	Network.CreateSender("ACF_ModelData", function(Queue, Model)
		Standby[Model] = true
		Queue[Model]   = true

		hook.Run("ACF_OnRequestedModelData", Model)
	end)

	Network.CreateReceiver("ACF_ModelData", function(Data)
		for Model, Info in pairs(Data) do
			Standby[Model] = nil
			Models[Model]  = Info

			hook.Run("ACF_OnReceivedModelData", Model, Info)
		end
	end)

	hook.Remove("ACF_OnAddonLoaded", "ACF_ModelData")
end)
