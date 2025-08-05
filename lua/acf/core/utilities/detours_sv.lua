-- -- Registers a bunch of legality detours.

-- local Detours = ACF.Detours

-- timer.Simple(Detours.Loaded and 0 or 5, function()
--     Detours.Loaded = true

--     local E2_SetPos E2_SetPos = Detours.Expression2("e:setPos(v)", function(Scope, Args, ...)
--         return E2_SetPos(Scope, Args, ...)
--     end)

--     local SF_SetPos SF_SetPos = Detours.Starfall("instance.Types.Entity.Methods.setPos", function(_, Entity, Pos, ...)
--         return SF_SetPos(Entity, Pos, ...)
--     end)

--     print("ACF detours loaded...") -- I forgot the print function :) note to self to find it
-- end)