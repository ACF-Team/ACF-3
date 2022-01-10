local ACF       = ACF
local ModelData = ACF.ModelData
local isnumber  = isnumber
local isvector  = isvector
local isstring  = isstring
local IsUseless = IsUselessModel

local function IsValidScale(Scale)
	if not Scale then return false end

	return isnumber(Scale) or isvector(Scale)
end

local function CopyMesh(Mesh, Scale)
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

local function GetVolume(Mesh)
	local Entity = ModelData.Entity

	Entity:PhysicsInitMultiConvex(Mesh)

	local PhysObj = Entity:GetPhysicsObject()

	return PhysObj:GetVolume()
end

-------------------------------------------------------------------

function ModelData.GetModelPath(Model)
	if not isstring(Model) then return end
	if IsUseless(Model) then return end

	return Model:Trim():lower()
end

function ModelData.GetModelMesh(Model, Scale)
	local Data = ModelData.GetModelData(Model)

	if not Data then return end
	if not IsValidScale(Scale) then Scale = 1 end

	return CopyMesh(Data.Mesh, Scale)
end

function ModelData.GetModelVolume(Model, Scale)
	local Data = ModelData.GetModelData(Model)

	if not Data then return end
	if not IsValidScale(Scale) then
		return Data.Volume
	end

	local Mesh = CopyMesh(Data.Mesh, Scale)

	return GetVolume(Mesh)
end

function ModelData.GetModelCenter(Model, Scale)
	local Data = ModelData.GetModelData(Model)

	if not Data then return end
	if not IsValidScale(Scale) then Scale = 1 end

	return Data.Center * Scale
end

function ModelData.GetModelSize(Model, Scale)
	local Data = ModelData.GetModelData(Model)

	if not Data then return end
	if not IsValidScale(Scale) then Scale = 1 end

	return Data.Size * Scale
end
