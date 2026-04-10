ACF.Class("ACF.Baseplates.AircraftBaseplate", "ACF.Baseplates.BaseplateType", function()
    CLASS.Name        = "Aircraft"
    CLASS.Icon        = "icon16/weather_clouds.png"
    CLASS.Description = "A baseplate designed for aircraft."

    function CLASS:OnInitialize(Entity)
        Entity:SetCollisionGroup(COLLISION_GROUP_WORLD)
    end

    function CLASS:PhysicsCollide(Entity, Data)
        self:PhysicsCollideExplosion(Entity, Data)
    end
end)