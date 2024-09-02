local ACF     = ACF
local Network = ACF.Networking

local acf_debris = GetConVar("acf_debris")

function ACF.CreateDebris(Model, Position, Angles, Velocity)
    if not acf_debris:GetBool() then return end
    if not Model then return end

    local Debris = ents.CreateClientProp(Model)
    Debris:SetPos(Position)
    Debris:SetAngles(Angles)
    Debris:SetMaterial("models/props_pipes/GutterMetal01a")
    Debris:Spawn()
    Debris:SetVelocity(Velocity)

    local ID = "ACF_DebrisWatcher" .. tostring(SysTime())
    timer.Simple(3, function()
        local now = CurTime()
        hook.Add("Think", ID, function()
            local TimeToLive = CurTime() - now
            if TimeToLive >= 1 then
                Debris:Remove()
                hook.Remove("Think", ID)
                return
            end

            -- This is set up this way primarily because of this code, but it won't work for me, so
            -- if someone can figure out why please fix it :)
            -- The color is correct, I checked printing it, it just doesnt like having a color

            --local c = Debris:GetColor()
            --c.a = (1 - TimeToLive) * 255
            --Debris:SetColor(c)
        end)
    end)
end

local EntData = {}

-- Models MIGHT change, but aren't likely to, especially in combat, so rather than running some intensive model checker on entities
-- it would be better to just store it on creation. It's worth a model or two being wrong every now and then for reducing 40+ bytes 
-- into just two bytes when writing the model part of debris
hook.Add("OnEntityCreated", "ACF_Debris_TrackEnts", function(ent)
    timer.Simple(0.001, function()
        if IsValid(ent) then
            local id = ent:EntIndex()
            if id ~= -1 then
                EntData[ent:EntIndex()] = ent:GetModel()
            end
        end
    end)
end)

net.Receive("ACF_Debris", function()
    local EntID    = net.ReadUInt(14)
    local Position = Network.ReadGrainyVector(12)
    local Angles   = Network.ReadGrainyAngle(8)
    local Normal   = Network.ReadGrainyVector(8, 1)
    local Power    = net.ReadUInt(16)

    ACF.CreateDebris(
        EntData[EntID],
        Position,
        Angles,
        Normal * Power
    )
end)