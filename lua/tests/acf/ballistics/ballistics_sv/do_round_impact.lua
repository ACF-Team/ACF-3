return {
    groupName = "ACF.Ballistics.DoRoundImpact",

    beforeEach = function( State )
        State.ACF_APKill_Result = {}
        State.ACF_APKill = stub( _G, "ACF_APKill" ).returns( State.ACF_APKill_Result )
        State.ACF_KEShove = stub( ACF, "KEShove" )

        State.ACF_Damage_Result = { Loss = 0, Kill = false }
        stub( ACF, "Damage" ).returns( State.ACF_Damage_Result )

        State.Bullet = {
            Speed = 1,
            Filter = {},
            Ricochets = 0,
            ShovePower = 1,
            Energy = { Kinetic = 1 },
            Flight = Vector( 1, 1, 1 )
        }

        State.Trace = {
            Entity = {
                IsValid = function() return true end
            }
        }
    end,

    cases = {
        {
            name = "Calculates Ricochet if HitRes Loss is 1",
            func = function( State )
                local GetRicochetVector = stub( ACF.Ballistics, "GetRicochetVector" ).returns( Vector( 1, 1, 1 ) )
                local CalculateRicochet = stub( ACF.Ballistics, "CalculateRicochet" ).returns( 1, 1 )

                local Trace = State.Trace
                local Bullet = State.Bullet
                State.ACF_Damage_Result.Loss = 1

                local HitRes = ACF.Ballistics.DoRoundImpact( Bullet, Trace )

                expect( HitRes.Ricochet ).to.equal( true )
                expect( GetRicochetVector ).to.haveBeenCalled()
                expect( CalculateRicochet ).to.haveBeenCalled()
            end
        },

        {
            name = "Calls ACF.KEShove if ACF.KEPush is enabled",
            func = function( State )
                State.Original_KEPush = ACF.KEPush
                ACF.KEPush = true

                local Trace = State.Trace
                local Bullet = State.Bullet

                ACF.Ballistics.DoRoundImpact( Bullet, Trace )

                expect( State.ACF_KEShove ).to.haveBeenCalled()
            end,

            cleanup = function( State )
                ACF.KEPush = State.Original_KEPush
            end
        },

        {
            name = "Does not call ACF.KEShove if ACF.KEPush is disabled",
            func = function( State )
                State.Original_KEPush = ACF.KEPush
                ACF.KEPush = false

                local Trace = State.Trace
                local Bullet = State.Bullet

                ACF.Ballistics.DoRoundImpact( Bullet, Trace )

                expect( State.ACF_KEShove ).toNot.haveBeenCalled()
            end,

            cleanup = function( State )
                ACF.KEPush = State.Original_KEPush
            end
        },

        {
            name = "Calls ACF_APKill when the entity is killed",
            func = function( State )
                local Trace = State.Trace
                local Bullet = State.Bullet

                State.ACF_Damage_Result.Kill = true

                ACF.Ballistics.DoRoundImpact( Bullet, Trace )

                expect( State.ACF_APKill ).to.haveBeenCalled()
            end
        },

        {
            name = "Does not call ACF_APKill when an invalid entity is killed",
            func = function( State )
                local Trace = State.Trace
                local Bullet = State.Bullet

                State.Entity.IsValid = function() return false end
                State.ACF_Damage_Result.Kill = true

                ACF.Ballistics.DoRoundImpact( Bullet, Trace )

                expect( State.ACF_APKill ).notTo.haveBeenCalled()
            end
        }
    }
}
