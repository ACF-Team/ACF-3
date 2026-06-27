local ACF       = ACF
local Classes   = ACF.Classes

Classes.DefineClass("ACF.Components.BaseComponent", function()
    function CLASS.__inherited(NewClass)
        if not NewClass.LimitConVar then
            NewClass.LimitConVar = {
                Name   = "_acf_misc",
                Amount = 32,
                Text   = "Maximum amount of ACF components a player can create."
            }
        end

        Classes.AddSboxLimit(NewClass.LimitConVar)
    end
end)

-- This isn't actually related to components, but it doesn't have its own unique place to go...
Classes.AddSboxLimit({
    Name   = "_acf_controller",
    Amount = 6,
    Text   = "Maximum amount of ACF controllers a player can create."
})