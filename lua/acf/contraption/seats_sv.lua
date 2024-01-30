-- Optional functionality for legality checking on all vehicles

hook.Add("OnEntityCreated", "ACF_SeatLegality", function(Entity)
    timer.Simple(0, function()
        if not IsValid(Entity) then return end
        if Entity:GetClass() ~= "prop_vehicle_prisoner_pod" then return end
        if not Entity.VehicleTable then return end -- Some vehicles like simfphys/WAC/Sit Anywhere will make non-solid seats that should be ignored

        local PhysObj = Entity:GetPhysicsObject()
        if not IsValid(PhysObj) then return end

        Entity.ACF = {}
        Entity.ACF.PhysObj = PhysObj
        Entity.ACF.LegalMass = PhysObj:GetMass()
        Entity.ACF.Model = Entity:GetModel()
        Entity.ACF.LegalSeat = true
        Entity.WireDebugName = Entity.WireDebugName or Entity.VehicleTable.Name or "ACF Legal Vehicle"

        Entity.Enable = function()
            Entity.ACF.LegalSeat = true
        end

        Entity.Disable = function()
            Entity.ACF.LegalSeat = false

            local Driver = Entity:GetDriver()
            if not IsValid(Driver) then return end
            Driver:ExitVehicle()
        end

        if not ACF.VehicleLegalChecks then return end

        ACF.CheckLegal(Entity)
    end)
end)

hook.Add("CanPlayerEnterVehicle", "ACF_SeatLegality", function(Player, Entity)
    if not Entity.ACF then return end

    if not Entity.ACF.LegalSeat then
        ACF.SendNotify(Player, false, "[ACF] Seat is not legal and is currently disabled.")
        return false
    end
end)