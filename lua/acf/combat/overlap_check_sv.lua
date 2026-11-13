-- Purpose: Randomly samples one convex per tick and disables its entity if something else blocks it

local ACF = ACF

local CHECK_INTERVAL = 0.1 -- Seconds between samples

-- Never sampled and never counted as a blocker
local IGNORE_GROUPS = {}

local EXEMPT = {
    acf_baseplate = true,
    acf_waterjet = true,
    acf_controller = true,
    acf_turret = true,
}

local Ignored = {}

for _, Group in ipairs(IGNORE_GROUPS) do
    for _, A in ipairs(Group) do
        Ignored[A] = Ignored[A] or {}

        for _, B in ipairs(Group) do
            Ignored[A][B] = true
        end
    end
end

-- Table order is effectively random, so walking it with a cursor samples everything evenly
local function nextKey(Set, Last)
    if Set[Last] == nil then Last = nil end -- Cursor was removed or not set yet

    return next(Set, Last) or next(Set)
end

-- Random point inside the convex: a random surface point scaled towards the centroid, which is inside since convexes are star-shaped from it
local function samplePoint(Tris, Centroid, Scale)
    local Tri  = Tris[math.random(#Tris)]
    local U, V = math.random(), math.random()

    if U + V > 1 then U, V = 1 - U, 1 - V end

    local Surface = Tri[1] + (Tri[2] - Tri[1]) * U + (Tri[3] - Tri[1]) * V

    -- Cube root evens out the density by volume, Scale keeps the point off the surface
    return Centroid + (Surface - Centroid) * Scale * math.random() ^ (1 / 3)
end

local CurEnt
local CurSkip
local CurOwner

local function traceFilter(Other)
    if Other == CurEnt or not Other.IsACFEntity or Other.ACF_IsNotLegalityChecked or EXEMPT[Other:GetClass()] then return false end
    if CurSkip and CurSkip[Other:GetClass()] then return false end
    if Other:CPPIGetOwner() ~= CurOwner then return false end -- Other players' entities never block, so nobody can disable someone else's by ramming into them

    return true
end

-- Blocker convex the point is deepest inside, nil for the world or entities without a mesh
local function blockerConvex(Blocker, Pos)
    if not IsValid(Blocker) or not Blocker.ACF_Volumetric_Mesh then return end

    local Point = Blocker:WorldToLocal(Pos)
    local Best, BestDepth

    for ConvexID, Convex in ipairs(Blocker.ACF_Volumetric_Mesh.Convexes) do
        local Depth = math.huge

        -- Triangles wind with (C-A)x(B-A) outward, so the depth is the distance to the nearest face plane
        for _, Tri in ipairs(Convex.Tris) do
            local A, B, C = Tri[1], Tri[2], Tri[3]

            Depth = math.min(Depth, (A - Point):Dot((C - A):Cross(B - A):GetNormalized()))
        end

        if not BestDepth or Depth > BestDepth then Best, BestDepth = ConvexID, Depth end
    end

    return Best
end

local LastContraption

local function sample()
    if not ACF.LegalChecks then return end

    local Contr = nextKey(CFW.Contraptions, LastContraption)
    if not Contr then return end

    LastContraption = Contr

    local Set = Contr.ACF_Entities
    if not Set then return end

    local Ent = nextKey(Set, Contr.ACF_OverlapCursor)
    Contr.ACF_OverlapCursor = Ent

    -- Restricted entities are still sampled so a lasting overlap keeps extending its violation
    if not IsValid(Ent) or ACF.IsDestroyed(Ent) or Ent.ACF_IsNotLegalityChecked or EXEMPT[Ent:GetClass()] then return end

    local MeshData = Ent.ACF_Volumetric_Mesh
    if not MeshData then return end

    local NumConvexes = #MeshData.Convexes
    if NumConvexes == 0 then return end

    local ConvexID = math.random(NumConvexes)
    local Convex   = MeshData.Convexes[ConvexID]
    if not Convex or #Convex.Tris == 0 then return end

    -- Sampling the shrunk convex lets entities clip into each other by about ACF.OverlapInset
    local Scale    = ACF.ConvexInsetScale(Convex, ACF.OverlapInset)
    local Centroid = Convex.Centroid
    local Start    = Ent:LocalToWorld(samplePoint(Convex.Tris, Centroid, Scale))
    local End      = Ent:LocalToWorld(samplePoint(Convex.Tris, Centroid, Scale))

    CurEnt   = Ent
    CurSkip  = Ignored[Ent:GetClass()]
    CurOwner = Ent:CPPIGetOwner()

    local Trace = util.TraceLine({
        start  = Start,
        endpos = End,
        filter = traceFilter,
        ignoreworld = true, -- The world never reaches the filter
    })

    if not (Trace.Hit or Trace.StartSolid) then return end

    local HitPos = Trace.StartSolid and Start or Trace.HitPos

    ACF.Legality.Report(Ent, "overlap", {
        From          = Ent:WorldToLocal(Start),
        To            = Ent:WorldToLocal(End),
        HitPos        = Ent:WorldToLocal(HitPos),
        Convex        = ConvexID,
        Blocker       = Trace.Entity,
        BlockerConvex = blockerConvex(Trace.Entity, HitPos),
    })
end

timer.Create("ACF_OverlapCheck", CHECK_INTERVAL, 0, sample)
