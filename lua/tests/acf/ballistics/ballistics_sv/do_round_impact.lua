return {
    groupName = "ACF.Ballistics.DoRoundImpact",

    beforeEach = function( state )
        state.ACF_APKill_Result = {}
        state.ACF_APKill = stub( _G, "ACF_APKill" ).returns( state.ACF_APKill_Result )
        state.ACF_KEShove = stub( ACF, "KEShove" )

        state.ACF_Damage_Result = { Loss = 0, Kill = false }
        stub( ACF, "Damage" ).returns( state.ACF_Damage_Result )

        state.Bullet = {
            Speed = 1,
            Filter = {},
            Ricochets = 0,
            ShovePower = 1,
            Energy = { Kinetic = 1 },
            Flight = Vector( 1, 1, 1 )
        }

        state.Trace = {}
    end,

    cases = {
        {
            name = "Calculates Ricochet if HitRes Loss is 1",
            func = function( state )
                local GetRicochetVector = stub( ACF.Ballistics, "GetRicochetVector" ).returns( Vector( 1, 1, 1 ) )
                local CalculateRicochet = stub( ACF.Ballistics, "CalculateRicochet" ).returns( 1, 1 )

                local Trace = state.Trace
                local Bullet = state.Bullet
                state.ACF_Damage_Result.Loss = 1

                local HitRes = ACF.Ballistics.DoRoundImpact( Bullet, Trace )

                expect( HitRes.Ricochet ).to.equal( true )
                expect( GetRicochetVector ).to.haveBeenCalled()
                expect( CalculateRicochet ).to.haveBeenCalled()
            end
        },

        {
            name = "Calls ACF.KEShove if ACF.KEPush is enabled",
            func = function( state )
                state.Original_KEPush = ACF.KEPush
                ACF.KEPush = true

                local Trace = state.Trace
                local Bullet = state.Bullet

                ACF.Ballistics.DoRoundImpact( Bullet, Trace )

                expect( state.ACF_KEShove ).to.haveBeenCalled()
            end,

            cleanup = function( state )
                ACF.KEPush = state.Original_KEPush
            end
        },

        {
            name = "Does not call ACF.KEShove if ACF.KEPush is disabled",
            func = function( state )
                state.Original_KEPush = ACF.KEPush
                ACF.KEPush = false

                local Trace = state.Trace
                local Bullet = state.Bullet

                ACF.Ballistics.DoRoundImpact( Bullet, Trace )

                expect( state.ACF_KEShove ).toNot.haveBeenCalled()
            end,

            cleanup = function( state )
                ACF.KEPush = state.Original_KEPush
            end
        },

        {
            name = "Calls ACF_APKill when the entity is killed",
            func = function( state )
                local Trace = state.Trace
                local Bullet = state.Bullet
                state.ACF_Damage_Result.Kill = true

                ACF.Ballistics.DoRoundImpact( Bullet, Trace )

                expect( state.ACF_APKill ).to.haveBeenCalled()
                expect( #Bullet.Filter ).to.equal( 1 )
                expect( Bullet.Filter[1] ).to.equal( state.ACF_APKill_Result )
            end
        }
    }
}
