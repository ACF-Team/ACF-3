DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName     = "ACF Armor"
ENT.WireDebugName = "ACF Armor"
ENT.PluralName    = "ACF Armor"
ENT.IsACFArmor    = true

local function FindOtherSide(Ent, Origin, Dire)
    local Mesh = Ent:GetPhysicsObject():GetMeshConvexes()
    local Min  = math.huge

    for K in pairs(Mesh) do -- Loop over mesh
        local Hull = Mesh[K]

        for I = 1, #Hull, 3 do -- Loop over each tri (groups of 3)
            local P1     = Ent:LocalToWorld(Hull[I].pos) -- Points on tri
            local P2     = Ent:LocalToWorld(Hull[I + 1].pos)
            local P3     = Ent:LocalToWorld(Hull[I + 2].pos)
            local Edge1  = P2 - P1
            local Edge2  = P3 - P1

            if Dire:Dot(Edge1:Cross(Edge2)) > 0 then -- Plane facing the wrong way
                continue
            end

            local H = Dire:Cross(Edge2) -- Perpendicular to Dire
            local A = Edge1:Dot(H)

            if A > -0.0001 and A < 0.0001 then -- Parallel
                continue
            end

            local F = 1 / A
            local S = Origin - P1 -- Displacement from to origin from P1
            local U = F * S:Dot(H)

            if U < 0 or U > 1 then
                continue
            end

            local Q = S:Cross(Edge1)
            local V = F * Dire:Dot(Q)

            if V < 0 or U + V > 1 then
                continue
            end

            local T = F * Edge2:Dot(Q) -- Length of ray to intersection

            if T > 0.0001 and T < Min then -- >0 length
                Min = T
            end
        end
    end

    return Origin + Dire * Min
end

local function TraceThroughObject(Trace)
    local Ent    = Trace.Entity
    local Origin = Trace.StartPos
    local Enter  = Trace.HitPos
    local Dire   = (Enter - Trace.StartPos):GetNormalized()

    local Opposite = FindOtherSide(Ent, Origin, Dire)
    local Exit     = ACF.trace({start = Enter, endpos = Opposite, filter = {Ent}}).HitPos
    local Length   = (Exit - Enter):Length() * 25.4 -- Inches to mm

    return Length, Exit
end

function ENT:GetArmor(Trace)
    if not IsValid(Trace.Entity) then
        return 0
    end

    local Enter        = Trace.HitPos
    local Length, Exit = TraceThroughObject(Trace)

    debugoverlay.Cross(Enter, 3, 0.015, Color(0, 255, 0), true)
    debugoverlay.Cross(Exit, 3, 0.015, Color(255, 0, 0), true)
    debugoverlay.Line(Enter, Exit, 0.015, Color(0, 255, 255), true)

    return ACF.RHAe(Length, self.Density)
end