-- Ground ricochets of every gun go through here, these pin down how normal bullets behave
return {
    groupName = "ACF.Ballistics.DoRicochet",

    beforeEach = function( State )
        -- 1000 m/s coming down at 45 degrees onto flat ground
        State.Bullet = {
            Flight      = Vector( 1, 0, -1 ):GetNormalized() * 1000 * ACF.MeterToInch * ACF.Scale,
            Ricochet    = 60,
            GroundRicos = 0,
        }

        State.Trace = {
            Hit       = true,
            HitPos    = Vector( 0, 0, 0 ),
            HitNormal = Vector( 0, 0, 1 ),
            Entity    = game.GetWorld(),
        }
    end,

    cases = {
        {
            name = "Rolls the minimum angle against 90 like before",
            func = function( State )
                local Args
                stub( math, "random" ).with( function( Min, Max )
                    Args = Args or { Min, Max } -- VectorRand calls math.random too, only the first call is the roll

                    return 0
                end )
                stub( _G, "VectorRand" ).returns( Vector() )

                local Speed    = State.Bullet.Flight:Length() / ACF.Scale
                local MinAngle = math.min( 60 - Speed / ACF.MeterToInch / 30 + 20, 89.9 )

                ACF.Ballistics.DoRicochet( State.Bullet, State.Trace )

                expect( Args[1] ).to.aboutEqual( MinAngle, 1e-6 )
                expect( Args[2] ).to.equal( 90 )
            end
        },

        {
            name = "Ricochets when the hit angle beats the roll",
            func = function( State )
                stub( math, "random" ).returns( 0 )
                stub( _G, "VectorRand" ).returns( Vector() )

                local Result = ACF.Ballistics.DoRicochet( State.Bullet, State.Trace )

                expect( Result ).to.equal( "Ricochet" )
                expect( State.Bullet.GroundRicos ).to.equal( 1 )
                expect( State.Bullet.Pos ).to.equal( State.Trace.HitPos )
                expect( State.Bullet.Flight.z ).to.beGreaterThan( 0 ) -- Bounced back up
            end
        },

        {
            name = "Stops when the roll beats the hit angle",
            func = function( State )
                stub( math, "random" ).returns( 90 )

                local Flight = State.Bullet.Flight
                local Result = ACF.Ballistics.DoRicochet( State.Bullet, State.Trace )

                expect( Result ).to.beFalse()
                expect( State.Bullet.GroundRicos ).to.equal( 0 )
                expect( State.Bullet.Flight ).to.equal( Flight )
            end
        },

        {
            name = "Doesn't ricochet off the ground more than twice",
            func = function( State )
                stub( math, "random" ).returns( 0 )
                State.Bullet.GroundRicos = 2

                expect( ACF.Ballistics.DoRicochet( State.Bullet, State.Trace ) ).to.beFalse()
            end
        },

        {
            name = "Keeps 75% of the hit angle's share of the speed",
            func = function( State )
                stub( math, "random" ).returns( 0 )
                stub( _G, "VectorRand" ).returns( Vector() )

                local Speed    = State.Bullet.Flight:Length()
                local HitAngle = ACF.GetHitAngle( State.Trace, State.Bullet.Flight )

                ACF.Ballistics.DoRicochet( State.Bullet, State.Trace )

                expect( State.Bullet.Flight:Length() ).to.aboutEqual( Speed * HitAngle / 90 * 0.75, 0.01 ) -- Vectors are single precision
            end
        },

        {
            name = "Normal bullets get VectorRand spread on the new heading",
            func = function( State )
                stub( math, "random" ).returns( 0 )
                local VecRand = stub( _G, "VectorRand" ).returns( Vector() )

                ACF.Ballistics.DoRicochet( State.Bullet, State.Trace )

                local Heading = State.Bullet.Flight:GetNormalized()

                expect( VecRand ).was.called()
                expect( Heading.x ).to.aboutEqual( math.sqrt( 0.5 ), 1e-6 ) -- A clean mirror without spread
                expect( Heading.z ).to.aboutEqual( math.sqrt( 0.5 ), 1e-6 )
            end
        },

        {
            name = "Predicted bullets get the same ricochet every time",
            func = function( State )
                local Random = stub( math, "random" )

                local First = table.Copy( State.Bullet )
                First.PredictionID, First.WorldHits = 21699100929, 1

                local Second = table.Copy( First )

                local ResultA = ACF.Ballistics.DoRicochet( First, State.Trace )
                local ResultB = ACF.Ballistics.DoRicochet( Second, State.Trace )

                expect( Random ).wasNot.called()
                expect( ResultA ).to.equal( ResultB )
                expect( First.Flight ).to.equal( Second.Flight )
            end
        },
    }
}
