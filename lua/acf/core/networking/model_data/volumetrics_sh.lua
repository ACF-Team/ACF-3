-- Classes we should compute the mesh for
local ArmorableClasses = {
    prop_physics = true,
    primitive_shape = true,
    primitive_staircase = true,
    primitive_ladder = true,
    primitive_rail_silder = true,
    primitive_airfoil = true,
}

if SERVER then
    function ProcessConvexes(Entity, Meshes)
        local MeshData = { Verts = {}, Convexes = {} }
        local Lookup = {}

        local function GetIndex(Pos)
            local Key = Pos.x .. " " .. Pos.y .. " " .. Pos.z
            local Index = Lookup[Key]
            if not Index then
                MeshData.Verts[#MeshData.Verts + 1] = Pos
                Index = #MeshData.Verts
                Lookup[Key] = Index
            end
            return Index
        end

        for _, Convex in ipairs(Meshes) do
            local Tris    = {}
            local NormSum = Vector(0, 0, 0)
            local Volume  = 0

            for I = 1, #Convex, 3 do
                local A = Convex[I].pos
                local B = Convex[I + 1].pos
                local C = Convex[I + 2].pos

                NormSum = NormSum + (B - A):Cross(C - A)
                Volume  = Volume + A:Dot(B:Cross(C)) -- Scalar triple product gives 6 times the volume

                Tris[#Tris + 1] = Vector(GetIndex(A), GetIndex(B), GetIndex(C))
            end

            MeshData.Convexes[#MeshData.Convexes + 1] = {
                Tris   = Tris,
                Normal = NormSum:GetNormalized(),
                Volume = math.abs(Volume) / 6,
            }
        end

        Entity.ACF_Volumetric_Mesh = MeshData
    end

    local function ProcessEntity(entity)
        if IsValid(entity) and (entity.IsACFEntity or ArmorableClasses[entity:GetClass()]) and IsValid(entity:GetPhysicsObject()) then
            local convexes = entity:GetPhysicsObject():GetMeshConvexes() or {}
            ProcessConvexes(entity, convexes)
        end
    end

    hook.Add("ACF_OnLoadAddon", "ACF_Volumetric_Detours", function()
        local Detours = ACF and ACF.Detours
        print("Loading ACF Volumetric Detours", Detours)

        local PhysInitConvex_Orig PhysInitConvex_Orig = Detours.Metatable("Entity", "PhysicsInitConvex", function(self, Mesh, ...)
            timer.Simple(0, function()
                -- print("PhysicsInitConvex", self, Mesh)
                ProcessEntity(self)
            end)
            return PhysInitConvex_Orig(self, Mesh, ...)
        end)

        local PhysInitMultiConvex_Orig PhysInitMultiConvex_Orig = Detours.Metatable("Entity", "PhysicsInitMultiConvex", function(self, Meshes, ...)
            timer.Simple(0, function()
                -- print("PhysicsInitMultiConvex", self, Meshes)
                ProcessEntity(self)
            end)
            return PhysInitMultiConvex_Orig(self, Meshes, ...)
        end)

        -- Everything in general
        hook.Add("OnEntityCreated", "ACF_Volumetric_Detours", function(ent)
            timer.Simple(0, function()
                -- print("OnEntityCreated", ent)
                ProcessEntity(ent)
            end)
        end)
    end)
end

-- Returns a sorted list of { Pos, Normal, ConvexIndex, T } for every triangle the ray pierces.
-- Verts are stored in local space, so Entity is required to transform them into world space.
function ACF.RayIntersectMesh(Entity, Start, Direction, Length)
    local MeshData = Entity.ACF_Volumetric_Mesh
    if not MeshData then return {} end

    local Verts   = MeshData.Verts
    local Hits    = {}
    local NormDir = Direction:GetNormalized()

    for ConvexID, Convex in ipairs(MeshData.Convexes) do
        for _, Tri in ipairs(Convex.Tris) do
            local A = Entity:LocalToWorld(Verts[Tri[1]])
            local B = Entity:LocalToWorld(Verts[Tri[2]])
            local C = Entity:LocalToWorld(Verts[Tri[3]])

            local Normal = (B - A):Cross(C - A):GetNormalized()

            local P = util.IntersectRayWithPlane(Start, NormDir, A, Normal)
            if not P then continue end

            -- Recover the T value along the ray and make sure it's within the ray length
            local T = (P - Start):Dot(NormDir)
            if T < 0 or T > Length then continue end

            -- Make sure the point is within the triangle, not just its plane
            if (B - A):Cross(P - A):Dot(Normal) < 0 then continue end
            if (C - B):Cross(P - B):Dot(Normal) < 0 then continue end
            if (A - C):Cross(P - C):Dot(Normal) < 0 then continue end

            Hits[#Hits + 1] = { Pos = P, Normal = Normal, ConvexID = ConvexID, T = T }
        end
    end

    -- Order hits by distance from ray start
    table.sort(Hits, function(a, b) return a.T < b.T end)
    return Hits
end