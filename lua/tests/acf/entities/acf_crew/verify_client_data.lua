local function WaitForContraption()
    if ACF.Contraption.SetModel then return end

    local Co = coroutine.running()

    timer.Create( "ACF Tests Wait For Contraption", 0, 0, function()
        if not ACF.Contraption.SetModel then return end

        timer.Remove( "ACF Tests Wait For Contraption" )
        coroutine.resume( Co )
    end )

    coroutine.yield()
end

return {
    groupName = "acf_crew:ACF_OnVerifyClientData",

    beforeEach = function( State )
        State.Verify = scripted_ents.GetStored( "acf_crew" ).t.ACF_OnVerifyClientData
    end,

    cases = {
        {
            name = "Keeps valid crew type, model and pose IDs",
            func = function( State )
                local Data = { CrewTypeID = "Gunner", CrewModelID = "StandingLarge", CrewPoseID = "WalkCamera" }

                State.Verify( Data )

                expect( Data.CrewTypeID ).to.equal( "Gunner" )
                expect( Data.CrewModelID ).to.equal( "StandingLarge" )
                expect( Data.CrewPoseID ).to.equal( "WalkCamera" )
            end
        },

        {
            name = "Replaces an unknown crew type with Commander",
            func = function( State )
                local Data = { CrewTypeID = "NotACrewType" }

                State.Verify( Data )

                expect( Data.CrewTypeID ).to.equal( "Commander" )
            end
        },

        {
            name = "Replaces a crew type with the wrong casing",
            func = function( State )
                local Data = { CrewTypeID = "gunner" }

                State.Verify( Data )

                expect( Data.CrewTypeID ).to.equal( "Commander" )
            end
        },

        {
            name = "Replaces an unknown crew model with Sitting",
            func = function( State )
                local Data = { CrewModelID = "NotAModel" }

                State.Verify( Data )

                expect( Data.CrewModelID ).to.equal( "Sitting" )
            end
        },

        {
            name = "Clears an unknown crew pose",
            func = function( State )
                local Data = { CrewPoseID = "NotAPose" }

                State.Verify( Data )

                expect( Data.CrewPoseID ).to.equal( "" )
            end
        },

        {
            name = "Leaves missing IDs untouched",
            func = function( State )
                local Data = {}

                State.Verify( Data )

                expect( Data.CrewTypeID ).to.beNil()
                expect( Data.CrewModelID ).to.beNil()
                expect( Data.CrewPoseID ).to.beNil()
            end
        },

        {
            name = "A spawned crew with an unknown type uses a valid type ID",
            async = true,
            coroutine = true,
            timeout = 10,
            func = function()
                WaitForContraption()

                stub( FindMetaTable( "Entity" ), "CPPISetOwner" )

                local Crew = ACF.Entities.DoSpawnInternal( "acf_crew", nil, Vector(), Angle(), { CrewTypeID = "Junk" } )

                expect( Crew ).to.beValid()
                expect( Crew.CrewTypeID ).to.equal( "Commander" )
                expect( Crew:GetCrewType() ).to.equal( ACF.Classes.GetTypeByName( "ACF.CrewTypes.Commander" ) )

                Crew:Remove()

                done()
            end
        },
    }
}
