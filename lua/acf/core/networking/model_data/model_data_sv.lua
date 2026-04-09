-- TODO: Does making a pointer on server and client separately work? it would save networking.
local ACF       = ACF
ACF.ModelData = ACF.ModelData or {}
local ModelData = ACF.ModelData
ModelData.Models = ModelData.Models or {}
local Models    = ModelData.Models
local util = util

--- Returns the pointer entity, creating it if it doesn't exist
local function EnsurePointerEntity()
	if IsValid(ModelData.Entity) then return ModelData.Entity end

	-- Something BAD happened if this fails
	local Entity = ents.Create("base_entity")
	if not IsValid(Entity) then return error("[ACF] Failed to create ModelData entity serverside!") end

	Entity:SetModel("models/props_junk/popcan01a.mdl")
	Entity:PhysicsInit(SOLID_VPHYSICS)
	Entity:SetMoveType(MOVETYPE_NONE)
	Entity:SetCollisionGroup(COLLISION_GROUP_WORLD)
	Entity:SetNotSolid(true)
	Entity:SetNoDraw(true)
	Entity:Spawn()

	-- When the entity is removed, recreate it as soon as possible
	Entity:CallOnRemove("ACF_ModelData", function()
		hook.Add("Think", "ACF_ModelData_Entity", function()
			EnsurePointerEntity()
			hook.Remove("Think", "ACF_ModelData_Entity")
		end)
	end)

	ModelData.Entity = Entity
	return ModelData.Entity
end

ModelData.EnsurePointerEntity = EnsurePointerEntity

-- After all the entities are initialized
hook.Add("InitPostEntity", "ACF_ModelData", function()
	EnsurePointerEntity()
	hook.Remove("InitPostEntity", "ACF_ModelData")
end)

-- When a player spawns in
hook.Add("ACF_OnLoadPlayer", "ACF_ModelData", function(_)
	EnsurePointerEntity()
end)

-- Prevent recreating the entity when the server is shutting down
hook.Add("ShutDown", "ACF_ModelData", function()
	local Entity = ModelData.Entity
	if not IsValid(Entity) then return end
	Entity:RemoveCallOnRemove("ACF_ModelData")
end)

-------------------------------------------------------------------

--- Returns mesh and physics data about a model
--- Internally handles caching and creating a pointer entity to get the physics data of the model
function ModelData.GetModelData(Model)
	local Path = ModelData.GetModelPath(Model) -- Verify model exists
	if not Path then return end

	local Data = Models[Path] -- See if we cached it before
	if Data then return Data end

	util.PrecacheModel(Model) -- Cache the model itself

	-- Reinitialize the pointer entity with a new model
	local Ent = EnsurePointerEntity()
	Ent:SetModel(Model)
	Ent:PhysicsInit(SOLID_VPHYSICS)
	local PhysObj = Ent:GetPhysicsObject()
	if not IsValid(PhysObj) then return end

	-- Save properties of the physics object
	local Min, Max = PhysObj:GetAABB()
	Data = {
		Mesh   = ModelData.GetMultiConvex(PhysObj),
		Volume = PhysObj:GetVolume(),
		Center = (Min + Max) * 0.5,
		Size   = Max - Min,
	}

	Models[Path] = Data -- Cache the data for future use

	return Data
end