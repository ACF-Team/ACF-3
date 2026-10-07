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
    groupName = "ACF entity spawn legality",

    beforeEach = function( State )
        stub( FindMetaTable( "Entity" ), "CPPISetOwner" )
        State.CheckLegal = stub( ACF, "CheckLegal" ).returns( true )
        State.Ents = {}
    end,

    afterEach = function( State )
        for _, Ent in ipairs( State.Ents ) do
            if not IsValid( Ent ) then continue end

            if Ent:IsPlayer() then Ent:Kick() else Ent:Remove() end
        end
    end,

    cases = {
        {
            name = "Duplicator spawns start the legality checks",
            async = true,
            coroutine = true,
            timeout = 10,
            func = function( State )
                WaitForContraption()

                local Ent = duplicator.CreateEntityFromTable( nil, { Class = "acf_radar", Pos = Vector( 0, 0, 500 ), Angle = Angle() } )
                State.Ents[1] = Ent

                expect( Ent ).to.beValid()
                expect( State.CheckLegal ).was.called( 1 )
                expect( State.CheckLegal.callHistory[1][1] ).to.equal( Ent )

                done()
            end
        },

        {
            name = "Menu spawns start the legality checks once",
            async = true,
            coroutine = true,
            timeout = 10,
            func = function( State )
                WaitForContraption()

                local _, Ent = ACF.Entities.Spawn( "acf_radar", nil, Vector( 0, 0, 500 ), Angle(), {}, true )
                State.Ents[1] = Ent

                expect( Ent ).to.beValid()
                expect( State.CheckLegal ).was.called( 1 )

                done()
            end
        },

        {
            name = "Duplicator spawns store the owner on the entity",
            async = true,
            coroutine = true,
            timeout = 10,
            func = function( State )
                WaitForContraption()

                local Owner = player.CreateNextBot( "ACF Legality Test" )
                local Ent = duplicator.CreateEntityFromTable( Owner, { Class = "acf_radar", Pos = Vector( 0, 0, 500 ), Angle = Angle() } )
                State.Ents[1] = Ent
                State.Ents[2] = Owner

                expect( Ent ).to.beValid()
                expect( Ent.Owner ).to.equal( Owner )

                done()
            end
        },
    }
}
