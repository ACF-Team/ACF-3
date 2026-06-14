local ACF       = ACF
local ModelData = ACF.ModelData

-- Note: Put this in console for good luck: hook.Run("ACF_OnLoadAddon")

-- TODO: Move these into the globals file
local CubicInchToM3 = ACF.InchToMCu
local HealthMul = ACF.HealthCoef
local ArmorCoef = ACF.ArmorCoef

-- TODO: Merge these lists with the other global ACF filters

-- Classes we should compute the mesh for
local ArmorableClasses = {
    prop_physics = true,
    starfall_prop = true,
    acf_missile = true,

    -- Vehicles
    prop_vehicle_prisoner_pod = true,
    prop_vehicle_jeep = true,
    prop_vehicle_airboat = true,
    prop_vehicle_apc = true,

    -- Primitives
    primitive_shape = true,
    primitive_staircase = true,
    primitive_ladder = true,
    primitive_rail_silder = true,
    primitive_airfoil = true,
}

-- TODO: Handle reinitializable classes
do
    local ArmorTypes = ACF.Classes.ArmorTypes

    -- Sets the material of a convex, recalculating its mass, health pool, and the entity's aggregates.
    function ACF.SetConvexMaterial(Entity, ConvexID, Material)
        local MeshData = Entity.ACF_Volumetric_Mesh
        if not MeshData then return end

        local Convex = MeshData.Convexes[ConvexID]
        if not Convex then return end

        local ArmorType = ArmorTypes.Get(Material) or ArmorTypes.Get("Default")

        Convex.Material    = ArmorType.ID
        -- print("SetConvexMaterial", Entity, ConvexID, Material, Convex.Material)
        Convex.Mass        = Convex.Volume * CubicInchToM3 * ArmorType.Density -- Volume is in^3, Density is kg/m^3
        Convex.MaxHealth   = Convex.Volume * CubicInchToM3 * ArmorType.HealthMul * HealthMul -- HealthMul bakes in material density
        Convex.Health      = Convex.MaxHealth
        Convex.IsExplosive = ArmorType.IsExplosive or nil -- Reactive armor; see Ballistics.DoReactiveArmor

        local TotalMass    = 0
        local HasReactive  = false
        for _, Conv in ipairs(MeshData.Convexes) do
            TotalMass = TotalMass + Conv.Mass
            if Conv.IsExplosive then HasReactive = true end
        end

        MeshData.TotalMass         = TotalMass
        MeshData.HasReactiveArmor  = HasReactive -- Lets ballistics skip the reactive-armor check entirely for normal entities

        if SERVER and ArmorType.ID ~= "Default" then
            local EntACF = Entity.ACF
            if EntACF then
                ACF.Contraption.SetMass(Entity, TotalMass)
            else
                Entity:GetPhysicsObject():SetMass(TotalMass)
            end
        end
    end

    function ProcessConvexes(Entity, Meshes)
        local MeshData = { Verts = {}, Convexes = {} }
        local Lookup   = {}

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
                local A = Convex[I]
                local B = Convex[I + 1]
                local C = Convex[I + 2]

                NormSum = NormSum + (C - A):Cross(B - A) -- Outward-facing; GetMeshConvexes triangles wind such that (B-A)x(C-A) points inward
                Volume  = Volume + A:Dot(B:Cross(C)) -- Scalar triple product gives 6 times the volume

                Tris[#Tris + 1] = Vector(GetIndex(A), GetIndex(B), GetIndex(C))
            end

            -- Material-independent characteristics; material-dependent ones (Material, Mass, Health, MaxHealth)
            -- are filled in below by ACF.SetConvexMaterial.
            MeshData.Convexes[#MeshData.Convexes + 1] = {
                Tris      = Tris,
                Normal    = NormSum:GetNormalized(),
                Volume    = math.abs(Volume) / 6, -- Verts are in inches (Source units), so this is in^3
                Mass      = 0,
                Health    = 0,
                MaxHealth = 0,
                Entity    = Entity,
            }
        end

        MeshData.TotalMass         = 0
        Entity.ACF_Volumetric_Mesh = MeshData

        for ConvexID in ipairs(MeshData.Convexes) do
            -- If painting is allowed for this entity (not ACF_PreventArmoring) and this convex has a saved player-painted material, use that.
            -- Otherwise use the entity's fixed ConvexMaterial (e.g. crew = Flesh, engines = Aluminum), if set.
            -- Otherwise default to RHA for ACF entities, or Default for generic props.
            local Override = not Entity.ACF_PreventArmoring and Entity.ACF_Volumetric_Materials and Entity.ACF_Volumetric_Materials[ConvexID]
            local Material  = Override or Entity.ConvexMaterial or (Entity.IsACFEntity and "RHA" or "Default")
            ACF.SetConvexMaterial(Entity, ConvexID, Material)
        end
    end

    local function ComputeVolumetricMesh(entity, isReInit)
        if not IsValid(entity) then return end
        if not entity.IsACFEntity and not ArmorableClasses[entity:GetClass()] then return end

        -- NOTE: I HATE THIS SO MUCH... ONLY PRIMITIVES AND SCALEABLES HAVE VALID CLIENTSIDE PHYSOBJs...
        local Mesh
        local PhysObj = entity:GetPhysicsObject()

        -- This is fine on the client, but not fine on the server
        if SERVER and not IsValid(PhysObj) then return end

        -- Sanitized version of GetMeshConvexes
        if IsValid(PhysObj) then Mesh = ModelData.SanitizeMesh(PhysObj) end

        -- Fallback if no physobj exists on the client
        if CLIENT and not IsValid(PhysObj) then Mesh = ModelData.GetModelMesh(entity:GetModel(), ModelData.GetEntityScale(entity)) end

        -- TODO: Fix the error that forced me to do this...
        ProcessConvexes(entity, Mesh or {})

        -- ACF entities track their total health as the sum of their convexes' health, separately from the
        -- per-convex health that armorable props (e.g. prop_physics) take damage on directly.
        if entity.IsACFEntity and entity.ACF then
            local TotalHealth = 0
            for _, Convex in ipairs(entity.ACF_Volumetric_Mesh.Convexes) do
                TotalHealth = TotalHealth + Convex.Health
            end

            entity.ACF.MaxHealth = TotalHealth
            entity.ACF.Health    = TotalHealth
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
-- Filter (optional) is a per-entity set { [ConvexID] = true } of convexes to treat as transparent
-- (e.g. already penetrated by the current projectile), in addition to dead convexes.
function ACF.RayIntersectMesh(Entity, Start, Direction, Length, IncludeDead, Filter)
    local MeshData = Entity.ACF_Volumetric_Mesh
    if not MeshData then return {} end

    local Verts   = MeshData.Verts
    local Hits    = {}
    local NormDir = Direction:GetNormalized()

    for ConvexID, Convex in ipairs(MeshData.Convexes) do
        if Convex.Health <= 0 and not IncludeDead then continue end -- destroyed convex is transparent to projectiles
        if Filter and Filter[ConvexID] then continue end -- explicitly filtered (already penetrated this flight)

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
-- Filter (optional) is a per-entity set { [ConvexID] = true } of convexes to treat as transparent (already penetrated).
function ACF.GetConvexHits(Entity, HitPos, Direction, IncludeDead, Filter)
    local MeshData = Entity.ACF_Volumetric_Mesh
    if not MeshData then return {} end

    local Hits       = ACF.RayIntersectMesh(Entity, HitPos - Direction * 2, Direction, 10000, IncludeDead, Filter)
    local ArmorTypes = ACF.Classes.ArmorTypes
    local ConvexHits = {}
    local Entry

    for _, Hit in ipairs(Hits) do
        if not Entry then
            if Direction:Dot(Hit.Normal) < 0 then Entry = Hit end
        elseif Hit.ConvexID == Entry.ConvexID and Direction:Dot(Hit.Normal) > 0 then
            local Convex    = MeshData.Convexes[Entry.ConvexID]
            local ArmorType = ArmorTypes.Get(Convex.Material) or ArmorTypes.Get("Default")

            ConvexHits[#ConvexHits + 1] = {
                ConvexID    = Entry.ConvexID,
                GeoThick    = (Hit.T - Entry.T) * 25.4 * ArmorCoef, -- inches to mm
                ArmorType   = ArmorType,
                HitAngle    = math.deg(math.acos(math.min(1, math.max(-1, -Direction:Dot(Entry.Normal))))),
                EntryPos    = Entry.Pos,
                ExitPos     = Hit.Pos,
                EntryNormal = Entry.Normal,
            }

            Entry = nil
        end
    end

    return ConvexHits
end

-- Convenience wrapper for ACF.GetConvexHits that returns only the first convex entry/exit pair (or nil if none).
function ACF.GetConvexHit(Entity, HitPos, Direction, IncludeDead, Filter)
    return ACF.GetConvexHits(Entity, HitPos, Direction, IncludeDead, Filter)[1]
end

-- Returns an entity's total health and max health. ACF entities track this directly on their ACF table (damage is
-- deferred to it), while armorable props take damage per convex, so their totals are summed from their convexes.
function ACF.GetEntityHealth(Entity)
    if Entity.IsACFEntity and Entity.ACF then
        return Entity.ACF.Health or 0, Entity.ACF.MaxHealth or 0
    end

    local MeshData = Entity.ACF_Volumetric_Mesh
    if not MeshData then return 0, 0 end

    local Health, MaxHealth = 0, 0

    for _, Convex in ipairs(MeshData.Convexes) do
        Health    = Health + Convex.Health
        MaxHealth = MaxHealth + Convex.MaxHealth
    end

    return Health, MaxHealth
end