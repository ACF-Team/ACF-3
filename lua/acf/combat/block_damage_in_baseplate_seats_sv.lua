local ACF = ACF
local BlockDamageHook = false

-- Purpose: Make players invincible while in ACF baseplate seats.
-- We don't want other damage systems to interact with ACF combat.
-- Deaths instead will happen when the crew dies.
hook.Add("EntityTakeDamage", "ACF_EntityTakeDamage_BlockDamageInBaseplateSeats", function(Target, _)
    if BlockDamageHook then return end -- To avoid crashes/allow ACF to stop damage for a bit
    if ACF.AllowBaseplateDamage then return end

    if not Target:IsPlayer() then return end
    if not Target:InVehicle() then return end

    local Vehicle = Target:GetVehicle()
    if not IsValid(Vehicle) then return end

    local Contraption = Vehicle:CFW_GetContraption()
    if not Contraption then return end

    local Base = Contraption.ACF_Baseplate
    if IsValid(Base) then
        return true -- Block damage, because there's a contraption, with a baseplate
    end
end)

function ACF.RunFunctionWhileBlockingBPSeatDamage(Fn, ...)
    BlockDamageHook = true
    Fn(...)
    BlockDamageHook = false
end