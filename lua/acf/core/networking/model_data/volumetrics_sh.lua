local ACF       = ACF
local ModelData = ACF.ModelData

-- Note: Put this in console for good luck: hook.Run("ACF_OnLoadAddon")

-- TODO: Move these into the globals file
local CubicInchToM3 = ACF.InchToMCu
local HealthMul = ACF.HealthCoef
local ArmorCoef = ACF.ArmorCoef
local ArmorTypes = ACF.Classes.ArmorTypes

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

do
    local ArmorTypes = ACF.Classes.ArmorTypes

    -- Sets the material of a convex, recalculating its mass, health pool, and the entity's aggregates.
    function ACF.SetConvexMaterial(Entity, ConvexID, Material, Player, ShouldStore)
        local MeshData = Entity.ACF_Volumetric_Mesh
        if not MeshData then return end

        local Convex = MeshData.Convexes[ConvexID]
        if not Convex then return end

        local ArmorType = ArmorTypes.Get(Material) or ArmorTypes.Get("Default")

        if ArmorType.IsExplosive and Convex.Volume > ACF.MaxExplosiveConvexVolume then
            if SERVER and IsValid(Player) then
                ACF.Utilities.Messages.SendChat(Player, "Error", "Convex " .. ConvexID .. " is too large for an explosive material (limit: " .. ACF.MaxExplosiveConvexVolume .. " in³).")
            end
            return false
        end

        Convex.Material    = ArmorType.ID
        Convex.Mass        = Convex.Volume * CubicInchToM3 * ArmorType.Density -- Volume is in^3, Density is kg/m^3
        Convex.MaxHealth   = Convex.Volume * ArmorType.HealthMul * HealthMul -- HealthMul bakes in material density
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

        Entity.ACF_Volumetric_Materials = Entity.ACF_Volumetric_Materials or {}
        Entity.ACF_Volumetric_Materials[ConvexID] = Convex.Material

        if SERVER and ArmorType.ID ~= "Default" then
            if ShouldStore then duplicator.StoreEntityModifier(Entity, "ACF_ArmorMesh", { Materials = Entity.ACF_Volumetric_Materials }) end
            local EntACF = Entity.ACF
            if EntACF then
                ACF.Contraption.SetMass(Entity, TotalMass)
            else
                Entity:GetPhysicsObject():SetMass(TotalMass)
            end
        end
    end

    function ProcessConvexes(Entity, Meshes)
        local MeshData = { Convexes = {} }

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

                Tris[#Tris + 1] = { A, B, C }
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
            -- Priority: per-convex painted material > global material override > fixed ConvexMaterial > entity-type default.
            -- ACF_Volumetric_Material_Override covers entities converted from the old uniform-RHA system where the
            -- convex count may change after initialization (e.g. hollow cube primitives start solid, reinitialize hollow).
            local Material
            if not Entity.ACF_PreventArmoring then
                Material = Entity.ACF_Volumetric_Material_Override or (Entity.ACF_Volumetric_Materials and Entity.ACF_Volumetric_Materials[ConvexID])
            end
            Material = Material or Entity.ConvexMaterial or (Entity.IsACFEntity and "RHA" or "Default")
            ACF.SetConvexMaterial(Entity, ConvexID, Material)
        end
    end

    local function ComputeVolumetricMesh(entity)
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
        -- print("Loading ACF Volumetric Detours", Detours)

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

-- Networking: sends per-entity convex materials to clients when they look at a new contraption.
do
    local ArmorTypes         = ACF.Classes.ArmorTypes
    local ArmorTypeByIndex   = {} -- index (1-based int) -> armor type ID string
    local ArmorTypeIndexByID = {} -- armor type ID string -> index (1-based int)
    local MAX_CONVEXES       = 5  -- bits for the convex count field
    local MAX_MATERIALS      = 5  -- bits for the material index field

    -- Built once after all armor types are registered; neither table changes after this.
    hook.Add("ACF_OnLoadAddon", "ACF_BuildArmorTypeIndex", function()
        local List = ArmorTypes.GetList()
        table.sort(List, function(A, B) return A.ID < B.ID end)

        for I, Entry in ipairs(List) do
            ArmorTypeByIndex[I]       = Entry.ID
            ArmorTypeIndexByID[Entry.ID] = I
        end
    end)

    if SERVER then
        util.AddNetworkString("ACF_EntityMaterials")
        util.AddNetworkString("ACF_ContraptionMaterials_Request")

        -- Tracks the last-seen contraption/entity per player to avoid redundant sends.
        local PlayerLastToken = {}

        hook.Add("PlayerDisconnected", "ACF_ClearPlayerLastToken", function(Player)
            PlayerLastToken[Player] = nil
        end)

        -- Sends the convex materials of a single entity to a player.
        -- Writes a uint5 convex count followed by a uint5 armor type index per convex.
        function ACF.NetworkEntityMaterials(Entity, Player)
            local MeshData = Entity.ACF_Volumetric_Mesh
            if not MeshData then return end

            local Convexes = MeshData.Convexes
            local Count    = math.min(#Convexes, 31)

            net.Start("ACF_EntityMaterials")
            net.WriteUInt(Entity:EntIndex(), MAX_EDICT_BITS)
            net.WriteUInt(Count, MAX_CONVEXES)
            for I = 1, Count do
                local Material = Convexes[I].Material or "Default"
                net.WriteUInt(ArmorTypeIndexByID[Material] or ArmorTypeIndexByID["Default"] or 1, MAX_MATERIALS)
            end
            net.Send(Player)
        end

        net.Receive("ACF_ContraptionMaterials_Request", function(_, Player)
            local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
            local Ent      = Entity(EntIndex)
            if not IsValid(Ent) then return end

            local Contraption = Ent:CFW_GetContraption()
            local Token       = Contraption or Ent

            if PlayerLastToken[Player] == Token then return end
            PlayerLastToken[Player] = Token

            if Contraption then
                for ContraptionEnt in pairs(Contraption.ents) do
                    ACF.NetworkEntityMaterials(ContraptionEnt, Player)
                end
            else
                ACF.NetworkEntityMaterials(Ent, Player)
            end
        end)
    end

    if CLIENT then
        hook.Add("ACF_RenderContext_LookAtChanged", "ACF_NetworkContraptionMaterials", function(_, New)
            if not IsValid(New) then return end
            net.Start("ACF_ContraptionMaterials_Request")
            net.WriteUInt(New:EntIndex(), MAX_EDICT_BITS)
            net.SendToServer()
        end)

        net.Receive("ACF_EntityMaterials", function()
            local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
            local Count    = net.ReadUInt(MAX_CONVEXES)
            local Ent      = Entity(EntIndex)
            local Valid    = IsValid(Ent)

            for I = 1, Count do
                local MatIndex = net.ReadUInt(MAX_MATERIALS)
                if Valid then
                    ACF.SetConvexMaterial(Ent, I, ArmorTypeByIndex[MatIndex] or "Default")
                end
            end
        end)
    end
end

-- Returns every triangle the ray pierces as { Pos, Normal, ConvexID, T, Entity, IsEntry }, unsorted.
-- IsEntry is true when the ray crosses into the face. The ray is a forward half-line: hits behind
-- Start clamp to T = 0 / Pos = Start, so a convex the ray began inside still yields an entry.
-- Filter (optional): a per-entity set { [ConvexID] = true } of convexes to treat as transparent.
function ACF.RayIntersectMesh(Entity, Start, Direction, IncludeDead, Filter)
    local MeshData = Entity.ACF_Volumetric_Mesh
    if not MeshData then return {} end

    local Hits    = {}
    local NormDir = Direction:GetNormalized()

    for ConvexID, Convex in ipairs(MeshData.Convexes) do
        if Convex.Health <= 0 and not IncludeDead then continue end -- destroyed convex is transparent to projectiles
        if Filter and Filter[ConvexID] then continue end -- explicitly filtered (already penetrated this flight)

        for _, Tri in ipairs(Convex.Tris) do
            local A = Entity:LocalToWorld(Tri[1])
            local B = Entity:LocalToWorld(Tri[2])
            local C = Entity:LocalToWorld(Tri[3])

            -- GetMeshConvexes triangles wind such that (C-A)x(B-A) points outward (same as ProcessConvexes)
            local Normal = (C - A):Cross(B - A):GetNormalized()

            local P = util.IntersectRayWithPlane(Start, NormDir, A, Normal)
            if not P then continue end

            -- Make sure the point is within the triangle, not just its plane
            if (B - A):Cross(P - A):Dot(Normal) > 0 then continue end
            if (C - B):Cross(P - B):Dot(Normal) > 0 then continue end
            if (A - C):Cross(P - C):Dot(Normal) > 0 then continue end

            -- Entry when the outward normal opposes the ray. Clamp hits behind Start onto it so a
            -- convex the ray started inside still yields an entry at T = 0.
            local IsEntry = NormDir:Dot(Normal) < 0
            local T       = (P - Start):Dot(NormDir)

            if T < 0 then T = 0 P = Start end

            Hits[#Hits + 1] = { Pos = P, Normal = Normal, ConvexID = ConvexID, T = T, Entity = Entity, IsEntry = IsEntry }
        end
    end

    return Hits
end

-- Builds one hit for the gap Left -> Right, taking material and thickness from Source's convex.
-- Top-level (not a closure) so it compiles once. T values are pre-clamped, so GeoThick stays >= 0.
local function BuildGapHit(Left, Right, Source, Direction)
    local Entity, ConvexID = Source.Entity, Source.ConvexID
    local Convex    = Entity.ACF_Volumetric_Mesh.Convexes[ConvexID]
    local ArmorType = ArmorTypes.Get(Convex.Material) or ArmorTypes.Get("Default")

    return {
        Entity      = Entity,
        ConvexID    = ConvexID,
        GeoThick    = (Right.T - Left.T) * 25.4 * ArmorCoef, -- inches to mm
        ArmorType   = ArmorType,
        HitAngle    = math.deg(math.acos(math.min(1, math.max(-1, -Direction:Dot(Left.Normal))))),
        EntryPos    = Left.Pos,
        ExitPos     = Right.Pos,
        EntryNormal = Left.Normal,
    }
end

-- Front-to-back. At equal distance, entries come before exits so a convex behind Start (both faces
-- at T = 0) meets its exit immediately instead of painting past it.
local function SortIntersections(A, B)
    if A.T == B.T then return A.IsEntry and not B.IsEntry end
    return A.T < B.T
end

-- Pairs intersections into convex hits with "no benefit from clipping": overlapping convexes never
-- add thickness. The innermost convex owns the overlap, and an outer one resumes once the inner exits.
--
-- Every convex has an entry and an exit (see RayIntersectMesh). Resolve by painting: each intersection
-- owns the gap to the next, and each convex paints its own gaps. Visiting entries front-to-back lets a
-- deeper convex overwrite the gaps it clips, so each gap ends up owned by the innermost convex over it.
--
-- Intersections: unsorted list from RayIntersectMesh, sorted here. ClosestOnly returns the first hit
-- or nil. Otherwise returns the full front-to-back list of
-- { Entity, ConvexID, GeoThick, ArmorType, HitAngle, EntryPos, ExitPos, EntryNormal }.
function ACF.ResolveConvexStack(Intersections, Direction, ClosestOnly)
    table.sort(Intersections, SortIntersections)

    local Count = #Intersections

    -- Gap I is Intersections[I] to Intersections[I + 1], with its owner stored on the left boundary.
    -- Match on (Entity, ConvexID): merged intersections can reuse a ConvexID across entities.
    for Index = 1, Count do
        local Entry = Intersections[Index]
        if not Entry.IsEntry then continue end

        for I = Index, Count - 1 do
            Intersections[I].Owner = Entry

            -- Stop at our own exit; the gap past it is outside this convex.
            local Next = Intersections[I + 1]
            if not Next.IsEntry and Next.Entity == Entry.Entity and Next.ConvexID == Entry.ConvexID then break end
        end
    end

    -- One hit per painted gap. The left boundary gives the entry geometry, so a resumed convex picks up
    -- from the inner exit. Zero-width gaps (a convex entirely behind the start) are skipped.
    local Hits = {}
    for I = 1, Count - 1 do
        local Left  = Intersections[I]
        local Owner = Left.Owner
        if not Owner then continue end

        local Right = Intersections[I + 1]
        if Right.T <= Left.T then continue end

        local Hit = BuildGapHit(Left, Right, Owner, Direction)
        if ClosestOnly then return Hit end
        Hits[#Hits + 1] = Hit
    end

    if ClosestOnly then return nil end
    return Hits
end

-- Every convex entry/exit pair the ray passes through a single entity's mesh, in order (see
-- ACF.ResolveConvexStack). GeoThick is in mm; multiply by ArmorType.KineticMul/.ChemicalMul as needed.
-- Filter (optional) is a per-entity set { [ConvexID] = true } of convexes to treat as transparent.
function ACF.GetConvexHits(Entity, HitPos, Direction, IncludeDead, Filter)
    if not Entity.ACF_Volumetric_Mesh then return {} end

    local Start = HitPos - Direction * 2
    local Hits  = ACF.RayIntersectMesh(Entity, Start, Direction, IncludeDead, Filter)

    return ACF.ResolveConvexStack(Hits, Direction)
end

-- Convenience wrapper returning only the closest convex entry/exit pair (or nil if none); see
-- ACF.ResolveConvexStack's ClosestOnly argument.
function ACF.GetConvexHit(Entity, HitPos, Direction, IncludeDead, Filter)
    if not Entity.ACF_Volumetric_Mesh then return nil end

    local Start = HitPos - Direction * 2
    local Hits  = ACF.RayIntersectMesh(Entity, Start, Direction, IncludeDead, Filter)

    return ACF.ResolveConvexStack(Hits, Direction, true)
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

-- Testing new trace logic
concommand.Add( "test_trace", function( ply )
    local plyTr = ply:GetEyeTrace()
    local dir = ply:GetAimVector()

    local start = plyTr.StartPos
    local endpos = plyTr.HitPos + dir * 10000
    local ents = ents.FindAlongRay( start, endpos)

    local Intersections = {}
    for _, ent in ipairs(ents) do
        if ent == ply then continue end

        local EntHits = ACF.RayIntersectMesh(ent, start, dir, true)
        for _, Hit in ipairs(EntHits) do
            Intersections[#Intersections + 1] = Hit
        end
    end

    local Hits = ACF.ResolveConvexStack(Intersections, dir)

    for Index, Hit in ipairs(Hits) do
        local Col = ACF.GetIndexColor(Index)
        debugoverlay.Line(Hit.EntryPos, Hit.ExitPos, 10, Col, true)
        debugoverlay.EntityTextAtPosition((Hit.EntryPos + Hit.ExitPos) / 2, 0, Hit.ArmorType.Name, 10, Col)
        debugoverlay.EntityTextAtPosition((Hit.EntryPos + Hit.ExitPos) / 2, 1, "CID: " .. Hit.ConvexID, 10, Col)

        -- local FaceCol = Color(Col.r, Col.g, Col.b, 50)
        -- local Convex  = Hit.Entity.ACF_Volumetric_Mesh.Convexes[Hit.ConvexID]
        -- for _, Tri in ipairs(Convex.Tris) do
        --     local A = Hit.Entity:LocalToWorld(Tri[1])
        --     local B = Hit.Entity:LocalToWorld(Tri[2])
        --     local C = Hit.Entity:LocalToWorld(Tri[3])

        --     debugoverlay.Triangle(A, B, C, 10, FaceCol, true)
        -- end
    end
end )