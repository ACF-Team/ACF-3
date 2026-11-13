local Damaged   = {} -- Damaged[Entity] = { Steps = { [ConvexID] = Step }, Root = Entity }
local Groups    = {} -- Groups[Root] = { Members = { [Entity] = true }, Meshes = { [MaterialIndex] = { IMesh, ... } }, Dirty = bool }
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
local render_SetMaterial = render.SetMaterial
local cam_PushModelMatrix = cam.PushModelMatrix
local cam_PopModelMatrix  = cam.PopModelMatrix

local MaxTris       = 10000 -- per IMesh
local CheckInterval = 0.5
local NextCheck     = 0
local DrawMatrix    = Matrix()

local function GetMaterialIndex(Percent)
	if Percent > 0.7 then return 1 end
	if Percent > 0.3 then return 2 end
	if Percent > 0   then return 3 end

	return 4
end

-- StepLooks[Step] = { MaterialIndex, Alpha }
local StepLooks = {}

for Step = 0, 9 do
	local Percent = Step * 0.1

	StepLooks[Step] = { GetMaterialIndex(Percent), math.Clamp(1 - Percent, 0, 0.8) * 255 }
end

local function DestroyMeshes(Group)
	for _, List in pairs(Group.Meshes) do
		for I = 1, #List do
			List[I]:Destroy()
		end
	end

	Group.Meshes = {}
end

local function GetRoot(Entity, Data)
	if Data.Loose then return Entity end

	local Parent = Entity:GetParent()

	return IsValid(Parent) and Parent or Entity
end

local function LeaveGroup(Entity, Data)
	local Root  = Data.Root
	local Group = Groups[Root]

	Data.Root = nil

	if not Group then return end

	Group.Members[Entity] = nil
	Group.Dirty = true

	if not next(Group.Members) then
		DestroyMeshes(Group)

		Groups[Root] = nil
	end
end

local function JoinGroup(Entity, Data)
	local Root  = GetRoot(Entity, Data)
	local Group = Groups[Root]

	if not Group then
		Group = { Members = {}, Meshes = {}, Dirty = true }
		Groups[Root] = Group
	end

	Group.Members[Entity] = true
	Group.Dirty = true

	Data.Root = Root
end

local function Remove(Entity)
	local Data = Damaged[Entity]
	if not Data then return end

	if IsValid(Entity) then
		Entity:RemoveCallOnRemove("ACF_RenderDamage")
	end

	LeaveGroup(Entity, Data)

	Damaged[Entity] = nil

	if not next(Damaged) then
		hook.Remove("PostDrawOpaqueRenderables", "ACF_RenderDamage")
	end
end

local function RemoveConvex(Entity, ConvexID)
	local Data = Damaged[Entity]
	if not Data then return end

	Data.Steps[ConvexID] = nil

	if not next(Data.Steps) then
		Remove(Entity)
	else
		Groups[Data.Root].Dirty = true
	end
end

-- Collects the triangles of every damaged convex in the group, in the root's local space
local function CollectTris(Root, Group)
	local Buckets = {} -- [MaterialIndex] = { A, B, C, Normal, Alpha, ... }

	for Entity in pairs(Group.Members) do
		local Data     = Damaged[Entity]
		local MeshData = Entity.ACF_Volumetric_Mesh

		Data.MeshData = MeshData

		local Transform

		if Entity ~= Root then
			Data.LocalPos = Entity:GetLocalPos()
			Data.LocalAng = Entity:GetLocalAngles()

			Transform = Matrix()
			Transform:SetTranslation(Data.LocalPos)
			Transform:SetAngles(Data.LocalAng)
		end

		if not MeshData then continue end

		for ConvexID, Step in pairs(Data.Steps) do
			local Convex = MeshData.Convexes[ConvexID]
			if not Convex then continue end

			local Look     = StepLooks[Step]
			local Alpha    = Look[2]
			local Centroid = Convex.Centroid
			local Bucket   = Buckets[Look[1]]

			if not Bucket then
				Bucket = {}
				Buckets[Look[1]] = Bucket
			end

			local Count = #Bucket

			for _, Tri in ipairs(Convex.Tris) do
				local A, B, C = Tri[1], Tri[2], Tri[3]
				local Normal  = (B - A):Cross(C - A)

				Normal:Normalize()

				-- winding isnt guaranteed to face outwards, and front faces are clockwise
				if Normal:Dot(A - Centroid) < 0 then
					Normal = -Normal
				else
					B, C = C, B
				end

				-- Push the triangle 0.1 units along its outward normal to avoid z-fighting with the model surface
				local Offset = Normal * 0.1

				A, B, C = A + Offset, B + Offset, C + Offset

				if Transform then
					A, B, C = Transform * A, Transform * B, Transform * C

					Normal:Rotate(Data.LocalAng)
				end

				Bucket[Count + 1] = A
				Bucket[Count + 2] = B
				Bucket[Count + 3] = C
				Bucket[Count + 4] = Normal
				Bucket[Count + 5] = Alpha

				Count = Count + 5
			end
		end
	end

	return Buckets
