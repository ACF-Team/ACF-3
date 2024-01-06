return {
    groupName = "ACF.Ballistics.GetImpactType",
    cases = {
        {
            name = "Returns World if impacting the World",
            func = function()
                local Trace = { HitWorld = true }
                local Entity = {}

                local Type = ACF.Ballistics.GetImpactType( Trace, Entity )
                expect( Type ).to.equal( "World" )
            end
        },

        {
            name = "Returns Prop if impacting a Player Entity",
            func = function()
                local Trace = {}
                local Entity = {
                    IsPlayer = stub().returns( true ),
                    IsNPC = stub().returns( false )
                }

                local Type = ACF.Ballistics.GetImpactType( Trace, Entity )
                expect( Type ).to.equal( "Prop" )
            end
        },

        {
            name = "Returns Prop if impacting an NPC Entity",
            func = function()
                local Trace = {}
                local Entity = {
                    IsPlayer = stub().returns( false ),
                    IsNPC = stub().returns( true )
                }

                local Type = ACF.Ballistics.GetImpactType( Trace, Entity )
                expect( Type ).to.equal( "Prop" )
            end
        },

        {
            name = "Returns Prop if impacting a player-owned Entity",
            func = function()
                local Trace = {}
                local Entity = {
                    IsPlayer = stub().returns( false ),
                    IsNPC = stub().returns( false ),
                    CPPIGetOwner = function()
                        return { IsValid = stub().returns( true ) }
                    end
                }

                local Type = ACF.Ballistics.GetImpactType( Trace, Entity )
                expect( Type ).to.equal( "Prop" )
            end
        },

        {
            name = "Returns World if impacting a world-owned Entity",
            func = function()
                local Trace = {}
                local Entity = {
                    IsPlayer = stub().returns( false ),
                    IsNPC = stub().returns( false ),
                    CPPIGetOwner = function()
                        return { IsValid = stub().returns( false ) }
                    end
                }

                local Type = ACF.Ballistics.GetImpactType( Trace, Entity )
                expect( Type ).to.equal( "World" )
            end
        }
    }
}
