local Notify = ACF.Utilities.Notify

-- Track ACF changes on a contraption
do
    -- Maintain a record in the contraption of its current baseplate
    hook.Add("cfw.contraption.init", "ACF_CFW_Indexing", function(contraption)
        contraption.ACF_EntitiesCount = 0
    end)

    hook.Add("cfw.contraption.entityAdded", "ACF_CFW_Indexing", function(contraption, ent)
        local Class = ent:GetClass()

        if Class == "acf_baseplate" then
            -- I don't think ent == contraption.ACF_Baseplate would *ever* happen,
            -- but at the same time, if ACF_Baseplate == ent, then it's still a valid
            -- scenario since there's still only one baseplate. Maybe this is too paranoid.
            if IsValid(contraption.ACF_Baseplate) and ent ~= contraption.ACF_Baseplate then
                -- Destroy the new one! We can't have more than one on a contraption
                -- Warn on the baseplate that won't be destroyed... otherwise not really a point to using EntityWarning
                Notify.EntityWarning(contraption.ACF_Baseplate, "A contraption can only have one ACF baseplate. New baseplate removed.")
                ent:Remove()
                return
            end

            contraption.ACF_Baseplate = ent
        end

        if ent.IsACFEntity then
            contraption.ACF_EntitiesCount = math.max(0, contraption.ACF_EntitiesCount + 1)
            hook.Run("ACF_OnPostACFEntityAddedToContraption", contraption, ent)
        end
    end)

    hook.Add("cfw.contraption.entityRemoved", "ACF_CFW_Deindexing", function(contraption, ent)
        local Class = ent:GetClass()

        if Class == "acf_baseplate" then
            contraption.ACF_Baseplate = nil
        end

        if ent.IsACFEntity then
            contraption.ACF_EntitiesCount = math.max(0, contraption.ACF_EntitiesCount - 1)
        end
    end)

    -- When two contraptions merge, transfer ACF data from the absorbed contraption
    hook.Add("cfw.contraption.merged", "ACF_CFW_Indexing", function(absorbed, into)
        into.ACF_EntitiesCount = (into.ACF_EntitiesCount or 0) + (absorbed.ACF_EntitiesCount or 0)

        -- Transfer baseplate if the target doesn't have one
        if not IsValid(into.ACF_Baseplate) and IsValid(absorbed.ACF_Baseplate) then
            into.ACF_Baseplate = absorbed.ACF_Baseplate
        end
    end)

    -- When a contraption splits, the child contraption needs its data recalculated
    -- ACF_EntitiesCount and ACF_Baseplate are rebuilt from the entities that moved
    hook.Add("cfw.contraption.split", "ACF_CFW_Indexing", function(parent, child)
        child.ACF_EntitiesCount = 0

        for ent in pairs(child.ents) do
            if ent:GetClass() == "acf_baseplate" then
                child.ACF_Baseplate = ent
            end

            if ent.IsACFEntity then
                child.ACF_EntitiesCount = child.ACF_EntitiesCount + 1
            end
        end

        -- Recalculate parent's ACF_EntitiesCount (entities were moved out)
        parent.ACF_EntitiesCount = 0

        for ent in pairs(parent.ents) do
            if ent:GetClass() == "acf_baseplate" and not IsValid(parent.ACF_Baseplate) then
                parent.ACF_Baseplate = ent
            end

            if ent.IsACFEntity then
                parent.ACF_EntitiesCount = parent.ACF_EntitiesCount + 1
            end
        end
    end)
end

-- ACF contraption methods
do
    local CONTRAPTION     = CFW.Classes.Contraption

    function CONTRAPTION:ACF_IsACFContraption()
        return self.ACF_EntitiesCount > 0
    end

    function CONTRAPTION:ACF_GetContraptionType()
        local Baseplate = self.ACF_Baseplate
        if not IsValid(Baseplate) then return "" end -- We have no way of knowing...
        return Baseplate:ACF_GetUserVar("BaseplateType").ID
    end

    function CONTRAPTION:ACF_IsGroundVehicle()
        local Baseplate = self.ACF_Baseplate
        if not IsValid(Baseplate) then return false end -- We have no way of knowing...
        return Baseplate:ACF_GetUserVar("BaseplateType").ID == "GroundVehicle"
    end

    function CONTRAPTION:ACF_IsAircraft()
        local Baseplate = self.ACF_Baseplate
        if not IsValid(Baseplate) then return false end -- We have no way of knowing...
        return Baseplate:ACF_GetUserVar("BaseplateType").ID == "Aircraft"
    end

    function CONTRAPTION:ACF_IsRecreational()
        local Baseplate = self.ACF_Baseplate
        if not IsValid(Baseplate) then return false end -- We have no way of knowing...
        return Baseplate:ACF_GetUserVar("BaseplateType").ID == "Recreational"
    end

    -- todo
    --function CONTRAPTION:ACF_IsLethal()
    --end
end