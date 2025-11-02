local ACF       = ACF
local ModelData = ACF.ModelData
local Models    = ModelData.Models

function ModelData.GetModelData(Model)
	local Path = ModelData.GetModelPath(Model)
	if not Path then return end

	local Data = Models[Path]
	if Data then return Data end

	local Entity = ents.CreateClientProp(Model)
	Entity:SetPos(Vector(0, 0, 0))
	Entity:Spawn()

	local Min, Max = Entity:GetModelBounds()
	local PhysObj  = Entity:GetPhysicsObject()

	Data = {
		Mesh   = ModelData.SanitizeMesh(PhysObj),
		Volume = PhysObj:GetVolume(),
		Center = (Min + Max) * 0.5,
		Size   = Max - Min
	}

	Models[Path] = Data

	timer.Simple(0, function() if IsValid(Entity) then Entity:Remove() end end)

	hook.Run("ACF_OnReceiveModelData", Path, Data)

	return Data
end