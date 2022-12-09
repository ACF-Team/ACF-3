local ACF        = ACF
local Ballistics = ACF.Ballistics

function Ballistics.DigTrace(From, To, Filter)
    local Dig = util.TraceLine({
        start  = From,
        endpos = To,
        mask   = MASK_NPCSOLID_BRUSHONLY, -- Map and brushes only
    })

    debugoverlay.Line(From, Dig.StartPos, 30, ColorRand(100, 255), true)

    if Dig.StartSolid then -- Started inside solid map volume
        if Dig.FractionLeftSolid == 0 then -- Trace could not move inside
            local Displacement = To - From
            local Normal       = Displacement:GetNormalized()
            local Length       = Displacement:Length()

            local C = math.Round(Length / 12)
            local N = Length / C

            for I = 1, C do
                local P = From + Normal * I * N

                local Back = util.TraceLine({ -- Send a trace backwards to hit the other side
                    start  = P,
                    endpos = From, -- Countering the initial offset position of the dig trace to handle things <1 inch thick
                    mask   = MASK_NPCSOLID_BRUSHONLY, -- Map and brushes only
                })

                if Back.StartSolid or Back.HitNoDraw then continue end

                return true, Back.HitPos
            end

            return false
        elseif Dig.FractionLeftSolid == 1 then -- Non-penetration: too thick
            return false
        else -- Penetrated
            if Dig.HitNoDraw then -- Hit a layer inside
                return Ballistics.DigTrace(Dig.HitPos + (To - From):GetNormalized() * 0.1, To, Filter) -- Try again
            else -- Complete penetration
                local Back = util.TraceLine({
                    start  = Dig.StartPos,
                    endpos = From,
                    mask   = MASK_NPCSOLID_BRUSHONLY, -- Map and brushes only
                })

                -- False positive, still inside the world
                -- Typically occurs when two brushes meet
                if Back.StartSolid or Back.HitNoDraw then
                    return Ballistics.DigTrace(Dig.StartPos + (To - From):GetNormalized() * 0.1, To, Filter)
                end

                return true, Dig.StartPos
            end
        end
    else -- Started inside a brush
        local Back = util.TraceLine({ -- Send a trace backwards to hit the other side
            start  = Dig.HitPos,
            endpos = From + (From - Dig.HitPos):GetNormalized(), -- Countering the initial offset position of the dig trace to handle things <1 inch thick
            mask   = MASK_NPCSOLID_BRUSHONLY, -- Map and brushes only
        })

        if Back.StartSolid then -- object is too thick
            return false
        elseif not Back.Hit or Back.HitNoDraw then
            -- Hit nothing on the way back
            -- Map edge, going into the ground, whatever...
            -- Effectively infinitely thick

            return false
        else -- Penetration
            return true, Back.HitPos
        end
    end
end

function Ballistics.PenetrateMapEntity(Bullet, Trace)
    local Surface = util.GetSurfaceData(Trace.SurfaceProps)
    local Density = ((Surface and Surface.density * 0.5 or 500) * math.Rand(0.9, 1.1)) ^ 0.9 / 10000
    local MaxPen  = Bullet:GetPenetration() -- Base RHA penetration of the projectile
    local RHAe    = math.max(MaxPen / Density, 1) -- RHA equivalent thickness of the target material
    local Enter   = Trace.HitPos -- Impact point
    local Fwd     = Bullet.Flight:GetNormalized()

    local PassThrough = util.TraceLine({
        start  = Enter,
        endpos = Enter + Fwd * RHAe / 25.4,
        mask   = MASK_SOLID_BRUSHONLY
    })

    local Filt = {}
    local Back

    repeat
        Back = util.TraceLine({
            start  = PassThrough.HitPos,
            endpos = Enter,
            filter = Filt
        })

        -- NOTE: Temporary patch for map entity penetration
        -- Sometimes, really short flight projectiles will be processed
        -- after a bounce or penetration of another map entity.
        -- These are created in the air, so no entity is every hit
        -- which leads to an infinite loop.
        if not Back.Hit then return false end

        if Back.HitNonWorld and Back.Entity ~= Trace.Entity then
            Filt[#Filt + 1] = Back.Entity

            continue
        end

        if Back.StartSolid then return Ballistics.DoRicochet(Bullet, Trace) end
    until Back.Entity == Trace.Entity

    local Thickness = (Back.HitPos - Enter):Length() * Density * 25.4 -- Obstacle thickness in RHA

    Bullet.Flight  = Bullet.Flight * (1 - Thickness / MaxPen)
    Bullet.NextPos = Back.HitPos + Fwd * 0.25

    table.insert(Bullet.Filter, Back.Entity)

    return "Penetrated"
end

function Ballistics.PenetrateGround(Bullet, Trace)
    local Surface = util.GetSurfaceData(Trace.SurfaceProps)
    local Density = ((Surface and Surface.density * 0.5 or 500) * math.Rand(0.9, 1.1)) ^ 0.9 / 10000
    local MaxPen  = Bullet:GetPenetration() -- Base RHA penetration of the projectile
    local RHAe    = math.max(MaxPen / Density, 1) -- RHA equivalent thickness of the target material
    local Enter   = Trace.HitPos -- Impact point
    local Fwd     = Bullet.Flight:GetNormalized()

    local Penetrated, Exit = Ballistics.DigTrace(Enter + Fwd, Enter + Fwd * RHAe / 25.4)

    if Penetrated then
        local Thickness = (Exit - Enter):Length() * Density * 25.4 -- RHAe of the material passed through
        local DeltaTime = engine.TickInterval()

        Bullet.Flight  = Bullet.Flight * (1 - Thickness / MaxPen)
        Bullet.Pos     = Exit
        Bullet.NextPos = Exit + Bullet.Flight * ACF.Scale * DeltaTime

        return "Penetrated"
    else -- Ricochet
        return Ballistics.DoRicochet(Bullet, Trace)
    end
end