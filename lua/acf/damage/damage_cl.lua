local Damaged   = {} -- Damaged[Entity] = { [ConvexID] = { Material = IMaterial, Color = Color } }
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

local IsValid            = IsValid
local EyePos             = EyePos
local render_SetMaterial = render.SetMaterial
local render_DrawQuad    = render.DrawQuad

local function GetMaterial(Percent)
	if Percent > 0.7 then return Materials[1] end
	if Percent > 0.3 then return Materials[2] end
	if Percent > 0   then return Materials[3] end

	return Materials[4]
end

local function Remove(Entity)
	Entity:RemoveCallOnRemove("ACF_RenderDamage")

	Damaged[Entity] = nil

	if not next(Damaged) then
		hook.Remove("PostDrawOpaqueRenderables", "ACF_RenderDamage")
	end
end

local function RemoveConvex(Entity, ConvexID)
	local Convexes = Damaged[Entity]
	if not Convexes then return end

	Convexes[ConvexID] = nil

	if not next(Convexes) then
		Remove(Entity)
	end
end

local function RenderDamage(bDrawingDepth, _, isDraw3DSkybox)
	if bDrawingDepth or isDraw3DSkybox then return end

	local CameraPos = EyePos()

	for Entity, Convexes in pairs(Damaged) do
		if not IsValid(Entity) then
			Remove(Entity)
			continue
		end

		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then continue end

		render.SetColorMaterial() -- Stops flashing
		for ConvexID, Data in pairs(Convexes) do
			local Convex = MeshData.Convexes[ConvexID]
			if not Convex then continue end

			render_SetMaterial(Data.Material)

			for _, Tri in ipairs(Convex.Tris) do
				local A = Entity:LocalToWorld(Tri[1])
				local B = Entity:LocalToWorld(Tri[2])
				local C = Entity:LocalToWorld(Tri[3])

				-- Push the triangle 0.1 units along its outward normal to avoid z-fighting with the model surface
				local Normal = (B - A):Cross(C - A):GetNormalized()
				if Normal:Dot(A - CameraPos) > 0 then Normal = -Normal end
				Normal = Normal * 0.1

				render_DrawQuad(A + Normal, B + Normal, C + Normal, C + Normal, Data.Color)
			end
		end
	end
end

local function Add(Entity, ConvexID, Percent)
	local Convexes = Damaged[Entity]

	if not Convexes then -- First time this entity has been damaged; register it
		if not next(Damaged) then -- First damaged entity overall; start rendering
			hook.Add("PostDrawOpaqueRenderables", "ACF_RenderDamage", RenderDamage)
		end

		Convexes = {}
		Damaged[Entity] = Convexes

		Entity:CallOnRemove("ACF_RenderDamage", function()
			Remove(Entity)
		end)
	end

	-- Update render data (runs for both new and existing convexes)
	local Alpha = math.Clamp(1 - Percent, 0, 0.8) * 255

	Convexes[ConvexID] = {
		Material = GetMaterial(Percent),
		Color    = Color(255, 255, 255, Alpha),
	}
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
