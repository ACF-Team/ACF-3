return {
    groupName = "ACF entity spawn errors",

    beforeEach = function( State )
        State.Stored = scripted_ents.GetStored( "acf_radar" ).t
        State.PreSpawn = State.Stored.ACF_PreSpawn
    end,

    afterEach = function( State )
        State.Stored.ACF_PreSpawn = State.PreSpawn
    end,

    cases = {
        {
            name = "Removes the entity if it errors while initializing",
            func = function( State )
                local Create = ents.Create
                local Created

                stub( ents, "Create" ).with( function( ... )
                    Created = Create( ... )
                    return Created
                end )
                stub( _G, "ErrorNoHaltWithStack" )

                State.Stored.ACF_PreSpawn = function() error( "Test error" ) end

                local Success, Reason = ACF.Entities.Spawn( "acf_radar", nil, Vector(), Angle(), {} )

                expect( Success ).to.beFalse()
                expect( Reason ).to.beA( "string" )
                expect( Created ).to.exist()
                expect( Created:IsMarkedForDeletion() ).to.beTrue()
            end
        },

        {
            name = "Reports the error",
            func = function( State )
                local Report = stub( _G, "ErrorNoHaltWithStack" )

                State.Stored.ACF_PreSpawn = function() error( "Test error" ) end

                ACF.Entities.Spawn( "acf_radar", nil, Vector(), Angle(), {} )

                expect( Report ).was.called()
            end
        },
    }
}
