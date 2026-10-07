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
            func = function( State )
                local Ent = duplicator.CreateEntityFromTable( nil, { Class = "acf_radar", Pos = Vector( 0, 0, 500 ), Angle = Angle() } )
                State.Ents[1] = Ent

                expect( Ent ).to.beValid()
                expect( State.CheckLegal ).was.called( 1 )
                expect( State.CheckLegal.callHistory[1][1] ).to.equal( Ent )
            end
        },

        {
            name = "Menu spawns start the legality checks once",
            func = function( State )
                local _, Ent = ACF.Entities.Spawn( "acf_radar", nil, Vector( 0, 0, 500 ), Angle(), {}, true )
                State.Ents[1] = Ent

                expect( Ent ).to.beValid()
                expect( State.CheckLegal ).was.called( 1 )
            end
        },

        {
            name = "Duplicator spawns store the owner on the entity",
            func = function( State )
                local Owner = player.CreateNextBot( "ACF Legality Test" )
                local Ent = duplicator.CreateEntityFromTable( Owner, { Class = "acf_radar", Pos = Vector( 0, 0, 500 ), Angle = Angle() } )
                State.Ents[1] = Ent
                State.Ents[2] = Owner

                expect( Ent ).to.beValid()
                expect( Ent.Owner ).to.equal( Owner )
            end
        },
    }
}
