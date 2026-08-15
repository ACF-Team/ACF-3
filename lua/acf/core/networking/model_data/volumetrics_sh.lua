local ACF       = ACF
local ModelData = ACF.ModelData

-- Note: Put this in console for good luck: hook.Run("ACF_OnLoadAddon")

-- TODO: Move these into the globals file
local CubicInchToM3 = ACF.InchToMCu
local HealthMul = ACF.HealthCoef
local ArmorCoef = ACF.ArmorCoef
local ArmorTypes = ACF.Classes.ArmorTypes

-- Networking: whenever a convex's material is set (serverside), the new material is sent straight to
-- every client. No request/refresh cycle -- just send it the moment it changes.
local MAX_CONVEXES  = 5 -- bits for the convex index field
local MAX_MATERIALS = 5 -- bits for the material index field

local ArmorTypeByIndex   = {} -- index (1-based int) -> armor type ID string
local ArmorTypeIndexByID = {} -- armor type ID string -> index (1-based int)

-- Built once after all armor types are registered; neither table changes after this.
hook.Add("ACF_OnLoadAddon", "ACF_BuildArmorTypeIndex", function()
    local List = ArmorTypes.GetList()
    table.sort(List, function(A, B) return A.ID < B.ID end)

    for I, Entry in ipairs(List) do
        ArmorTypeByIndex[I]           = Entry.ID
        ArmorTypeIndexByID[Entry.ID]  = I
    end
end)

if SERVER then
    util.AddNetworkString("ACF_ConvexMaterialSet")
end

if CLIENT then
    net.Receive("ACF_ConvexMaterialSet", function()
        local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
        local Count    = net.ReadUInt(MAX_CONVEXES)

        local Materials = {}
        for _ = 1, Count do
            local ConvexID = net.ReadUInt(MAX_CONVEXES)
            local MatIndex = net.ReadUInt(MAX_MATERIALS)
            Materials[ConvexID] = ArmorTypeByIndex[MatIndex] or "Default"
        end

        local Ent = Entity(EntIndex)
        if not IsValid(Ent) then return end

        ACF.SetConvexMaterials(Ent, Materials)
    end)
