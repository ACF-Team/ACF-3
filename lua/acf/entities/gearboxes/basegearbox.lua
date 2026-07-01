local ACF         = ACF
local Classes     = ACF.Classes

Classes.DefineClass("ACF.Gearboxes.BaseGearbox", function()
    CLASS.Sound = "buttons/lever7.wav"
    function CLASS.__inherited(NewClass)
        if not NewClass.LimitConVar then
            NewClass.LimitConVar = {
                Name   = "_acf_gearbox",
                Amount = 24,
                Text   = "Maximum amount of ACF gearboxes a player can create."
            }
        end

        Classes.AddSboxLimit(NewClass.LimitConVar)
    end
end)