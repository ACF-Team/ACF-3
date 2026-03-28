-- Purpose: Block crewed contraptions that have had their crew killed from being able to be entered again.
local ACF = ACF
local Notify = ACF.Utilities.Notify

hook.Add("CanPlayerEnterVehicle", "ACF_CanPlayerEnterVehicle_BlockEnterVehicleOnDeadContraption", function(Player, Vehicle)
    if not IsValid(Vehicle) then return end

    local Contraption = Vehicle:GetContraption()
    if not Contraption then return end

    local Now = CurTime()

    if Contraption.ACF_AllCrewKilled then
        if (Now - (Contraption.ACF_LastNotifyDeathTime or 0)) > 1 then
            Notify.Start()
            Notify.WithTitle("This contraption is no longer usable.")
            Notify.WithSilkIcon("error")
            Notify.WithTargetEntity(Contraption.ACF_Baseplate)
            Notify.WithDescription("All crew members have been killed.")
            Notify.AddPlayer(Player)
            Notify.Transmit()
            Contraption.ACF_LastNotifyDeathTime = Now
        end

        return false
    end
end)
