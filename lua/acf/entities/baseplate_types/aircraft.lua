local Types     = ACF.Classes.BaseplateTypes
local Baseplate = Types.Register("Aircraft")

function Baseplate:OnLoaded()
    self.Name		 = "Aircraft"
    self.Icon        = "icon16/weather_clouds.png"
    self.Description = "A baseplate designed for aircraft."
end

function Baseplate:OnInitialize()
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
end

function Baseplate:PhysicsCollide(Data)
    local Contraption = self:GetContraption()
    if not Contraption then return end

    if Data.HitEntity:GetContraption() == Contraption then return end
    if Data.Speed > 1000 then
        -- Timer simple to avoid "Changing collision rules within a callback is likely to cause crashes!"
        timer.Simple(0, function()
            local Position = IsValid(self) and self:GetPos() or nil
            for Player in ACF.PlayersInContraptionIterator(Contraption) do
                Player:Kill()
            end
            for Entity in pairs(Contraption.ents) do
                ACF.HEKill(Entity, Data.HitNormal, Data.Speed * 100, Data.HitPos, nil, true)
            end
            if Position then
                ACF.Damage.explosionEffect(Position, Data.HitNormal, 120)
            end
        end)
    end
end