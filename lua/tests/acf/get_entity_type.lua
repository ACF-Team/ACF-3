return {
    groupName = "ACF.GetEntityType",

    beforeEach = function( state )
        state.ent = {
            IsPlayer = function() return false end,
            IsNPC = function() return false end,
            IsNextBot = function() return false end,
            IsVehicle = function() return false end
        }
    end,

    cases = {
        {
            name = "Returns 'Prop' by default",
            func = function( state )
                local ent = state.ent

                expect( ACF.GetEntityType( ent ) ).to.equal( "Prop" )
            end
        },

        {
            name = "Returns 'Squishy' for Players",
            func = function( state )
                local ent = state.ent
                ent.IsPlayer = function() return true end

                expect( ACF.GetEntityType( ent ) ).to.equal( "Squishy" )
            end
        },

        {
            name = "Returns 'Squishy' for NPCs",
            func = function( state )
                local ent = state.ent
                ent.IsNPC = function() return true end

                expect( ACF.GetEntityType( ent ) ).to.equal( "Squishy" )
            end
        },

        {
            name = "Returns 'Squishy' for NextBots",
            func = function( state )
                local ent = state.ent
                ent.IsNextBot = function() return true end

                expect( ACF.GetEntityType( ent ) ).to.equal( "Squishy" )
            end
        },

        {
            name = "Returns 'Vehicle' for Vehicles",
            func = function( state )
                local ent = state.ent
                ent.IsVehicle = function() return true end

                expect( ACF.GetEntityType( ent ) ).to.equal( "Vehicle" )
            end
        },
    }
}
