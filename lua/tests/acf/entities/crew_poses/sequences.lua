return {
    groupName = "ACF.CrewPoses",

    beforeEach = function( State )
        State.Ent = ents.Create( "prop_dynamic" )
        State.Ent:SetModel( "models/player/dod_german.mdl" )
        State.Ent:Spawn()
    end,

    afterEach = function( State )
        if IsValid( State.Ent ) then State.Ent:Remove() end
    end,

    cases = {
        {
            name = "Has at least one pose",
            func = function()
                expect( #ACF.Classes.GetSubtypesAsList( "ACF.CrewPoses.BaseCrewPose" ) ).to.beGreaterThan( 0 )
            end
        },

        {
            name = "Every pose has a sequence that exists on the crew player model",
            func = function( State )
                for _, Pose in ipairs( ACF.Classes.GetSubtypesAsList( "ACF.CrewPoses.BaseCrewPose" ) ) do
                    expect( Pose.Sequence ).to.beA( "string" )
                    expect( State.Ent:LookupSequence( Pose.Sequence ) ).to.beGreaterThan( -1 )
                end
            end
        },
    }
}
