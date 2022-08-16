return {
    groupName = "ACF.Damage",

    beforeEach = function( State )
        State.Ent = {}
        State.Trace = { Entity = State.Ent }

        State.originalCanDamage = ACF.Permissions.CanDamage
        hook.Remove( "ACF_BulletDamage", "ACF_DamagePermissionCore" )
    end,

    afterEach = function( State )
        local OG = State.originalCanDamage
        hook.Add( "ACF_BulletDamage", "ACF_DamagePermissionCore", OG )
    end,

    cases = {
        {
            name = "Does not deal damage to an invalid Type",
            func = function( State )
                stub( ACF, "Check" ).returns( false )

                local HitRes = ACF.Damage( nil, State.Trace, nil )
                expect( HitRes.Damage ).to.equal( 0 )
                expect( HitRes.Overkill ).to.equal( 0 )
                expect( HitRes.Loss ).to.equal( 0 )
                expect( HitRes.Kill ).to.beFalse()
            end
        },

        {
            name = "Does not deal damage if ACF_BulletDamage returns false",
            func = function( State )
                stub( ACF, "Check" )
                hook.Add( "ACF_BulletDamage", "Test", function()
                    return false
                end )

                local HitRes = ACF.Damage( nil, State.Trace, nil )
                expect( HitRes.Damage ).to.equal( 0 )
                expect( HitRes.Overkill ).to.equal( 0 )
                expect( HitRes.Loss ).to.equal( 0 )
                expect( HitRes.Kill ).to.beFalse()
            end
        },

        {
            name = "Calls an entity's custom OnDamage function, if present",
            func = function( State )
                local Ent = State.Ent

                Ent.ACF_OnDamage = stub()
                stub( ACF, "Check" )

                ACF.Damage( nil, State.Trace, nil )

                expect( Ent.ACF_OnDamage ).to.haveBeenCalled()
            end
        },

        {
            name = "Calls PropDamage for a Prop",
            func = function( State )
                stub( ACF, "Check" ).returns( "Prop" )
                local PropDamage = stub( ACF, "PropDamage" )

                ACF.Damage( nil, State.Trace, nil )

                expect( PropDamage ).to.haveBeenCalled()
            end
        },

        {
            name = "Calls VehicleDamage for a Vehicle",
            func = function( State )
                stub( ACF, "Check" ).returns( "Vehicle" )
                local VehicleDamage = stub( ACF, "VehicleDamage" )

                ACF.Damage( nil, State.Trace, nil )

                expect( VehicleDamage ).to.haveBeenCalled()
            end
        },

        {
            name = "Calls SquishyDamage for a Squish",
            func = function( State )
                stub( ACF, "Check" ).returns( "Squishy" )
                local SquishyDamage = stub( ACF, "SquishyDamage" )

                ACF.Damage( nil, State.Trace, nil )

                expect( SquishyDamage ).to.haveBeenCalled()
            end
        }
    }
}
