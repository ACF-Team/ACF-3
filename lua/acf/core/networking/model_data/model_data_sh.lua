--- Note: Mesh refers to https://wiki.facepunch.com/gmod/Structures/MeshVertex
local ACF       = ACF
ACF.ModelData = ACF.ModelData or {}
local ModelData = ACF.ModelData
local isstring  = isstring
local IsUseless = IsUselessModel

--- Returns a scaled copy of a mesh
local function CopyScaledMesh(Mesh, Scale)
	local Result = {}

	for I, Hull in ipairs(Mesh) do
		local Current = {}

		for J, Vertex in ipairs(Hull) do
			Current[J] = Vertex * Scale
		end

		Result[I] = Current
	end

	return Result
end

--- Returns the mesh of a physics object in the format PhysicsInitMultiConvex expects
function ModelData.GetMultiConvex(PhysObj)
	local Mesh = PhysObj:GetMeshConvexes()

	for I, Hull in ipairs(Mesh) do
		for J, Vertex in ipairs(Hull) do
			Mesh[I][J] = Vertex.pos
		end
	end

	return Mesh
end

--- TODO: SHOULD WE DO THIS?
--- Returns a nice scale vector from a number or vector, or nil if the input is invalid
function ModelData.GetNiceScale(Scale)
	if not Scale then return end
	if isnumber(Scale) then return Vector(Scale, Scale, Scale)
	elseif isvector(Scale) then return Scale end
end

-------------------------------------------------------------------

--- Returns the path of a model, or nil if the model is invalid
function ModelData.GetModelPath(Model)
	if not isstring(Model) then return end
	if IsUseless(Model) then return end

	return Model:Trim():lower()
end

--- Returns the mesh of a model after scaling
function ModelData.GetModelMesh(Model, Scale)
	local Data = ModelData.GetModelData(Model)

	Scale = ModelData.GetNiceScale(Scale)
	if not Data then return end
	if not Scale then return Data.Mesh end

	return CopyScaledMesh(Data.Mesh, Scale)
end

--- Returns the volume of a model after scaling
function ModelData.GetModelVolume(Model, Scale)
	local Data = ModelData.GetModelData(Model)

	Scale = ModelData.GetNiceScale(Scale)
	if not Data then return end
	if not Scale then return Data.Volume end

	return Data.Volume * math.abs(Scale.x * Scale.y * Scale.z)
end

--- Returns the center of a model after scaling
function ModelData.GetModelCenter(Model, Scale)
	local Data = ModelData.GetModelData(Model)

	Scale = ModelData.GetNiceScale(Scale)
	if not Data then return end
	if not Scale then return Data.Center end

	return Data.Center * Scale
end

--- Returns the size of a model after scaling
function ModelData.GetModelSize(Model, Scale)
	local Data = ModelData.GetModelData(Model)

	Scale = ModelData.GetNiceScale(Scale)
	if not Data then return end
	if not Scale then return Data.Size end

	return Data.Size * Scale
end