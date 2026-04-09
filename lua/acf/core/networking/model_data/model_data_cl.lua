local ACF       = ACF
ACF.ModelData = ACF.ModelData or {}
local ModelData = ACF.ModelData
ModelData.Models = ModelData.Models or {}
local Models    = ModelData.Models

--- Returns mesh and physics data about a model
--- Internally handles caching and creating a pointer entity to get the physics data of the model
function ModelData.GetModelData(Model)
	local Path = ModelData.GetModelPath(Model) -- Verify model exists
	if not Path then return end

	local Data = Models[Path] -- See if we cached it before
	if Data then return Data end

	-- Create a temporary entity to get the physics data of the model
	local EntTest = ents.CreateClientProp(Model)
	EntTest:SetPos(Vector(0, 0, 0))
	EntTest:Spawn()

	-- Remove the entity if the physics object is invalid
	local PhysObj = EntTest:GetPhysicsObject()
	if not IsValid(PhysObj) then
		timer.Simple(0, function() if IsValid(EntTest) then EntTest:Remove() end end)
		return
	end

	-- Save properties of the physics object
	local Min, Max = PhysObj:GetAABB()
	Data = {
		Mesh   = ModelData.GetMultiConvex(PhysObj),
		Volume = PhysObj:GetVolume(),
		Center = (Min + Max) * 0.5,
		Size   = Max - Min
	}
	timer.Simple(0, function() if IsValid(EntTest) then EntTest:Remove() end end)

	Models[Path] = Data -- Cache the data for future use

	return Data
end