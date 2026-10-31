-- Every gun hitting the map goes through here, these pin down how normal bullets behave
return {
    groupName = "ACF.Ballistics.GetPenetrationSetup",

    beforeEach = function( State )
        State.Bullet = {
            Flight         = Vector( 1000, 0, 0 ),
            GetPenetration = function() return 100 end,
        }

        State.Trace = {
            HitPos       = Vector( 1, 2, 3 ),
            SurfaceProps = 0, -- "default"
        }
    end,

    cases = {
        {
            name = "Varies the density with math.Rand(0.9, 1.1) for normal bullets",
            func = function( State )
                local Args
                stub( math, "Rand" ).with( function( Min, Max )
                    Args = { Min, Max }

                    return 1
                end )

                local Density = ACF.Ballistics.GetPenetrationSetup( State.Bullet, State.Trace )
                local Surface = util.GetSurfaceData( 0 )
                local Base    = Surface and Surface.density * 0.5 or 500

                expect( Args[1] ).to.equal( 0.9 )
                expect( Args[2] ).to.equal( 1.1 )
                expect( Density ).to.aboutEqual( Base ^ 0.9 / 10000, 1e-9 )
            end
        },

        {
            name = "Returns the penetration, its RHA equivalent, the entry and the heading",
            func = function( State )
                stub( math, "Rand" ).returns( 1 )

                local Density, MaxPen, RHAe, Enter, Fwd = ACF.Ballistics.GetPenetrationSetup( State.Bullet, State.Trace )

                expect( MaxPen ).to.equal( 100 )
                expect( RHAe ).to.aboutEqual( math.max( 100 / Density, 1 ), 1e-6 )
                expect( Enter ).to.equal( State.Trace.HitPos )
                expect( Fwd ).to.equal( Vector( 1, 0, 0 ) )
            end
        },

        {
            name = "Predicted bullets get the same density every time without math.Rand",
            func = function( State )
                local Rand = stub( math, "Rand" )

                State.Bullet.PredictionID, State.Bullet.WorldHits = 21699100929, 1

                local First  = ACF.Ballistics.GetPenetrationSetup( State.Bullet, State.Trace )
                local Second = ACF.Ballistics.GetPenetrationSetup( State.Bullet, State.Trace )

                expect( Rand ).wasNot.called()
                expect( First ).to.equal( Second )
            end
        },
    }
}
