-- Purpose: Block crewed contraptions that have had their crew killed from being able to be entered again.
local ACF = ACF

hook.Add("CanPlayerEnterVehicle", "ACF_CanPlayerEnterVehicle_BlockEnterVehicleOnDeadContraption", function(Player, Vehicle)
    if not IsValid(Vehicle) then return end

    local Contraption = Vehicle:GetContraption()
    if not Contraption then return end

    local Now = CurTime()

    if Contraption.ACF_AllCrewKilled then
        if (Now - (Contraption.ACF_LastNotifyDeathTime or 0)) > 1 then
            ACF.SendNotify(Player, false, "This contraption is no longer usable.")
            Contraption.ACF_LastNotifyDeathTime = Now
        end

        return false
    end
end)
