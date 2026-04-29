local ACF      		= ACF

ACF.AddInputAction("acf_baseplate", "Unflip", function(Entity, Value)
    if Value == 0 then return end

    local LastFlipped = Entity.LastFlipped or 0
    if Value == 0 or CurTime() - LastFlipped < 10 then return end -- Only flip every 10 seconds to prevent spam
    Entity.LastFlipped = CurTime()

    local Physicals = constraint.GetAllConstrainedEntities(Entity)

    local NewPosition = Entity:GetPos() + Vector(0, 0, 100)
    local NewAngles = Angle(Entity:GetAngles().p, Entity:GetAngles().y, 0)

    local LocalPositions = {}
    local LocalAngles = {}

    local Contraption = Entity:CFW_GetContraption()
    if Contraption then Contraption.IsPickedUp = true end

    local ShouldNotReposition = {}

    for v in pairs(Physicals) do
        if not IsValid(v) then continue end
        local Phys = v:GetPhysicsObject()
        if not IsValid(Phys) then continue end

        if not Phys:IsMotionEnabled() then ShouldNotReposition[v] = true end
        if not Phys:IsGravityEnabled() then ShouldNotReposition[v] = true end
    end

    for v in pairs(Physicals) do
        if not IsValid(v) then continue end
        local Phys = v:GetPhysicsObject()
        if not IsValid(Phys) then continue end

        Phys:EnableMotion(false)
        Phys:Wake()
    end

    for v in pairs(Physicals) do
        if not IsValid(v) then continue end
        LocalPositions[v] = Entity:WorldToLocal(v:GetPos())
        LocalAngles[v] = Entity:WorldToLocalAngles(v:GetAngles())
    end

    timer.Simple(1, function()
        Entity:SetPos(NewPosition)
        Entity:SetAngles(NewAngles)

        for v in pairs(Physicals) do
            if not IsValid(v) then continue end
            if not ShouldNotReposition[v] then v:SetPos(Entity:LocalToWorld(LocalPositions[v])) end
            v:SetAngles(Entity:LocalToWorldAngles(LocalAngles[v]))
        end

        timer.Simple(1, function()
            for v in pairs(Physicals) do
                if not IsValid(v) then continue end
                local Phys = v:GetPhysicsObject()
                if not IsValid(Phys) then continue end

                Phys:EnableMotion(true)
                Phys:Wake()
            end

            if Contraption then Contraption.IsPickedUp = false end
        end)
    end)
end)