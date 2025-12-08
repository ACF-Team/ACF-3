local Controls = ACF.MenuControls or {}
ACF.MenuControls = Controls

function ACF.DefineControl(Name, Desc, Def, Base)
    -- This gives us an opportunity later to inject things into these definitions, if we need to do that...
    -- (although we should avoid that where possible)
    -- I made sure to confirm against Lua execution order that autorun runs before vgui as well.
    derma.DefineControl(Name, Desc, Def, Base)
end
