-- Optional functionality for legality checking on all vehicles

-- A whitelist of allowed seats, prevents setting your seat to something with a microscopic physics object
local ValidSeatModels = {
    -- Default HL2 seats
    ["models/nova/airboat_seat.mdl"] = true,
    ["models/nova/chair_office02.mdl"] = true,
    ["models/props_phx/carseat2.mdl"] = true,
    ["models/props_phx/carseat2.mdl"] = true,
    ["models/props_phx/carseat3.mdl"] = true,
    ["models/props_phx/carseat2.mdl"] = true,
    ["models/nova/chair_plastic01.mdl"] = true,
    ["models/nova/jeep_seat.mdl"] = true,
    ["models/nova/chair_office01.mdl"] = true,
    ["models/nova/chair_wood01.mdl"] = true,
    ["models/vehicles/prisoner_pod_inner.mdl"] = true,

    -- ACF default seats
    ["models/vehicles/driver_pod.mdl"] = true,
    ["models/vehicles/pilot_seat.mdl"] = true,

    -- Playerstart seats
    ["models/chairs_playerstart/airboatpose.mdl"] = true,
    ["models/chairs_playerstart/jeeppose.mdl"] = true,
    ["models/chairs_playerstart/podpose.mdl"] = true,
    ["models/chairs_playerstart/sitposealt.mdl"] = true,
    ["models/chairs_playerstart/pronepose.mdl"] = true,
    ["models/chairs_playerstart/sitpose.mdl"] = true,
    ["models/chairs_playerstart/standingpose.mdl"] = true,

    -- Racing seats
    ["models/lubprops/seat/raceseat.mdl"] = true,
    ["models/lubprops/seat/raceseat2.mdl"] = true,

    -- Crew Seats
    ["models/liddul/crewseat.mdl"] = true,
}

ACF.ValidSeatModels = ValidSeatModels

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
        Entity.ACF.Model = Entity.VehicleTable.Model or Entity:GetModel()
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

hook.Add("ACF_IsLegal", "ACF_CheckLegal_SeatLegality", function(Entity)
    if not ACF.VehicleLegalChecks then return end
    if not Entity:IsVehicle() then return end

    local ModelPath = Entity:GetModel()

    if not ValidSeatModels[ModelPath] and ModelPath ~= Entity.VehicleTable.Model then
        return false, "Bad Seat Model", "This seat model is not on the whitelist."
    end
end)

hook.Add("CanPlayerEnterVehicle", "ACF_SeatLegality", function(Player, Entity)
    if not ACF.VehicleLegalChecks or not Entity.ACF then return end

    local IsLegal, Reason = ACF.IsLegal(Entity)
    if IsLegal then return end

    Reason = Reason or "Reason not found."

    ACF.SendNotify(Player, false, "[ACF] Seat is not legal and is currently disabled. (" .. Reason .. ")")

    return false
end)