end

local function Rebuild(Root, Group)
	DestroyMeshes(Group)

	Group.Dirty = false

	for Index, Bucket in pairs(CollectTris(Root, Group)) do
		local Material = Materials[Index]
		local Total    = #Bucket / 5
		local List     = {}

		for First = 0, Total - 1, MaxTris do
			local Amount = math.min(MaxTris, Total - First)
			local IMesh  = Mesh(Material)

			mesh.Begin(IMesh, MATERIAL_TRIANGLES, Amount)

			for I = First * 5, (First + Amount - 1) * 5, 5 do
				local Normal = Bucket[I + 4]
				local Alpha  = Bucket[I + 5]

				mesh.Position(Bucket[I + 1])
				mesh.Normal(Normal)
				mesh.TexCoord(0, 0, 0)
				mesh.Color(255, 255, 255, Alpha)
				mesh.AdvanceVertex()

				mesh.Position(Bucket[I + 2])
				mesh.Normal(Normal)
				mesh.TexCoord(0, 1, 0)
				mesh.Color(255, 255, 255, Alpha)
				mesh.AdvanceVertex()

				mesh.Position(Bucket[I + 3])
				mesh.Normal(Normal)
				mesh.TexCoord(0, 1, 1)
				mesh.Color(255, 255, 255, Alpha)
				mesh.AdvanceVertex()
			end

			mesh.End()

			List[#List + 1] = IMesh
		end

		Group.Meshes[Index] = List
	end
end

-- Nothing tells the client about reparenting or a recomputed mesh, so look for it
local function CheckGroups()
	for Entity, Data in pairs(Damaged) do
		if not IsValid(Entity) then
			Remove(Entity)
			continue
		end

		local Root = Data.Root

		if GetRoot(Entity, Data) ~= Root then
			LeaveGroup(Entity, Data)
			JoinGroup(Entity, Data)
			continue
		end

		local Group = Groups[Root]
		if Group.Dirty then continue end

		if Data.MeshData ~= Entity.ACF_Volumetric_Mesh then
			Group.Dirty = true
		elseif Entity ~= Root and (Data.LocalPos ~= Entity:GetLocalPos() or Data.LocalAng ~= Entity:GetLocalAngles()) then
			-- moves around inside its parent, cant share a mesh with it
			Data.Loose = true

			LeaveGroup(Entity, Data)
			JoinGroup(Entity, Data)
		end
	end
end

local function RenderDamage(bDrawingDepth, _, isDraw3DSkybox)
	if bDrawingDepth or isDraw3DSkybox then return end

	local Now = RealTime()

	if Now >= NextCheck then
		NextCheck = Now + CheckInterval

		CheckGroups()
	end

	render.SetColorMaterial() -- Stops flashing

	for Root, Group in pairs(Groups) do
		if not IsValid(Root) or Root:IsDormant() then continue end
		if Group.Dirty then Rebuild(Root, Group) end

		-- SetAngles keeps the old scale and it drifts when the matrix is reused
		DrawMatrix:Identity()
		DrawMatrix:SetTranslation(Root:GetPos())
		DrawMatrix:SetAngles(Root:GetAngles())

		cam_PushModelMatrix(DrawMatrix)

		for Index, List in pairs(Group.Meshes) do
			render_SetMaterial(Materials[Index])

			for I = 1, #List do
				List[I]:Draw()
			end
		end

		cam_PopModelMatrix()
	end
end

local function Add(Entity, ConvexID, Step)
	local Data = Damaged[Entity]

	if not Data then -- First time this entity has been damaged; register it
		if not next(Damaged) then -- First damaged entity overall; start rendering
			hook.Add("PostDrawOpaqueRenderables", "ACF_RenderDamage", RenderDamage)
		end

		Data = { Steps = {} }
		Damaged[Entity] = Data

		JoinGroup(Entity, Data)

		Entity:CallOnRemove("ACF_RenderDamage", function()
			Remove(Entity)
		end)
	end

	Data.Steps[ConvexID] = Step

	Groups[Data.Root].Dirty = true
end

net.Receive("ACF_Damage", function()
	local EntityCount = net.ReadUInt(MAX_EDICT_BITS)

	for _ = 1, EntityCount do
		local Entity      = Entity(net.ReadUInt(13))
		local ConvexCount = net.ReadUInt(12)

		for _ = 1, ConvexCount do
			local ConvexID = net.ReadUInt(12)
			local Step      = net.ReadUInt(4)

			if IsValid(Entity) then
				if Step < 10 then
					Add(Entity, ConvexID, Step)
				else
					RemoveConvex(Entity, ConvexID)
				end
			end
		end
	end
end)
