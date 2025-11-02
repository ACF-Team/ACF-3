local ACF       = ACF
local ModelData = ACF.ModelData
local Models    = ModelData.Models

do -- Model data getter method
	local util = util

	local function CreateTempEntity(Model)
		util.PrecacheModel(Model)

		local Entity = ents.Create("base_entity")

		if not IsValid(Entity) then return nil end

		Entity:SetModel(Model)
		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_NONE)
		Entity:SetNotSolid(true)
		Entity:SetNoDraw(true)
		Entity:Spawn()

		return Entity
	end

	function ModelData.GetModelData(Model)
		local Path = ModelData.GetModelPath(Model)

		if not Path then return end

		local Data = Models[Path]

		if Data then return Data end

		local Entity = CreateTempEntity(Path)

		if not IsValid(Entity) then return end

		local PhysObj = Entity:GetPhysicsObject()

		if not IsValid(PhysObj) then
			Entity:Remove()
			return
		end

		local Min, Max = Entity:GetModelBounds()

		Data = {
			Mesh   = ModelData.SanitizeMesh(PhysObj),
			Volume = PhysObj:GetVolume(),
			Center = (Min + Max) * 0.5,
			Size   = Max - Min,
		}

		Models[Path] = Data

		Entity:Remove()

		return Data
	end
end