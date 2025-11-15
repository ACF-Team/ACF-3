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

function ModelData.SanitizeMesh(PhysObj)
	local Mesh = PhysObj:GetMeshConvexes()

	for I, Hull in ipairs(Mesh) do
		for J, Vertex in ipairs(Hull) do
			Mesh[I][J] = Vertex.pos
		end
	end

	return Mesh
end

do -- BVH
	-- Adds BVH spatial partitioning for ray intersection. Way, way faster than iterating over all triangles for complex models.
	-- This collects vertices into a list of triangles and then builds a tree of AABBs (Nodes) that covers them.
	-- Some of this is very verbose and ugly scalar math, but that's because it's faster than using vectors/tables/dot products.

	-- Node: AABB surrounding a set of triangles. May have 0 or 2 children.
	-- Leaf: Node with no children (triangle count <= LeafSize)

	local Huge   = math.huge
	local Unpack = FindMetaTable("Vector").Unpack

	do -- BVH Building
		-- This is Bounding Volume Hierarchy (BVH) using Surface Area Heuristic (SAH) splitting
		-- "This cost model assumes that the probability of a ray intersecting a child node is
		--  proportional to the ratio of the child's surface area to the parent's surface area."
		local LeafSize     = 64 -- Max triangles in a node. Most important dial. This can affect performance during intersection tests
		local SplitSamples = 8 -- Tune this to increase or decrease the number of splits tested per axis. Affects build time.

		-- Compute surface area of an AABB (used for split cost)
		local function SurfaceArea(MinX, MinY, MinZ, MaxX, MaxY, MaxZ)
			if MaxX <= MinX or MaxY <= MinY or MaxZ <= MinZ then
				return 0
			end

			local ExtentX = MaxX - MinX
			local ExtentY = MaxY - MinY
			local ExtentZ = MaxZ - MinZ

			return 2 * (ExtentX * ExtentY + ExtentX * ExtentZ + ExtentY * ExtentZ)
		end

		-- Evaluate a candidate split axis using SAH heuristic
		-- This adds some overhead up front but speeds up ray intersection by having smarter partitioning
		local function EvaluateAxis(Tris, First, Last, Axis, CMin, CMax)
			local AxisExtent = CMax - CMin
			if AxisExtent <= 0 then return end

			local BestCost = Huge
			local BestSplit

			for S = 1, SplitSamples do -- sample potential split positions along the axis
				local Fraction = S / (SplitSamples + 1)
				local Split = CMin + AxisExtent * Fraction

				local LMinX, LMinY, LMinZ = Huge, Huge, Huge
				local LMaxX, LMaxY, LMaxZ = -Huge, -Huge, -Huge
				local RMinX, RMinY, RMinZ = Huge, Huge, Huge
				local RMaxX, RMaxY, RMaxZ = -Huge, -Huge, -Huge
				local LCount, RCount = 0, 0

				-- classify triangles to left/right of this split and grow their bounds
				for I = First, Last do
					local Tri = Tris[I]
					local Cx, Cy, Cz = Tri.cx, Tri.cy, Tri.cz
					local V = Axis == 1 and Cx or Axis == 2 and Cy or Cz

					local V1x, V1y, V1z = Tri.v1x, Tri.v1y, Tri.v1z
					local V2x = V1x + Tri.e1x
					local V2y = V1y + Tri.e1y
					local V2z = V1z + Tri.e1z
					local V3x = V1x + Tri.e2x
					local V3y = V1y + Tri.e2y
					local V3z = V1z + Tri.e2z

					if V < Split then
						LCount = LCount + 1

						if V1x < LMinX then LMinX = V1x end
						if V1y < LMinY then LMinY = V1y end
						if V1z < LMinZ then LMinZ = V1z end
						if V2x < LMinX then LMinX = V2x end
						if V2y < LMinY then LMinY = V2y end
						if V2z < LMinZ then LMinZ = V2z end
						if V3x < LMinX then LMinX = V3x end
						if V3y < LMinY then LMinY = V3y end
						if V3z < LMinZ then LMinZ = V3z end

						if V1x > LMaxX then LMaxX = V1x end
						if V1y > LMaxY then LMaxY = V1y end
						if V1z > LMaxZ then LMaxZ = V1z end
						if V2x > LMaxX then LMaxX = V2x end
						if V2y > LMaxY then LMaxY = V2y end
						if V2z > LMaxZ then LMaxZ = V2z end
						if V3x > LMaxX then LMaxX = V3x end
						if V3y > LMaxY then LMaxY = V3y end
						if V3z > LMaxZ then LMaxZ = V3z end
					else
						RCount = RCount + 1

						if V1x < RMinX then RMinX = V1x end
						if V1y < RMinY then RMinY = V1y end
						if V1z < RMinZ then RMinZ = V1z end
						if V2x < RMinX then RMinX = V2x end
						if V2y < RMinY then RMinY = V2y end
						if V2z < RMinZ then RMinZ = V2z end
						if V3x < RMinX then RMinX = V3x end
						if V3y < RMinY then RMinY = V3y end
						if V3z < RMinZ then RMinZ = V3z end

						if V1x > RMaxX then RMaxX = V1x end
						if V1y > RMaxY then RMaxY = V1y end
						if V1z > RMaxZ then RMaxZ = V1z end
						if V2x > RMaxX then RMaxX = V2x end
						if V2y > RMaxY then RMaxY = V2y end
						if V2z > RMaxZ then RMaxZ = V2z end
						if V3x > RMaxX then RMaxX = V3x end
						if V3y > RMaxY then RMaxY = V3y end
						if V3z > RMaxZ then RMaxZ = V3z end
					end
				end

				if LCount > 0 and RCount > 0 then -- ignore splits that put all tris on one side
					local LArea = SurfaceArea(LMinX, LMinY, LMinZ, LMaxX, LMaxY, LMaxZ)
					local RArea = SurfaceArea(RMinX, RMinY, RMinZ, RMaxX, RMaxY, RMaxZ)
					local Cost = LArea * LCount + RArea * RCount

					if Cost < BestCost then
						BestCost  = Cost
						BestSplit = Split
					end
				end
			end

			if not BestSplit then return end

			return BestCost, BestSplit
		end

		-- Build a BVH node for the given triangle range [First, Last]
		local function BuildNode(Nodes, Tris, First, Last)
			local NodeIndex = #Nodes + 1
			local Node = {
				First = First,
				Last  = Last,
				Count = Last - First + 1, -- inclusive indexing so +1
			}

			Nodes[NodeIndex] = Node

			local MinX, MinY, MinZ = Huge, Huge, Huge
			local MaxX, MaxY, MaxZ = -Huge, -Huge, -Huge

			-- Build an AABB that covers all triangles in this node
			for I = First, Last do
				local Tri = Tris[I]

				local V1x, V1y, V1z = Tri.v1x, Tri.v1y, Tri.v1z
				local V2x = V1x + Tri.e1x
				local V2y = V1y + Tri.e1y
				local V2z = V1z + Tri.e1z
				local V3x = V1x + Tri.e2x
				local V3y = V1y + Tri.e2y
				local V3z = V1z + Tri.e2z

				if V1x < MinX then MinX = V1x end
				if V1y < MinY then MinY = V1y end
				if V1z < MinZ then MinZ = V1z end
				if V2x < MinX then MinX = V2x end
				if V2y < MinY then MinY = V2y end
				if V2z < MinZ then MinZ = V2z end
				if V3x < MinX then MinX = V3x end
				if V3y < MinY then MinY = V3y end
				if V3z < MinZ then MinZ = V3z end

				if V1x > MaxX then MaxX = V1x end
				if V1y > MaxY then MaxY = V1y end
				if V1z > MaxZ then MaxZ = V1z end
				if V2x > MaxX then MaxX = V2x end
				if V2y > MaxY then MaxY = V2y end
				if V2z > MaxZ then MaxZ = V2z end
				if V3x > MaxX then MaxX = V3x end
				if V3y > MaxY then MaxY = V3y end
				if V3z > MaxZ then MaxZ = V3z end
			end

			Node.minx, Node.miny, Node.minz = MinX, MinY, MinZ -- Scalars, not vectors
			Node.maxx, Node.maxy, Node.maxz = MaxX, MaxY, MaxZ

			if Node.Count <= LeafSize then -- Leaf node
				return NodeIndex
			else -- Internal node
				-- Compute bounds of triangle centroids (used to pick split axis)
				local CMinX, CMinY, CMinZ = Huge, Huge, Huge
				local CMaxX, CMaxY, CMaxZ = -Huge, -Huge, -Huge

				for I = First, Last do
					local Tri = Tris[I]
					local Cx, Cy, Cz = Tri.cx, Tri.cy, Tri.cz

					if Cx < CMinX then CMinX = Cx end
					if Cy < CMinY then CMinY = Cy end
					if Cz < CMinZ then CMinZ = Cz end
					if Cx > CMaxX then CMaxX = Cx end
					if Cy > CMaxY then CMaxY = Cy end
					if Cz > CMaxZ then CMaxZ = Cz end
				end

				local ExtentX = CMaxX - CMinX
				local ExtentY = CMaxY - CMinY
				local ExtentZ = CMaxZ - CMinZ

				-- If the triangle centroids are all in the same spot, make this a leaf
				-- This can happen if we have a bunch of triangles stacked on top of each other (shit modeling)
				if ExtentX <= 0 and ExtentY <= 0 and ExtentZ <= 0 then
					return NodeIndex
				end

				-- Go through all 3 axis and split them into chunks to test for the best split
				local BestAxis, BestSplit
				local BestCost = Huge

				local Cost, Split

				Cost, Split = EvaluateAxis(Tris, First, Last, 1, CMinX, CMaxX)
				if Cost and Cost < BestCost then
					BestCost  = Cost
					BestAxis  = 1
					BestSplit = Split
				end

				Cost, Split = EvaluateAxis(Tris, First, Last, 2, CMinY, CMaxY)
				if Cost and Cost < BestCost then
					BestCost  = Cost
					BestAxis  = 2
					BestSplit = Split
				end

				Cost, Split = EvaluateAxis(Tris, First, Last, 3, CMinZ, CMaxZ)
				if Cost and Cost < BestCost then
					BestCost  = Cost
					BestAxis  = 3
					BestSplit = Split
				end

				if not BestAxis then
					return NodeIndex
				end

				local Axis  = BestAxis
				local Split = BestSplit
				local I, J  = First, Last

				-- Partition the triangles into two sets using the best axis and split
				-- This will be our new left and right nodes
				while I <= J do
					local TriI = Tris[I]
					local TriJ = Tris[J]
					local VI = Axis == 1 and TriI.cx or Axis == 2 and TriI.cy or TriI.cz
					local VJ = Axis == 1 and TriJ.cx or Axis == 2 and TriJ.cy or TriJ.cz

					if VI < Split then
						I = I + 1
					elseif VJ >= Split then
						J = J - 1
					else
						Tris[I], Tris[J] = TriJ, TriI
						I = I + 1
						J = J - 1
					end
				end

				local Mid = I - 1

				if Mid <= First or Mid >= Last then
					Mid = math.floor((First + Last) * 0.5)
				end

				Node.Left  = BuildNode(Nodes, Tris, First, Mid)
				Node.Right = BuildNode(Nodes, Tris, Mid + 1, Last)

				return NodeIndex
			end
		end

		function ModelData.BuildBVH(Mesh)
			if not Mesh then return end

			local Tris  = {}
			local Nodes = {}

			local Count = 0

			-- Flatten the mesh into a list of triangles
			for _, Hull in ipairs(Mesh) do
				local HC = #Hull

				for I = 1, HC, 3 do
					local A, B, C = Hull[I], Hull[I + 1], Hull[I + 2]

					if C then -- Make sure we have complete triangles
						local Ax, Ay, Az = Unpack(A)
						local Bx, By, Bz = Unpack(B)
						local Cx, Cy, Cz = Unpack(C)

						-- Edges
						local E1x = Bx - Ax
						local E1y = By - Ay
						local E1z = Bz - Az
						local E2x = Cx - Ax
						local E2y = Cy - Ay
						local E2z = Cz - Az

						-- Normal
						local Nx = E2y * E1z - E2z * E1y
						local Ny = E2z * E1x - E2x * E1z
						local Nz = E2x * E1y - E2y * E1x
						local LenSq = Nx * Nx + Ny * Ny + Nz * Nz

						if LenSq > 0 then
							local InvLen = 1 / math.sqrt(LenSq)
							Nx = Nx * InvLen
							Ny = Ny * InvLen
							Nz = Nz * InvLen
						else
							Nx, Ny, Nz = 0, 0, 1
						end

						-- Center
						local CxCent = (Ax + Bx + Cx) / 3
						local CyCent = (Ay + By + Cy) / 3
						local CzCent = (Az + Bz + Cz) / 3

						Count = Count + 1
						Tris[Count] = {
							v1x = Ax, v1y = Ay, v1z = Az,          -- Vertices
							e1x = E1x, e1y = E1y, e1z = E1z,       -- Edges
							e2x = E2x, e2y = E2y, e2z = E2z,       -- Edges
							nx = Nx,  ny = Ny,  nz = Nz,           -- Normal
							cx = CxCent, cy = CyCent, cz = CzCent, -- Center
						}
					end
				end
			end

			if Count == 0 then return end

			-- Build the BVH tree
			BuildNode(Nodes, Tris, 1, Count)

			return {
				Nodes = Nodes,
				Tris  = Tris,
			}
		end
	end

	do -- BVH ray intersection
		local function HitLess(A, B)
			return A.Distance < B.Distance
		end

		local function GetEntityBVH(Entity)
			if not IsValid(Entity) then return end

			if Entity.ACF_BVH then return Entity.ACF_BVH end

			local Model = Entity:GetModel()

			if not Model then return end

			local Data = ModelData.GetModelData(Model)

			if not Data then return end

			return Data.BVH
		end

		-- Ray/AABB intersection
		local function RayAABB(Ox, Oy, Oz, InvX, InvY, InvZ, Node, Limit)
			local MinX, MinY, MinZ = Node.minx, Node.miny, Node.minz -- Vector Unpack doesn't apply here: Note these are scalars, not vectors
			local MaxX, MaxY, MaxZ = Node.maxx, Node.maxy, Node.maxz

			local tx1 = (MinX - Ox) * InvX
			local tx2 = (MaxX - Ox) * InvX
			local tmin = tx1 < tx2 and tx1 or tx2
			local tmax = tx1 > tx2 and tx1 or tx2

			local ty1 = (MinY - Oy) * InvY
			local ty2 = (MaxY - Oy) * InvY
			local tymin = ty1 < ty2 and ty1 or ty2
			local tymax = ty1 > ty2 and ty1 or ty2
			if tymin > tmin then tmin = tymin end
			if tymax < tmax then tmax = tymax end

			local tz1 = (MinZ - Oz) * InvZ
			local tz2 = (MaxZ - Oz) * InvZ
			local tzmin = tz1 < tz2 and tz1 or tz2
			local tzmax = tz1 > tz2 and tz1 or tz2
			if tzmin > tmin then tmin = tzmin end
			if tzmax < tmax then tmax = tzmax end

			if tmax < (tmin > 0 and tmin or 0) then
				return false
			end

			if tmin > Limit then
				return false
			end

			return true
		end

		-- Ray/triangle intersection
		local Epsilon = 0.0001

		local function RayTriangle(Ox, Oy, Oz, Dx, Dy, Dz, Tri)
			local E1x, E1y, E1z = Tri.e1x, Tri.e1y, Tri.e1z
			local E2x, E2y, E2z = Tri.e2x, Tri.e2y, Tri.e2z

			-- H = D x E2
			local Hx = Dy * E2z - Dz * E2y
			local Hy = Dz * E2x - Dx * E2z
			local Hz = Dx * E2y - Dy * E2x

			local A = E1x * Hx + E1y * Hy + E1z * Hz

			if A > -Epsilon and A < Epsilon then return end

			local F = 1 / A

			local V1x, V1y, V1z = Tri.v1x, Tri.v1y, Tri.v1z
			local Sx = Ox - V1x
			local Sy = Oy - V1y
			local Sz = Oz - V1z

			local U = F * (Sx * Hx + Sy * Hy + Sz * Hz)
			if U < 0 or U > 1 then return end

			-- Q = S x E1
			local Qx = Sy * E1z - Sz * E1y
			local Qy = Sz * E1x - Sx * E1z
			local Qz = Sx * E1y - Sy * E1x

			local V = F * (Dx * Qx + Dy * Qy + Dz * Qz)
			if V < 0 or U + V > 1 then return end

			local T = F * (E2x * Qx + E2y * Qy + E2z * Qz)

			if T > Epsilon then
				return T, Tri.nx, Tri.ny, Tri.nz
			end
		end

		local ANG_0  = Angle()
		local VEC_0  = Vector()

		--- Casts a ray against an entity's mesh using its BVH
		-- @param Entity Entity The entity to test against
		-- @param RayOrigin Vector World space ray origin
		-- @param RayDir Vector World space ray direction (does not need to be normalized)
		-- @param MaxDistance? number Optional maximum distance along the ray to consider
		-- @return table|nil Hits, integer HitCount A table of hits, each with HitPos, HitNormal, Distance, sorted by Distance
		function ModelData.RayIntersectEntity(Entity, RayOrigin, RayDir, MaxDistance)
			if not IsValid(Entity) then return end
			if not isvector(RayOrigin) or not isvector(RayDir) then return end

			local BVH = GetEntityBVH(Entity)
			if not BVH then return end

			-- Transform the ray into entity-local space and normalize direction
			local DirWorld = RayDir:GetNormalized()
			local Limit    = MaxDistance or Huge

			local Ang = Entity:GetAngles()

			local Origin   = WorldToLocal(RayOrigin, ANG_0, Entity:GetPos(), Ang)
			local LocalDir = WorldToLocal(DirWorld, ANG_0, VEC_0, Ang)

			-- Unpacked, scalar components for faster math
			-- Used exclusively to translate hitPos and hitNormal back to world space
			local ROx, ROy, ROz = Unpack(RayOrigin) -- World space ray origin
			local DWx, DWy, DWz = Unpack(DirWorld)  -- World space ray direction
			local Ox, Oy, Oz    = Unpack(Origin)    -- Local space ray origin
			local Dx, Dy, Dz    = Unpack(LocalDir)  -- Local space ray direction
			local Fx, Fy, Fz    = Unpack(Ang:Forward())
			local Rx, Ry, Rz    = Unpack(Ang:Right())
			local Ux, Uy, Uz    = Unpack(Ang:Up())

			-- Precompute inverse direction for ray-AABB intersection
			local InvX = Dx ~= 0 and 1 / Dx or Huge
			local InvY = Dy ~= 0 and 1 / Dy or Huge
			local InvZ = Dz ~= 0 and 1 / Dz or Huge

			-- Set up traversal data: nodes, triangles, stack, and hit accumulator
			local Nodes = BVH.Nodes
			local Tris  = BVH.Tris

			local Stack = {[1] = 1} -- LIFO stack of node indices
			local Top   = 1 -- As in the 'top' of the stack (stack count)

			local Hits     = {}
			local HitCount = 0

			-- Traverse the BVH
			while Top > 0 do
				-- Grab the node on the top of the stack
				local Index = Stack[Top]

				Top = Top - 1

				local Node = Nodes[Index]

				-- Check if the ray intersects this node's AABB
				local RayIntersectsNode = RayAABB(Ox, Oy, Oz, InvX, InvY, InvZ, Node, Limit)

				if RayIntersectsNode then
					if Node.Left then -- This node has children: Add them to the stack
						Top = Top + 1
						Stack[Top] = Node.Left

						Top = Top + 1
						Stack[Top] = Node.Right
					else -- Leaf node: Check for hits
						local First = Node.First
						local Last  = First + Node.Count - 1

						-- Check each triangle in this leaf for ray hits
						for I = First, Last do
							local Dist, Nx, Ny, Nz = RayTriangle(Ox, Oy, Oz, Dx, Dy, Dz, Tris[I])

							if Dist and Dist <= Limit then
								HitCount = HitCount + 1

								local HitPosX = ROx + DWx * Dist
								local HitPosY = ROy + DWy * Dist
								local HitPosZ = ROz + DWz * Dist
								local HitPos = Vector(HitPosX, HitPosY, HitPosZ)

								local HitNormalX = Fx * Nx + Rx * Ny + Ux * Nz
								local HitNormalY = Fy * Nx + Ry * Ny + Uy * Nz
								local HitNormalZ = Fz * Nx + Rz * Ny + Uz * Nz
								local HitNormal = Vector(HitNormalX, HitNormalY, HitNormalZ)

								Hits[HitCount] = {
									HitPos    = HitPos,
									HitNormal = HitNormal,
									Distance  = Dist,
								}
							end
						end
					end
				end
			end

			if HitCount == 0 then return nil, 0 end

			table.sort(Hits, HitLess) -- Sort hits from nearest to farthest

			return Hits, HitCount
		end


		if SERVER then
			concommand.Add("acf_bvh_eyetrace", function(ply, _, args)
				if not IsValid(ply) then return end

				local trace    = ply:GetEyeTrace()
				local ent      = trace.Entity
				local duration = tonumber(args[1]) or 15

				if not IsValid(ent) then return end

				local startPos = trace.StartPos or ply:EyePos()
				local hitPos   = trace.HitPos or (startPos + trace.Normal * 32768)
				local dir      = (hitPos - startPos):GetNormalized()

				debugoverlay.Line(startPos, hitPos, 15, Color(0, 0, 255), true)

				local hits, hitCount = ModelData.RayIntersectEntity(ent, startPos, dir)
				if not hits then
					print("no hits")
					return
				end

				for i = 1, hitCount do
					local hit    = hits[i]
					local pos    = hit.HitPos
					local normal = hit.HitNormal

					debugoverlay.Cross(pos, 2, duration, Color(255, 0, 0), true)
					debugoverlay.Line(pos, pos + normal * 16, duration, Color(0, 255, 0), true)
				end
			end)
		end
	end

	do -- PhysicsInitConvex / PhysicsInitMultiConvex detours
		-- These build and attach per-entity BVHs that override model-based BVHs

		function ModelData.SanitizeConvexMesh(Mesh)
			if not Mesh then return end

			local Result = {}

			for I, Hull in ipairs(Mesh) do
				local Current = {}

				for J, Vertex in ipairs(Hull) do
					if isvector(Vertex) then
						Current[J] = Vertex
					elseif Vertex.pos then
						Current[J] = Vertex.pos
					end
				end

				Result[I] = Current
			end

			return Result
		end

		hook.Add("ACF_OnLoadAddon", "ACF_ModelData_BVHDetours", function()
			local Detours = ACF and ACF.Detours

			local PhysInitConvex_Orig = Detours.Metatable("Entity", "PhysicsInitConvex", function(self, Mesh, ...)
				if Mesh and istable(Mesh) then
					local Convexes  = { Mesh }
					local Sanitized = ModelData.SanitizeConvexMesh(Convexes)

					if Sanitized then
						self.ACF_BVH = ModelData.BuildBVH(Sanitized)

						if self.ACF_BVH then
							self:CallOnRemove("ACF_BVH_Cleanup", function(Ent)
								Ent.ACF_BVH = nil
							end)
						end
					end
				else
					self.ACF_BVH = nil
				end

				return PhysInitConvex_Orig(self, Mesh, ...)
			end)

			local PhysInitMultiConvex_Orig = Detours.Metatable("Entity", "PhysicsInitMultiConvex", function(self, Meshes, ...)
				if Meshes and istable(Meshes) then
					local Sanitized = ModelData.SanitizeConvexMesh(Meshes)

					if Sanitized then
						self.ACF_BVH = ModelData.BuildBVH(Sanitized)

						if self.ACF_BVH then
							self:CallOnRemove("ACF_BVH_Cleanup", function(Ent)
								Ent.ACF_BVH = nil
							end)
						end
					end
				else
					self.ACF_BVH = nil
				end

				return PhysInitMultiConvex_Orig(self, Meshes, ...)
			end)
		end)
	end
end

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
