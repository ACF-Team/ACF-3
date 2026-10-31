-- Bullets hitting the map: digging through it, map entities and ricochets
-- Shared so the owner's client can work out what its predicted bullets do when they hit the map, see ballistics_cl.lua
local ACF        = ACF
ACF.Ballistics   = ACF.Ballistics or {}

local Ballistics = ACF.Ballistics
local Debug		 = ACF.Debug

do -- Random rolls --------------------------------
    -- Predicted bullets roll the same numbers on the server and on the owner's client, from their PredictionID
    -- and how many times they hit the map. Every other bullet rolls normally
    local function Roll(Bullet, Key)
        return tonumber(util.CRC(Bullet.PredictionID .. ":" .. (Bullet.WorldHits or 0) .. ":" .. Key)) / 4294967296
    end

    -- Same as math.Rand
    function Ballistics.Random(Bullet, Key, Min, Max)
        if not Bullet.PredictionID then return math.Rand(Min, Max) end

        return Min + (Max - Min) * Roll(Bullet, Key)
    end

    -- Same as math.random(Min, Max), which takes non-integer bounds too
    function Ballistics.RandomInt(Bullet, Key, Min, Max)
        if not Bullet.PredictionID then return math.random(Min, Max) end

        return math.floor(Roll(Bullet, Key) * (Max - Min + 1)) + Min
    end

    -- Same as VectorRand
    function Ballistics.RandomVector(Bullet, Key)
        if not Bullet.PredictionID then return VectorRand() end

        return Vector(Roll(Bullet, Key .. "X") * 2 - 1, Roll(Bullet, Key .. "Y") * 2 - 1, Roll(Bullet, Key .. "Z") * 2 - 1)
    end
end

do -- Ricochets -----------------------------------
    function Ballistics.GetRicochetVector(Flight, HitNormal)
        local Normal = Flight:GetNormalized()

        return Normal - (2 * Normal:Dot(HitNormal)) * HitNormal
    end

    -- Re-seeds a bullet's flight after a ricochet and resets Pos/NextPos/TraceTo so the immediate
    -- re-trace this tick (triggered by OnImpact's "Ricochet" branch) starts from the ricochet point.
    -- Speed is unscaled (real-world) velocity; Spread is the VectorRand jitter magnitude.
    function Ballistics.ApplyRicochet(Bullet, Position, HitNormal, Speed, Ricochet, Spread, DeltaTime)
        local Direction = Ballistics.GetRicochetVector(Bullet.Flight, HitNormal) + Ballistics.RandomVector(Bullet, "RicochetSpread") * Spread
        local Flight    = Direction:GetNormalized() * Speed * Ricochet * ACF.Scale

        Bullet.Flight  = Flight
        Bullet.Pos     = Position
        Bullet.NextPos = Position + Flight * DeltaTime
        Bullet.TraceTo = Position + Flight * (DeltaTime * 2)
    end

    function Ballistics.DoRicochet(Bullet, Trace)
        local HitAngle = ACF.GetHitAngle(Trace, Bullet.Flight)
        local Speed    = Bullet.Flight:Length() / ACF.Scale
        local MinAngle = math.min(Bullet.Ricochet - Speed / ACF.MeterToInch / 30 + 20, 89.9) -- Making the chance of a ricochet get higher as the speeds increase
        local Ricochet = 0

        if HitAngle < 89.9 and HitAngle > Ballistics.RandomInt(Bullet, "Ricochet", MinAngle, 90) then -- Checking for ricochet
            Ricochet = HitAngle / 90 * 0.75
        end

        if Ricochet > 0 and Bullet.GroundRicos < 2 then
            local DeltaTime = engine.TickInterval()

            Bullet.GroundRicos = Bullet.GroundRicos + 1

            Ballistics.ApplyRicochet(Bullet, Trace.HitPos, Trace.HitNormal, Speed, Ricochet, 0.05, DeltaTime)

            return "Ricochet"
        end

        return false
    end
end

function Ballistics.DigTrace(From, To, Filter)
    local Dig = util.TraceLine({
        start  = From,
        endpos = To,
        mask   = MASK_NPCSOLID_BRUSHONLY, -- Map and brushes only
    })

    if Debug.SetDeveloperLevel(1) then
        Debug.Line(From, Dig.StartPos, 30, ColorRand(100, 255), true)
    end

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
            return true, Dig.StartPos
        end
    end
end

-- Shared penetration budget setup: density-derived RHA-equivalent thickness this bullet can still punch through.
function Ballistics.GetPenetrationSetup(Bullet, Trace)
    local Surface = util.GetSurfaceData(Trace.SurfaceProps)
    local Density = ((Surface and Surface.density * 0.5 or 500) * Ballistics.Random(Bullet, "Density", 0.9, 1.1)) ^ 0.9 / 10000
    local MaxPen  = Bullet:GetPenetration() -- Base RHA penetration of the projectile
    local RHAe    = math.max(MaxPen / Density, 1) -- RHA equivalent thickness of the target material
    local Enter   = Trace.HitPos -- Impact point
    local Fwd     = Bullet.Flight:GetNormalized()

    return Density, MaxPen, RHAe, Enter, Fwd
end

function Ballistics.PenetrateMapEntity(Bullet, Trace)
    Bullet.WorldHits = (Bullet.WorldHits or 0) + 1 -- Keeps the rolls of every map hit different

    local Density, MaxPen, RHAe, Enter, Fwd = Ballistics.GetPenetrationSetup(Bullet, Trace)

    local PassThrough = util.TraceLine({
        start  = Enter,
        endpos = Enter + Fwd * RHAe / ACF.InchToMm,
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

    local Thickness = (Back.HitPos - Enter):Length() * Density * ACF.InchToMm -- Obstacle thickness in RHA

    Bullet.Flight  = Bullet.Flight * (1 - Thickness / MaxPen)
    Bullet.NextPos = Back.HitPos + Fwd * 0.25

    table.insert(Bullet.Filter, Back.Entity)

    return "Penetrated"
end

function Ballistics.PenetrateGround(Bullet, Trace)
    Bullet.WorldHits = (Bullet.WorldHits or 0) + 1 -- Keeps the rolls of every map hit different

    local Density, MaxPen, RHAe, Enter, Fwd = Ballistics.GetPenetrationSetup(Bullet, Trace)

    local Penetrated, Exit = Ballistics.DigTrace(Enter + Fwd, Enter + Fwd * RHAe / ACF.InchToMm)

    if Penetrated then
        local Thickness = (Exit - Enter):Length() * Density * ACF.InchToMm -- RHAe of the material passed through
        local DeltaTime = engine.TickInterval()

        Bullet.Flight  = Bullet.Flight * (1 - Thickness / MaxPen)
        Bullet.Pos     = Exit
        Bullet.NextPos = Exit + Bullet.Flight * ACF.Scale * DeltaTime

        return "Penetrated"
    else -- Ricochet
        return Ballistics.DoRicochet(Bullet, Trace)
    end
end