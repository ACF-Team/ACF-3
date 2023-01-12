return {
    groupName = "ACF.Damage.dealDamage",

    beforeEach = function( State )
        local Entries = hook.GetTable().ACF_PreDamageEntity
        local Hooks   = {}

        State.Ent       = {}
        State.DmgResult = ACF.Damage.Objects.DamageResult()

        if Entries then
            for K, V in pairs( Entries ) do
                Hooks[K] = V

                hook.Remove( "ACF_PreDamageEntity", K )
            end
        end

        State.Hooks = Hooks
    end,

    afterEach = function( State )
        for K, V in pairs( State.Hooks ) do
            hook.Add( "ACF_PreDamageEntity", K, V )
        end
    end,

    cases = {
        {
            name = "Does not deal damage if ACF.Check fails",
            func = function( State )
                stub( ACF, "Check" ).returns( false )

                local HitRes = ACF.Damage.dealDamage( nil, State.DmgResult, nil )
                expect( HitRes.Damage ).to.equal( 0 )
                expect( HitRes.Overkill ).to.equal( 0 )
                expect( HitRes.Loss ).to.equal( 0 )
                expect( HitRes.Kill ).to.beFalse()
            end
        },

        {
            name = "Does not deal damage to an invalid type",
            func = function( State )
                stub( ACF, "Check" )

                local HitRes = ACF.Damage.dealDamage( nil, State.DmgResult, nil )
                expect( HitRes.Damage ).to.equal( 0 )
                expect( HitRes.Overkill ).to.equal( 0 )
                expect( HitRes.Loss ).to.equal( 0 )
                expect( HitRes.Kill ).to.beFalse()
            end
        },

        {
            name = "Does not deal damage if ACF_PreDamageEntity returns false",
            func = function( State )
                stub( ACF, "Check" )

                hook.Add( "ACF_PreDamageEntity", "Test", function()
                    return false
                end )

                local HitRes = ACF.Damage.dealDamage( nil, State.DmgResult, nil )
                expect( HitRes.Damage ).to.equal( 0 )
                expect( HitRes.Overkill ).to.equal( 0 )
                expect( HitRes.Loss ).to.equal( 0 )
                expect( HitRes.Kill ).to.beFalse()
            end
        },

        {
            name = "Calls an entity's custom OnDamage function, if present",
            func = function( State )
                stub( ACF, "Check" ).returns( "Test" )

                local Ent = State.Ent
                Ent.ACF_OnDamage = stub()

                ACF.Damage.dealDamage( Ent, State.DmgResult, nil )

                expect( Ent.ACF_OnDamage ).was.called()
            end
        },

        {
            name = "Calls PropDamage for a Prop",
            func = function( State )
                local PropDamage = stub( ACF.Damage, "doPropDamage" )

                stub( ACF, "Check" ).returns( "Prop" )

                ACF.Damage.dealDamage( State.Ent, State.DmgResult, nil )

                expect( PropDamage ).was.called()
            end
        },

        {
            name = "Calls VehicleDamage for a Vehicle",
            func = function( State )
                local VehicleDamage = stub( ACF.Damage, "doVehicleDamage" )

                stub( ACF, "Check" ).returns( "Vehicle" )

                ACF.Damage.dealDamage( State.Ent, State.DmgResult, nil )

                expect( VehicleDamage ).was.called()
            end
        },

        {
            name = "Calls SquishyDamage for a Squish",
            func = function( State )
                local SquishyDamage = stub( ACF.Damage, "doSquishyDamage" )

                stub( ACF, "Check" ).returns( "Squishy" )

                ACF.Damage.dealDamage( State.Ent, State.DmgResult, nil )

                expect( SquishyDamage ).was.called()
            end
        }
    }
}
