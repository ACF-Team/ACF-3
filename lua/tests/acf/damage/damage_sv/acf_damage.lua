return {
    groupName = "ACF.Damage",

    beforeEach = function( state )
        state.ent = {}
        state.trace = { Entity = state.ent }

        state.originalCanDamage = ACF.Permissions.CanDamage
        hook.Remove( "ACF_BulletDamage", "ACF_DamagePermissionCore" )
    end,

    afterEach = function( state )
        local og = state.originalCanDamage
        hook.Add( "ACF_BulletDamage", "ACF_DamagePermissionCore", og )
    end,

    cases = {
        {
            name = "Does not deal damage to an invalid Type",
            func = function( state )
                stub( ACF, "Check" ).returns( false )

                local res = ACF.Damage( nil, state.trace, nil )
                expect( res.Damage ).to.equal( 0 )
                expect( res.Overkill ).to.equal( 0 )
                expect( res.Loss ).to.equal( 0 )
                expect( res.Kill ).to.beFalse()
            end
        },

        {
            name = "Does not deal damage if ACF_BulletDamage returns false",
            func = function( state )
                stub( ACF, "Check" )
                hook.Add( "ACF_BulletDamage", "Test", function()
                    return false
                end )

                local res = ACF.Damage( nil, state.trace, nil )
                expect( res.Damage ).to.equal( 0 )
                expect( res.Overkill ).to.equal( 0 )
                expect( res.Loss ).to.equal( 0 )
                expect( res.Kill ).to.beFalse()
            end
        },

        {
            name = "Calls an entity's custom OnDamage function, if present",
            func = function( state )
                local ent = state.ent

                ent.ACF_OnDamage = stub()
                stub( ACF, "Check" )

                ACF.Damage( nil, state.trace, nil )

                expect( ent.ACF_OnDamage ).to.haveBeenCalled()
            end
        },

        {
            name = "Calls PropDamage for a Prop",
            func = function( state )
                stub( ACF, "Check" ).returns( "Prop" )
                local propDamage = stub( ACF, "PropDamage" )

                ACF.Damage( nil, state.trace, nil )

                expect( propDamage ).to.haveBeenCalled()
            end
        },

        {
            name = "Calls VehicleDamage for a Vehicle",
            func = function( state )
                stub( ACF, "Check" ).returns( "Vehicle" )
                local vehicleDamage = stub( ACF, "VehicleDamage" )

                ACF.Damage( nil, state.trace, nil )

                expect( vehicleDamage ).to.haveBeenCalled()
            end
        },

        {
            name = "Calls SquishyDamage for a Squish",
            func = function( state )
                stub( ACF, "Check" ).returns( "Squishy" )
                local squishyDamage = stub( ACF, "SquishyDamage" )

                ACF.Damage( nil, state.trace, nil )

                expect( squishyDamage ).to.haveBeenCalled()
            end
        }
    }
}
