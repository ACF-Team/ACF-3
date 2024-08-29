local ACF       = ACF
local Effects   = ACF.Utilities.Effects

do
    --- Creates effects based on util.Effect with ACF-specific functionality.
    --- @param EffectName string The name of the effect to create
    --- @param EffectTable table The table containing all of the parameters for the effect (case-sensitive)
    --- @param AllowOverride? boolean Whether Lua-defined effects should override engine-defined effects
    --- @param Filter? any Can be either a boolean to ignore the prediction filter or a CRecipientFilter
    function Effects.CreateEffect(EffectName, EffectTable, AllowOverride, Filter)
        if not EffectName or not EffectTable then return end

        local Effect = EffectData()

        local NewName, NewTable = hook.Run("ACF_PreCreateEffect", EffectName, EffectTable)
        EffectName = NewName or EffectName
        EffectTable = NewTable or EffectTable

        -- Set values for all possible valid CEffectData attributes present in EffectTable
        for Name, Value in pairs(EffectTable) do
            local EffectFunc = Effect["Set" .. Name]
            if not EffectFunc then continue end

            EffectFunc(Effect, Value)
        end

        util.Effect(EffectName, Effect, AllowOverride, Filter)
    end
end