end

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

    -- Sets the materials ({[ConvexID] = MaterialID, ...}) of one or more convexes.
    -- Batches network updates.
    -- Returns false if any convex was rejected (e.g. an explosive material on too large a convex)
    function ACF.SetConvexMaterials(Entity, Materials, Player, NoStore)
        local MeshData = Entity.ACF_Volumetric_Mesh
        if not MeshData then return end

        Entity.ACF_Volumetric_Materials = Entity.ACF_Volumetric_Materials or {}

        local Changed  = {} -- ConvexID -> ArmorType.ID, for networking/storage
        local AnyOK    = false
        local AllOK    = true

        for ConvexID, Material in pairs(Materials) do
            local Convex = MeshData.Convexes[ConvexID]
            if not Convex then continue end

            local ArmorType = ArmorTypes.Get(Material) or ArmorTypes.Get("Default")

            if ArmorType.IsExplosive and Convex.Volume > ACF.MaxExplosiveConvexVolume then
                if SERVER and IsValid(Player) then
                    ACF.Utilities.Messages.SendChat(Player, "Error", "Convex " .. ConvexID .. " is too large for an explosive material (limit: " .. ACF.MaxExplosiveConvexVolume .. " in³).")
                end
                AllOK = false
                continue
            end

            Convex.Material    = ArmorType.ID
            Convex.Mass        = Convex.Volume * CubicInchToM3 * ArmorType.Density -- Volume is in^3, Density is kg/m^3
            Convex.MaxHealth   = Convex.Volume * ArmorType.HealthMul * HealthMul -- HealthMul bakes in material density
            Convex.Health      = Convex.MaxHealth
            Convex.IsExplosive = ArmorType.IsExplosive or nil -- Reactive armor; see Ballistics.DoReactiveArmor

            Entity.ACF_Volumetric_Materials[ConvexID] = Convex.Material
            Changed[ConvexID] = ArmorType.ID
            AnyOK = true
        end

        if not AnyOK then return AllOK end

        local TotalMass    = 0
        local HasReactive  = false
        for _, Conv in ipairs(MeshData.Convexes) do
            TotalMass = TotalMass + Conv.Mass
            if Conv.IsExplosive then HasReactive = true end
        end

        MeshData.TotalMass         = TotalMass
        MeshData.HasReactiveArmor  = HasReactive -- Lets ballistics skip the reactive-armor check entirely for normal entities

        if SERVER then
            local Count = 0
            for _ in pairs(Changed) do Count = Count + 1 end
            Count = math.min(Count, 31)

            net.Start("ACF_ConvexMaterialSet")
            net.WriteUInt(Entity:EntIndex(), MAX_EDICT_BITS)
            net.WriteUInt(Count, MAX_CONVEXES)

            local Sent = 0
            for ConvexID, MaterialID in pairs(Changed) do
                if Sent >= Count then break end
                net.WriteUInt(ConvexID, MAX_CONVEXES)
                net.WriteUInt(ArmorTypeIndexByID[MaterialID] or ArmorTypeIndexByID["Default"] or 1, MAX_MATERIALS)
                Sent = Sent + 1
            end
            net.Broadcast()

            local HasNonDefault = false
            for _, MaterialID in pairs(Changed) do
                if MaterialID ~= "Default" then HasNonDefault = true break end
            end

            if HasNonDefault then
                if not NoStore then duplicator.StoreEntityModifier(Entity, "ACF_ArmorMesh", { Materials = Entity.ACF_Volumetric_Materials }) end

                local EntACF = Entity.ACF
                if EntACF then
                    ACF.Contraption.SetMass(Entity, TotalMass)
                else
                    local Phys = Entity:GetPhysicsObject()
                    if IsValid(Phys) then Phys:SetMass(TotalMass) end
                end
            end
        end

        return AllOK
    end

    -- Convenience wrapper for setting a single convex's material; see ACF.SetConvexMaterials.
    function ACF.SetConvexMaterial(Entity, ConvexID, Material, Player, NoStore)
        return ACF.SetConvexMaterials(Entity, { [ConvexID] = Material }, Player, NoStore)
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

        local Materials = {}
        for ConvexID in ipairs(MeshData.Convexes) do
            -- Priority: per-convex painted material > global material override > fixed ConvexMaterial > entity-type default.
            -- ACF_Volumetric_Material_Override covers entities converted from the old uniform-RHA system where the
            -- convex count may change after initialization (e.g. hollow cube primitives start solid, reinitialize hollow).
            local Material
            if not Entity.ACF_PreventArmoring then
                Material = Entity.ACF_Volumetric_Material_Override or (Entity.ACF_Volumetric_Materials and Entity.ACF_Volumetric_Materials[ConvexID])
            end
            Materials[ConvexID] = Material or Entity.ConvexMaterial or (Entity.IsACFEntity and "RHA" or "Default")
        end
        ACF.SetConvexMaterials(Entity, Materials, nil, true)
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

        local HitsBefore = #Hits

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

        -- Started inside this convex: only the exit hit came back. Add the missing entry at T = 0.
        if #Hits - HitsBefore == 1 then
            Hits[#Hits + 1] = { Pos = Start, Normal = -NormDir, ConvexID = ConvexID, T = 0, Entity = Entity, IsEntry = true }
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
local function TestTrace( ply )
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
    -- PrintTable(Intersections)

    local Hits = ACF.ResolveConvexStack(Intersections, dir)

    for Index, Hit in ipairs(Hits) do
        local Col = ACF.GetIndexColor(Index)
        debugoverlay.Line(Hit.EntryPos, Hit.ExitPos, 10, Col, true)
        debugoverlay.EntityTextAtPosition((Hit.EntryPos + Hit.ExitPos) / 2, 0, Hit.ArmorType.Name, 10, Col)
        debugoverlay.EntityTextAtPosition((Hit.EntryPos + Hit.ExitPos) / 2, 1, "CID: " .. Hit.ConvexID, 10, Col)
        debugoverlay.EntityTextAtPosition((Hit.EntryPos + Hit.ExitPos) / 2, 2, "RHAe: " .. math.Round(Hit.GeoThick * Hit.ArmorType.KineticMul), 10, Col)
    end
end

concommand.Add( "test_trace", TestTrace )
if CLIENT then concommand.Add( "test_trace_cl", function() TestTrace( LocalPlayer() ) end ) end

-- Draws the convex hulls (ACF_Volumetric_Mesh) of the entity being looked at.
local function DrawConvexes( ply )
    local Ent = ply:GetEyeTrace().Entity
    print("DrawConvexes", Ent)
    if not IsValid(Ent) then return end

    local MeshData = Ent.ACF_Volumetric_Mesh
    if not MeshData then return end

    for ConvexID, Convex in ipairs(MeshData.Convexes) do
        local Col = ACF.GetIndexColor(ConvexID)
        local FillCol = Color(Col.r, Col.g, Col.b, 80)

        for _, Tri in ipairs(Convex.Tris) do
            local A = Ent:LocalToWorld(Tri[1])
            local B = Ent:LocalToWorld(Tri[2])
            local C = Ent:LocalToWorld(Tri[3])

            debugoverlay.Triangle(A, B, C, 10, FillCol, true)
            debugoverlay.Line(A, B, 10, color_white, true)
            debugoverlay.Line(B, C, 10, color_white, true)
            debugoverlay.Line(C, A, 10, color_white, true)

            local Center = (A + B + C) / 3
            local Normal = (C - A):Cross(B - A):GetNormalized()
            debugoverlay.Line(Center, Center + Normal * 5, 10, Col, true)
        end

        local Center = Ent:LocalToWorld(Convex.Tris[1][1])
        debugoverlay.EntityTextAtPosition(Center, 0, "CID: " .. ConvexID, 10, Col)
    end
end

concommand.Add( "test_draw_convexes", DrawConvexes )
if CLIENT then concommand.Add( "test_draw_convexes_cl", function() DrawConvexes( LocalPlayer() ) end ) end

-- Draws the raw physics convex hulls (PhysObj:GetMeshConvexes()) of the entity being looked at.
local function DrawMeshConvexes( ply )
    local Ent = ply:GetEyeTrace().Entity
    print("DrawMeshConvexes", Ent)
    if not IsValid(Ent) then return end

    local PhysObj = Ent:GetPhysicsObject()
    if not IsValid(PhysObj) then return end

    local Mesh = PhysObj:GetMeshConvexes()
    if not Mesh then return end

    for ConvexID, Hull in ipairs(Mesh) do
        local Col = ACF.GetIndexColor(ConvexID)
        local FillCol = Color(Col.r, Col.g, Col.b, 80)

        for I = 1, #Hull, 3 do
            local A = Ent:LocalToWorld(Hull[I].pos)
            local B = Ent:LocalToWorld(Hull[I + 1].pos)
            local C = Ent:LocalToWorld(Hull[I + 2].pos)

            debugoverlay.Triangle(A, B, C, 10, FillCol, true)
            debugoverlay.Line(A, B, 10, color_white, true)
            debugoverlay.Line(B, C, 10, color_white, true)
            debugoverlay.Line(C, A, 10, color_white, true)

            local Center = (A + B + C) / 3
            local Normal = (C - A):Cross(B - A):GetNormalized()
            debugoverlay.Line(Center, Center + Normal * 5, 10, Col, true)
        end

        local Center = Ent:LocalToWorld(Hull[1].pos)
        debugoverlay.EntityTextAtPosition(Center, 0, "CID: " .. ConvexID, 10, Col)
    end
end

concommand.Add( "test_draw_meshconvexes", DrawMeshConvexes )
if CLIENT then concommand.Add( "test_draw_meshconvexes_cl", function() DrawMeshConvexes( LocalPlayer() ) end ) end