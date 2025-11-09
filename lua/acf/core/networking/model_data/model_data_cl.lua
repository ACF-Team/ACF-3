local ACF       = ACF
local ModelData = ACF.ModelData
local Models    = ModelData.Models

function ModelData.GetModelData(Model)
	local Path = ModelData.GetModelPath(Model)
	if not Path then return end

	local Data = Models[Path]
	if Data then return Data end

	local EntTest = ents.CreateClientProp(Model)
	EntTest:SetPos(Vector(0, 0, 0))
	EntTest:Spawn()

	local PhysObj = EntTest:GetPhysicsObject()
	local Min, Max = PhysObj:GetAABB()
	Data = {
		Mesh   = ModelData.SanitizeMesh(PhysObj),
		Volume = PhysObj:GetVolume(),
		Center = (Min + Max) * 0.5,
		Size   = Max - Min
	}
	timer.Simple(0, function() if IsValid(EntTest) then EntTest:Remove() end end)
	Models[Path] = Data

	-- backwards compat
	hook.Run("ACF_OnReceiveModelData", Path, Data)

	return Data
end

hook.Add("ACF_OnLoadAddon", "ACF_ModelData", function()
	local CheckEntity

	local function UpdateEntity(Entity)
		ModelData.Entity = Entity

		Entity:CallOnRemove("ACF_ModelData", function()
			hook.Add("OnEntityCreated", "ACF_ModelData", CheckEntity)
		end)

		hook.Remove("OnEntityCreated", "ACF_ModelData")
	end

	CheckEntity = function(Entity)
		if Entity:EntIndex() ~= ModelData.EntIndex then return end

		UpdateEntity(Entity)
	end

	net.Receive("ACF_ModelData_Entity", function()
		local Index    = net.ReadUInt(MAX_EDICT_BITS)
		local ModelEnt = Entity(Index)
		ModelData.EntIndex = Index

		if not IsValid(ModelEnt) then
			hook.Add("OnEntityCreated", "ACF_ModelData", CheckEntity)

			return
		end

		UpdateEntity(ModelEnt)
	end)

	hook.Remove("ACF_OnLoadAddon", "ACF_ModelData")
end)