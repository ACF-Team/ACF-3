return {
    groupName = "ACF.IsRecentlyMutated",
    cases = {
        {
            name = "Ignores a non-ACF entity stamped within the ghost time",
            func = function()
                local Ent = { ACF_LastMutated = CurTime(), CFW_GetContraption = function() return nil end }

                expect( ACF.IsRecentlyMutated( Ent ) ).to.beTrue()
            end
        },

        {
            name = "Stops ignoring an entity once the ghost time has passed",
            func = function()
                local Ent = { ACF_LastMutated = CurTime() - ACF.MutationGhostTime - 1, CFW_GetContraption = function() return nil end }

                expect( ACF.IsRecentlyMutated( Ent ) ).to.beFalse()
            end
        },

        {
            name = "Ignores an unstamped entity whose non-ACF contraption was stamped",
            func = function()
                local Contraption = { ACF_LastMutated = CurTime(), ACF_IsACFContraption = function() return false end }
                local Ent         = { CFW_GetContraption = function() return Contraption end }

                expect( ACF.IsRecentlyMutated( Ent ) ).to.beTrue()
            end
        },

        {
            name = "Never ignores ACF entities",
            func = function()
                local Ent = { IsACFEntity = true, ACF_LastMutated = CurTime(), CFW_GetContraption = function() return nil end }

                expect( ACF.IsRecentlyMutated( Ent ) ).to.beFalse()
            end
        },

        {
            name = "Never ignores entities on ACF contraptions",
            func = function()
                local Contraption = { ACF_LastMutated = CurTime(), ACF_IsACFContraption = function() return true end }
                local Ent         = { ACF_LastMutated = CurTime(), CFW_GetContraption = function() return Contraption end }

                expect( ACF.IsRecentlyMutated( Ent ) ).to.beFalse()
            end
        },
    }
}
