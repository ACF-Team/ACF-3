return {
    groupName = "ACF.TempDamage.dealDamage",

    beforeEach = function( State )
        local Entries = hook.GetTable().ACF_PreDamageEntity
        local Hooks   = {}

        State.Ent       = {}
        State.DmgResult = ACF.TempDamage.Objects.DamageResult()

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

                local HitRes = ACF.TempDamage.dealDamage( nil, State.DmgResult, nil )
                expect( HitRes.Damage ).to.equal( 0 )
                expect( HitRes.Overkill ).to.equal( 0 )
                expect( HitRes.Loss ).to.equal( 0 )
                expect( HitRes.Kill ).to.beFalse()
            end
        },

        {
            name = "Does not deal damage to an invalid type",
            func = function( State )
                stub( ACF, "Check" ).returns( "Test" )

                local HitRes = ACF.TempDamage.dealDamage( nil, State.DmgResult, nil )
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

                local HitRes = ACF.TempDamage.dealDamage( nil, State.DmgResult, nil )
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

                ACF.TempDamage.dealDamage( nil, State.DmgResult, nil )

                expect( Ent.ACF_OnDamage ).to.haveBeenCalled()
            end
        },

        {
            name = "Calls PropDamage for a Prop",
            func = function( State )
                local PropDamage = stub( ACF.TempDamag, "doPropDamage" )

                stub( ACF, "Check" ).returns( "Prop" )

                ACF.TempDamage.dealDamage( nil, State.DmgResult, nil )

                expect( PropDamage ).to.haveBeenCalled()
            end
        },

        {
            name = "Calls VehicleDamage for a Vehicle",
            func = function( State )
                local VehicleDamage = stub( ACF.TempDamag, "doVehicleDamage" )

                stub( ACF, "Check" ).returns( "Vehicle" )

                ACF.TempDamage.dealDamage( nil, State.DmgResult, nil )

                expect( VehicleDamage ).to.haveBeenCalled()
            end
        },

        {
            name = "Calls SquishyDamage for a Squish",
            func = function( State )
                local SquishyDamage = stub( ACF.TempDamag, "doSquishyDamage" )

                stub( ACF, "Check" ).returns( "Squishy" )

                ACF.TempDamage.dealDamage( nil, State.DmgResult, nil )

                expect( SquishyDamage ).to.haveBeenCalled()
            end
        }
    }
}
