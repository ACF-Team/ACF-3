-- Resolves issues with properClipping
-- Triggers an ACF.Activate update whenever a new clip is created

local timerSimple = timer.Simple

local function activate(ent)
    if ent._ACF_PropperClipping then return end

    ent._ACF_PropperClipping = true

    timerSimple(engine.TickInterval() * 2, function()
        if not IsValid(ent) then return end

        print("Pclip", ent)
        ent._ACF_PropperClipping = nil

        ACF.Activate(ent, true)
    end)
end

hook.Add("ProperClippingClipAdded", "ACF", activate)
hook.Add("ProperClippingClipRemoved", "ACF", activate)