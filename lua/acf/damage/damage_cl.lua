local Damaged   = {} -- Damaged[Entity] = { Convexes = { [ConvexID] = Percent }, Meshes = { { Mesh = IMesh, Material = IMaterial, Alpha = number } } }
local Materials = {
	CreateMaterial("ACF_Damaged1", "VertexLitGeneric", {
		["$basetexture"] = "damaged/damaged1"
	}),
	CreateMaterial("ACF_Damaged2", "VertexLitGeneric", {
		["$basetexture"] = "damaged/damaged2"
	}),
	CreateMaterial("ACF_Damaged3", "VertexLitGeneric", {
		["$basetexture"] = "damaged/damaged3"
	}),
	CreateMaterial("ACF_Damaged4", "VertexLitGeneric", {
		["$basetexture"] = "models/props_wasteland/metal_tram001a",
		["$color2"]     = "255 255 255",
		["$blendmodulatortexture"] = "damaged/damaged4"
	}),
}

local IsValid             = IsValid
local render_SetMaterial  = render.SetMaterial
local render_SetBlend     = render.SetBlend
local cam_PushModelMatrix = cam.PushModelMatrix
local cam_PopModelMatrix  = cam.PopModelMatrix

local function GetMaterial(Percent)
	if Percent > 0.7 then return Materials[1] end
	if Percent > 0.3 then return Materials[2] end
	if Percent > 0   then return Materials[3] end

	return Materials[4]
end

local function DestroyMeshes(Data)
	if not Data.Meshes then return end

	for _, Group in ipairs(Data.Meshes) do
		if Group.Mesh:IsValid() then Group.Mesh:Destroy() end
	end

	Data.Meshes = nil
end

local function Remove(Entity)
	Entity:RemoveCallOnRemove("ACF_RenderDamage")

	local Data = Damaged[Entity]
	if Data then DestroyMeshes(Data) end

	Damaged[Entity] = nil

	if not next(Damaged) then
		hook.Remove("PostDrawOpaqueRenderables", "ACF_RenderDamage")
	end
end

local function RemoveConvex(Entity, ConvexID)
	local Data = Damaged[Entity]
	if not Data then return end

	Data.Convexes[ConvexID] = nil

	DestroyMeshes(Data) -- Damage changed, the baked meshes no longer match

	if not next(Data.Convexes) then
		Remove(Entity)
	end
end

-- Bakes every damaged convex into one mesh per damage level, in the entity's local space.
-- Convexes sharing a level share a material and an alpha, so each level is a single draw call.
local function BuildMeshes(Entity, Data)
	local MeshData = Entity.ACF_Volumetric_Mesh
	if not MeshData then return end

	local Levels = {}

	for ConvexID, Percent in pairs(Data.Convexes) do
		local Convex = MeshData.Convexes[ConvexID]
		if not Convex then continue end

		local Vertices = Levels[Percent]

		if not Vertices then
			Vertices = {}
			Levels[Percent] = Vertices
		end

		for _, Tri in ipairs(Convex.Tris) do
			local A, B, C = Tri[1], Tri[2], Tri[3]

			-- Triangles wind so this points out of the convex, which is also the front face for the renderer
			local Normal = (C - A):Cross(B - A):GetNormalized()

			-- Push the triangle 0.1 units along its outward normal to avoid z-fighting with the model surface
			local Offset = Normal * 0.1

			Vertices[#Vertices + 1] = { pos = A + Offset, normal = Normal, u = 0, v = 0 }
			Vertices[#Vertices + 1] = { pos = B + Offset, normal = Normal, u = 1, v = 0 }
			Vertices[#Vertices + 1] = { pos = C + Offset, normal = Normal, u = 1, v = 1 }
		end
	end

	local Meshes = {}

	for Percent, Vertices in pairs(Levels) do
		local Baked = Mesh()

		Baked:BuildFromTriangles(Vertices)

		Meshes[#Meshes + 1] = {
			Mesh     = Baked,
			Material = GetMaterial(Percent),
			Alpha    = math.Clamp(1 - Percent, 0, 0.8),
		}
	end

	Data.Meshes = Meshes
	Data.Source = MeshData -- Rebuild if the entity's convexes are recomputed underneath us

	return Meshes
end

local function RenderDamage(bDrawingDepth, _, isDraw3DSkybox)
	if bDrawingDepth or isDraw3DSkybox then return end

	for Entity, Data in pairs(Damaged) do
		if not IsValid(Entity) then
			Remove(Entity)
			continue
		end

		local Meshes = Data.Meshes

		if not Meshes or Data.Source ~= Entity.ACF_Volumetric_Mesh then
			DestroyMeshes(Data)

			Meshes = BuildMeshes(Entity, Data)
		end

		if not Meshes then continue end

		cam_PushModelMatrix(Entity:GetWorldTransformMatrix()) -- Meshes are baked in local space, so they follow the entity

		for _, Group in ipairs(Meshes) do
			render_SetMaterial(Group.Material)
			render_SetBlend(Group.Alpha)

			Group.Mesh:Draw()
		end

		render_SetBlend(1)
		cam_PopModelMatrix()
	end
end

local function Add(Entity, ConvexID, Percent)
	local Data = Damaged[Entity]

	if not Data then -- First time this entity has been damaged; register it
		if not next(Damaged) then -- First damaged entity overall; start rendering
			hook.Add("PostDrawOpaqueRenderables", "ACF_RenderDamage", RenderDamage)
		end

		Data = { Convexes = {} }
		Damaged[Entity] = Data

		Entity:CallOnRemove("ACF_RenderDamage", function()
			Remove(Entity)
		end)
	end

	-- Update render data (runs for both new and existing convexes)
	Data.Convexes[ConvexID] = Percent

	DestroyMeshes(Data) -- Damage changed, the baked meshes no longer match
end

net.Receive("ACF_Damage", function()
	local EntityCount = net.ReadUInt(8)

	for _ = 1, EntityCount do
		local Entity      = Entity(net.ReadUInt(13))
		local ConvexCount = net.ReadUInt(8)

		for _ = 1, ConvexCount do
			local ConvexID = net.ReadUInt(9)
			local Step      = net.ReadUInt(4)

			if IsValid(Entity) then
				if Step < 10 then
					Add(Entity, ConvexID, Step * 0.1)
				else
					RemoveConvex(Entity, ConvexID)
				end
			end
		end
	end
end)
