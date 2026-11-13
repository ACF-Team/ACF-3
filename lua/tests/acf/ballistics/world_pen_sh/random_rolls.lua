-- Bullets without a PredictionID (every gun, missile and spall fragment) have to roll exactly like before
-- Predicted bullets have to roll the same numbers on the server and the owner's client
return {
    groupName = "ACF.Ballistics random rolls",

    beforeEach = function( State )
        State.Predicted = { PredictionID = 21699100929, WorldHits = 1 }
    end,

    cases = {
        {
            name = "Random uses math.Rand for normal bullets",
            func = function()
                local Args
                local Rand = stub( math, "Rand" ).with( function( Min, Max )
                    Args = { Min, Max }

                    return 0.95
                end )

                local Result = ACF.Ballistics.Random( {}, "Density", 0.9, 1.1 )

                expect( Rand ).was.called()
                expect( Result ).to.equal( 0.95 )
                expect( Args[1] ).to.equal( 0.9 )
                expect( Args[2] ).to.equal( 1.1 )
            end
        },

        {
            name = "RandomInt uses math.random for normal bullets",
            func = function()
                local Args
                local Random = stub( math, "random" ).with( function( Min, Max )
                    Args = { Min, Max }

                    return 70
                end )

                local Result = ACF.Ballistics.RandomInt( {}, "Ricochet", 46.7, 90 )

                expect( Random ).was.called()
                expect( Result ).to.equal( 70 )
                expect( Args[1] ).to.equal( 46.7 )
                expect( Args[2] ).to.equal( 90 )
            end
        },

        {
            name = "RandomVector uses VectorRand for normal bullets",
            func = function()
                local Expected = Vector( 0.1, 0.2, 0.3 )
                local VecRand  = stub( _G, "VectorRand" ).returns( Expected )

                local Result = ACF.Ballistics.RandomVector( {}, "RicochetSpread" )

                expect( VecRand ).was.called()
                expect( Result ).to.equal( Expected )
            end
        },

        {
            name = "Predicted bullets don't touch the global random generator",
            func = function( State )
                local Random  = stub( math, "random" )
                local Rand    = stub( math, "Rand" )
                local VecRand = stub( _G, "VectorRand" )

                ACF.Ballistics.Random( State.Predicted, "Density", 0.9, 1.1 )
                ACF.Ballistics.RandomInt( State.Predicted, "Ricochet", 46.7, 90 )
                ACF.Ballistics.RandomVector( State.Predicted, "RicochetSpread" )

                expect( Random ).wasNot.called()
                expect( Rand ).wasNot.called()
                expect( VecRand ).wasNot.called()
            end
        },

        {
            -- The client works these out on its own, a change here has to land on both realms at once
            name = "Predicted rolls are pinned to known values",
            func = function( State )
                local Vec = ACF.Ballistics.RandomVector( State.Predicted, "RicochetSpread" )

                expect( ACF.Ballistics.Random( State.Predicted, "Density", 0.9, 1.1 ) ).to.aboutEqual( 0.961128713517, 1e-9 )
                expect( ACF.Ballistics.RandomInt( State.Predicted, "Ricochet", 46.7, 90 ) ).to.aboutEqual( 83.7, 1e-9 )
                expect( Vec.x ).to.aboutEqual( -0.506615579128, 1e-5 )
                expect( Vec.y ).to.aboutEqual( -0.436522454023, 1e-5 )
                expect( Vec.z ).to.aboutEqual( 0.634074389935, 1e-5 )
            end
        },

        {
            name = "Predicted rolls stay within the same bounds as the normal ones",
            func = function( State )
                for Hit = 1, 50 do
                    State.Predicted.WorldHits = Hit

                    local Float = ACF.Ballistics.Random( State.Predicted, "Density", 0.9, 1.1 )
                    local Int   = ACF.Ballistics.RandomInt( State.Predicted, "Ricochet", 46.7, 90 )
                    local Vec   = ACF.Ballistics.RandomVector( State.Predicted, "RicochetSpread" )

                    expect( Float ).to.beBetween( 0.9, 1.1 )
                    expect( Int ).to.beBetween( 46.7, 90.7 ) -- math.random(46.7, 90) can return 90.7 too
                    expect( Int - 46.7 ).to.aboutEqual( math.Round( Int - 46.7 ), 1e-9 )
                    expect( Vec.x ).to.beBetween( -1, 1 )
                    expect( Vec.y ).to.beBetween( -1, 1 )
                    expect( Vec.z ).to.beBetween( -1, 1 )
                end
            end
        },

        {
            name = "Each map hit and each roll gets its own number",
            func = function( State )
                local First  = ACF.Ballistics.Random( State.Predicted, "Density", 0, 1 )
                local Other  = ACF.Ballistics.Random( State.Predicted, "Ricochet", 0, 1 )

                State.Predicted.WorldHits = 2

                local Second = ACF.Ballistics.Random( State.Predicted, "Density", 0, 1 )

                expect( First ).toNot.equal( Other )
                expect( First ).toNot.equal( Second )
            end
        },
    }
}
