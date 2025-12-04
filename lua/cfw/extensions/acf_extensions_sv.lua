-- Track ACF changes on a contraption
do
    -- Maintain a record in the contraption of its current baseplate
    hook.Add("cfw.contraption.created", "ACF_CFW_Indexing", function(contraption)
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
                ACF.SendNotify(ent:CPPIGetOwner(), false, "A contraption can only have one ACF baseplate. New baseplate removed.")
                ent:Remove()
                return
            end

            contraption.ACF_Baseplate = ent
        end

        if ent.IsACFEntity then
            contraption.ACF_EntitiesCount = math.max(0, contraption.ACF_EntitiesCount + 1)
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