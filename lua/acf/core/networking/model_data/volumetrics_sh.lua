local ACF = ACF


-- TODO: Move these into the globals file
local CubicInchToCm3 = 16.3871 -- 1 in^3 = 16.3871 cm^3 (Hammer units are inches in physics)
local HealthMul = 1

-- TODO: Merge these lists with the other global ACF filters

-- Classes we should compute the mesh for
local ArmorableClasses = {
    prop_physics = true,
    primitive_shape = true,
    primitive_staircase = true,
    primitive_ladder = true,
    primitive_rail_silder = true,
    primitive_airfoil = true,
}

-- Classes whose physics mesh may be reinitialized after creation (e.g. primitives that change shape)
local ReInitializableClasses = {
--     primitive_shape      = true,
--     primitive_staircase  = true,
--     primitive_ladder     = true,
--     primitive_rail_silder = true,
--     primitive_rail_slider = true,
--     primitive_airfoil    = true,
}

do
    function ProcessConvexes(Entity, Meshes)
        local MeshData   = { Verts = {}, Convexes = {} }
        local Lookup     = {}
        local ArmorTypes = ACF.Classes.ProcArmorTypes

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

        local TotalMaxHealth = 0

        for _, Convex in ipairs(Meshes) do
            local Tris    = {}
            local NormSum = Vector(0, 0, 0)
            local Volume  = 0

            for I = 1, #Convex, 3 do
                local A = Convex[I].pos
                local B = Convex[I + 1].pos
                local C = Convex[I + 2].pos

                NormSum = NormSum + (C - A):Cross(B - A) -- Outward-facing; GetMeshConvexes triangles wind such that (B-A)x(C-A) points inward
                Volume  = Volume + A:Dot(B:Cross(C)) -- Scalar triple product gives 6 times the volume

                Tris[#Tris + 1] = Vector(GetIndex(A), GetIndex(B), GetIndex(C))
            end

            -- TODO: TUNE THESE ONCE FUNCTIONALITY IS DONE
            local Material   = "RHA" -- Placeholder
            local ArmorType  = ArmorTypes.Get(Material) or ArmorTypes.Get("RHA")
            local Volume_cm3 = math.abs(Volume) / 6 * CubicInchToCm3
            local Health     = Volume_cm3 * ArmorType.Density * ArmorType.HealthMul * HealthMul-- Density in kg/cm^3.

            TotalMaxHealth = TotalMaxHealth + Health

            MeshData.Convexes[#MeshData.Convexes + 1] = {
                Tris      = Tris,
                Normal    = NormSum:GetNormalized(),
                Volume    = Volume_cm3,
                Material  = Material,
                Health    = Health,
                MaxHealth = Health,
                Entity    = Entity,
            }
        end

        MeshData.MaxHealth         = TotalMaxHealth
        Entity.ACF_Volumetric_Mesh = MeshData
    end

    local function ComputeVolumetricMesh(entity, isReInit)
        if not IsValid(entity) then return end
        if not entity.IsACFEntity and not ArmorableClasses[entity:GetClass()] then return end
        if not isReInit and ReInitializableClasses[entity:GetClass()] then return end

        local PhysObj = entity:GetPhysicsObject()
        if not IsValid(PhysObj) then return end

        ProcessConvexes(entity, PhysObj:GetMeshConvexes() or {})

        if SERVER then
            local EntACF = entity.ACF
            if EntACF then
                local MaxHealth  = entity.ACF_Volumetric_Mesh.MaxHealth
                EntACF.MaxHealth = MaxHealth
                EntACF.Health    = MaxHealth
            end
        end
    end
    ACF.ComputeVolumetricMesh = ComputeVolumetricMesh

    if SERVER then
        -- Sets the material of a convex, recalculating its health pool and the entity's aggregate health.
        function ACF.SetConvexMaterial(Entity, ConvexID, Material)
            local MeshData = Entity.ACF_Volumetric_Mesh
            if not MeshData then return end

            local Convex = MeshData.Convexes[ConvexID]
            if not Convex then return end

            local ArmorTypes = ACF.Classes.ProcArmorTypes
            local ArmorType  = ArmorTypes.Get(Material) or ArmorTypes.Get("RHA")

            Convex.Material  = ArmorType.ID
            Convex.MaxHealth = Convex.Volume * ArmorType.Density * ArmorType.HealthMul * HealthMul
            Convex.Health    = Convex.MaxHealth

            local TotalMaxHealth, TotalHealth = 0, 0
            for _, Conv in ipairs(MeshData.Convexes) do
                TotalMaxHealth = TotalMaxHealth + Conv.MaxHealth
                TotalHealth    = TotalHealth + Conv.Health
            end

            MeshData.MaxHealth = TotalMaxHealth

            local EntACF = Entity.ACF
            if EntACF then
                EntACF.MaxHealth = TotalMaxHealth
                EntACF.Health    = TotalHealth
            end
        end
    end

    hook.Add("ACF_OnLoadAddon", "ACF_Volumetric_Detours", function()
        local Detours = ACF and ACF.Detours
        print("Loading ACF Volumetric Detours", Detours)

        local PhysInitConvex_Orig PhysInitConvex_Orig = Detours.Metatable("Entity", "PhysicsInitConvex", function(self, Mesh, ...)
            timer.Simple(0, function()
                -- print("PhysicsInitConvex", self, Mesh)
                ComputeVolumetricMesh(self)
            end)
            return PhysInitConvex_Orig(self, Mesh, ...)
        end)

        local PhysInitMultiConvex_Orig PhysInitMultiConvex_Orig = Detours.Metatable("Entity", "PhysicsInitMultiConvex", function(self, Meshes, ...)
            timer.Simple(0, function()
                -- print("PhysicsInitMultiConvex", self, Meshes)
                ComputeVolumetricMesh(self)
            end)
            return PhysInitMultiConvex_Orig(self, Meshes, ...)
        end)

        -- Everything in general
        hook.Add("OnEntityCreated", "ACF_Volumetric_Detours", function(ent)
            timer.Simple(0, function()
                -- print("OnEntityCreated", ent)
                ComputeVolumetricMesh(ent)
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
        if Convex.Health <= 0 then continue end -- destroyed convex is transparent to projectiles

        for _, Tri in ipairs(Convex.Tris) do
            local A = Entity:LocalToWorld(Verts[Tri[1]])
            local B = Entity:LocalToWorld(Verts[Tri[2]])
            local C = Entity:LocalToWorld(Verts[Tri[3]])

            -- Plane/barycentric math is orientation-agnostic, so this raw cross product is fine for it
            local RawNormal = (B - A):Cross(C - A):GetNormalized()

            local P = util.IntersectRayWithPlane(Start, NormDir, A, RawNormal)
            if not P then continue end

            -- Recover the T value along the ray and make sure it's within the ray length
            local T = (P - Start):Dot(NormDir)
            if T < 0 or T > Length then continue end

            -- Make sure the point is within the triangle, not just its plane
            if (B - A):Cross(P - A):Dot(RawNormal) < 0 then continue end
            if (C - B):Cross(P - B):Dot(RawNormal) < 0 then continue end
            if (A - C):Cross(P - C):Dot(RawNormal) < 0 then continue end

            -- GetMeshConvexes triangles wind such that (B-A)x(C-A) points inward; flip for the stored outward normal
            Hits[#Hits + 1] = { Pos = P, Normal = -RawNormal, ConvexID = ConvexID, T = T }
        end
    end

    -- Order hits by distance from ray start
    table.sort(Hits, function(a, b) return a.T < b.T end)
    return Hits
end

-- Finds every convex entry/exit pair the ray passes through, in order, and returns damage-relevant data for each.
-- Returns an empty table if the entity has no mesh or the ray misses all live convexes.
-- GeoThick is geometric thickness in mm; multiply by ArmorType.KineticMul or .ChemicalMul as needed.
function ACF.GetConvexHits(Entity, HitPos, Direction)
    local MeshData = Entity.ACF_Volumetric_Mesh
    if not MeshData then return {} end

    local Hits       = ACF.RayIntersectMesh(Entity, HitPos - Direction * 2, Direction, 10000)
    local ArmorTypes = ACF.Classes.ProcArmorTypes
    local ConvexHits = {}
    local Entry

    for _, Hit in ipairs(Hits) do
        if not Entry then
            if Direction:Dot(Hit.Normal) < 0 then Entry = Hit end
        elseif Hit.ConvexID == Entry.ConvexID and Direction:Dot(Hit.Normal) > 0 then
            local Convex    = MeshData.Convexes[Entry.ConvexID]
            local ArmorType = ArmorTypes.Get(Convex.Material) or ArmorTypes.Get("RHA")

            ConvexHits[#ConvexHits + 1] = {
                ConvexID  = Entry.ConvexID,
                GeoThick  = (Hit.T - Entry.T) * 25.4, -- inches to mm
                ArmorType = ArmorType,
                HitAngle  = math.deg(math.acos(math.min(1, math.max(-1, -Direction:Dot(Entry.Normal))))),
            }

            Entry = nil
        end
    end

    return ConvexHits
end

-- Convenience wrapper for ACF.GetConvexHits that returns only the first convex entry/exit pair (or nil if none).
function ACF.GetConvexHit(Entity, HitPos, Direction)
    return ACF.GetConvexHits(Entity, HitPos, Direction)[1]
end