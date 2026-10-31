-- Only SWEP bullets fired by a player are predictable, every other bullet has to keep working like before
return {
    groupName = "ACF.Ballistics predicted bullets",

    beforeEach = function( State )
        State.TestAmmo = {}
        stub( ACF.Classes, "GetSubtypeByName" ).returns( State.TestAmmo )

        State.Bullet = {
            Type   = "TestType",
            Pos    = Vector( 0, 0, 0 ),
            Flight = Vector( 0, 0, 0 ),
        }
    end,

    afterEach = function()
        table.Empty( ACF.Ballistics.Bullets )
        table.Empty( ACF.Ballistics.PredictedBullets )
        hook.Remove( "ACF_OnTick", "ACF Iterate Bullets" )
    end,

    cases = {
        {
            name = "Normal bullets are stepped on the server's tick",
            func = function( State )
                local Calc = stub( ACF.Ballistics, "CalcBulletFlight" )

                ACF.Ballistics.Bullets[1] = State.Bullet
                ACF.Ballistics.IterateBullets()

                expect( Calc ).was.called()
            end
        },

        {
            name = "Predictable bullets are left to their owner's commands",
            func = function( State )
                local Calc = stub( ACF.Ballistics, "CalcBulletFlight" )

                State.Bullet.Predictable = true
                ACF.Ballistics.Bullets[1] = State.Bullet
                ACF.Ballistics.IterateBullets()

                expect( Calc ).wasNot.called()
            end
        },

        {
            name = "Normal bullets start on the server's clock",
            func = function( State )
                stub( ACF.Ballistics, "BulletClient" )
                stub( ACF.Ballistics, "CalcBulletFlight" )

                local Bullet = ACF.Ballistics.CreateBullet( State.Bullet )

                expect( Bullet.LastThink ).to.equal( ACF.Utilities.Clock.CurTime )
                expect( Bullet.Predictable ).toNot.beTrue()
            end
        },

        {
            name = "Predictable bullets without a player owner fall back to the server's tick",
            func = function( State )
                stub( ACF.Ballistics, "BulletClient" )
                local Calc = stub( ACF.Ballistics, "CalcBulletFlight" )

                State.Bullet.Predictable = true
                State.Bullet.PredictionID = 1

                local Bullet = ACF.Ballistics.CreateBullet( State.Bullet )

                expect( Bullet.Predictable ).to.beFalse()
                expect( next( ACF.Ballistics.PredictedBullets ) ).to.beNil()
                expect( Bullet.LastThink ).to.equal( ACF.Utilities.Clock.CurTime )
                expect( Calc ).was.called() -- The first step runs like any other bullet's
            end
        },

        {
            name = "Normal bullets' effects go to everyone without a net message",
            func = function( State )
                local Filter
                stub( ACF.Utilities.Effects, "CreateEffect" ).with( function( _, _, _, Recipients )
                    Filter = Recipients
                end )
                local NetStart = stub( net, "Start" )

                State.Bullet.Index = 1

                ACF.Ballistics.BulletClient( State.Bullet, "Init", 0 )
                ACF.Ballistics.BulletClient( State.Bullet, "Update", 1, Vector() )

                expect( Filter ).to.beTrue()
                expect( NetStart ).wasNot.called()
            end
        },

        {
            name = "Predictable bullets without a valid owner still send their effects to everyone",
            func = function( State )
                local Filter
                stub( ACF.Utilities.Effects, "CreateEffect" ).with( function( _, _, _, Recipients )
                    Filter = Recipients
                end )
                local NetStart = stub( net, "Start" )

                State.Bullet.Index = 1
                State.Bullet.Predictable = true
                State.Bullet.PredictionID = 1

                ACF.Ballistics.BulletClient( State.Bullet, "Init", 0 )

                expect( Filter ).to.beTrue()
                expect( NetStart ).wasNot.called()
            end
        },
    }
}
