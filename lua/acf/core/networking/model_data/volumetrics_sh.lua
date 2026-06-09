local ACF = ACF

-- TODO: Merge these lists with the other global ACF filters

local CubicInchToCm3 = 16.3871 -- 1 in^3 = 16.3871 cm^3 (Hammer units are inches in physics)

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
    primitive_shape      = true,
    primitive_staircase  = true,
    primitive_ladder     = true,
    primitive_rail_silder = true,
    primitive_rail_slider = true,
    primitive_airfoil    = true,
}

if SERVER then
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

                NormSum = NormSum + (B - A):Cross(C - A)
                Volume  = Volume + A:Dot(B:Cross(C)) -- Scalar triple product gives 6 times the volume

                Tris[#Tris + 1] = Vector(GetIndex(A), GetIndex(B), GetIndex(C))
            end

            -- TODO: TUNE THESE ONCE FUNCTIONALITY IS DONE
            local Material   = "RHA" -- Placeholder
            local ArmorType  = ArmorTypes.Get(Material) or ArmorTypes.Get("RHA")
            local Volume_cm3 = math.abs(Volume) / 6 * CubicInchToCm3
            local Health     = Volume_cm3 * ArmorType.Density * ArmorType.HealthMul -- Density in kg/cm^3.

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

        local EntACF = entity.ACF
        if EntACF then
            local MaxHealth  = entity.ACF_Volumetric_Mesh.MaxHealth
            EntACF.MaxHealth = MaxHealth
            EntACF.Health    = MaxHealth
        end
    end
    ACF.ComputeVolumetricMesh = ComputeVolumetricMesh

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

-- Finds the first convex entry/exit pair the ray passes through and returns damage-relevant data.
-- Returns nil if the entity has no mesh or the ray misses all live convexes.
-- GeoThick is geometric thickness in mm; multiply by ArmorType.KineticMul or .ChemicalMul as needed.
function ACF.GetConvexHit(Entity, HitPos, Direction)
    local MeshData = Entity.ACF_Volumetric_Mesh
    if not MeshData then return nil end

    local Hits  = ACF.RayIntersectMesh(Entity, HitPos - Direction * 2, Direction, 10000)
    local Entry, ExitHit

    for _, Hit in ipairs(Hits) do
        if not Entry then
            if Direction:Dot(Hit.Normal) < 0 then Entry = Hit end
        elseif Hit.ConvexID == Entry.ConvexID and Direction:Dot(Hit.Normal) > 0 then
            ExitHit = Hit
            break
        end
    end

    if not (Entry and ExitHit) then return nil end

    local ArmorTypes = ACF.Classes.ProcArmorTypes
    local Convex     = MeshData.Convexes[Entry.ConvexID]
    local ArmorType  = ArmorTypes.Get(Convex.Material) or ArmorTypes.Get("RHA")

    return {
        ConvexID = Entry.ConvexID,
        GeoThick = (ExitHit.T - Entry.T) * 25.4, -- inches to mm
        ArmorType = ArmorType,
        HitAngle = math.deg(math.acos(math.min(1, math.max(-1, -Direction:Dot(Entry.Normal))))),
    }
end