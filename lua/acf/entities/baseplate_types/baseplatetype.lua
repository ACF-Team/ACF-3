local Clock 	= ACF.Utilities.Clock
local LastBaseplateExplosions = {}
local TIME_BETWEEN_HE_EXPLOSIONS_PER_PLAYER = 10

ACF.Class("ACF.Baseplates.BaseplateType", function()
    function CLASS.PhysicsCollideExplosion(Entity, Data)
        local Contraption = Entity:GetContraption()
        if not Contraption then return end

        if Data.HitEntity:GetContraption() == Contraption then return end
        if Data.Speed > 1000 then
            local Owner       = Entity:CPPIGetOwner()
            local WillExplode = true
            if IsValid(Owner) then -- I don't even think this could happen...
                local Now         = Clock.CurTime
                local LastTime    = LastBaseplateExplosions[Owner]
                WillExplode = LastTime == nil or (Now - LastTime) > TIME_BETWEEN_HE_EXPLOSIONS_PER_PLAYER
                LastBaseplateExplosions[Owner] = Now
            end

            -- Timer simple to avoid "Changing collision rules within a callback is likely to cause crashes!"
            timer.Simple(0, function()
                local Position = IsValid(Entity) and Entity:GetPos() or nil
                for Player in ACF.PlayersInContraptionIterator(Contraption) do
                    Player:Kill()
                end

                for Entity in pairs(Contraption.ents) do
                    ACF.HEKill(Entity, Data.HitNormal, Data.Speed * 100, Data.HitPos, nil, true)
                end

                if WillExplode and Position then
                    ACF.Damage.explosionEffect(Position, Data.HitNormal, 120)
                end
            end)
        end
    end
end)