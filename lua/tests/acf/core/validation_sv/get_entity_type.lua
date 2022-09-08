return {
    groupName = "ACF.GetEntityType",

    beforeEach = function( State )
        State.Ent = {
            IsPlayer = function() return false end,
            IsNPC = function() return false end,
            IsNextBot = function() return false end,
            IsVehicle = function() return false end
        }
    end,

    cases = {
        {
            name = "Returns 'Prop' by default",
            func = function( State )
                local Ent = State.Ent

                expect( ACF.GetEntityType( Ent ) ).to.equal( "Prop" )
            end
        },

        {
            name = "Returns 'Squishy' for Players",
            func = function( State )
                local Ent = State.Ent
                Ent.IsPlayer = function() return true end

                expect( ACF.GetEntityType( Ent ) ).to.equal( "Squishy" )
            end
        },

        {
            name = "Returns 'Squishy' for NPCs",
            func = function( State )
                local Ent = State.Ent
                Ent.IsNPC = function() return true end

                expect( ACF.GetEntityType( Ent ) ).to.equal( "Squishy" )
            end
        },

        {
            name = "Returns 'Squishy' for NextBots",
            func = function( State )
                local Ent = State.Ent
                Ent.IsNextBot = function() return true end

                expect( ACF.GetEntityType( Ent ) ).to.equal( "Squishy" )
            end
        },

        {
            name = "Returns 'Vehicle' for Vehicles",
            func = function( State )
                local Ent = State.Ent
                Ent.IsVehicle = function() return true end

                expect( ACF.GetEntityType( Ent ) ).to.equal( "Vehicle" )
            end
        },
    }
}
