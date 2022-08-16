return {
    groupName = "ACF.Ballistics.CreateBullet",

    beforeEach = function( state )
        state.TestAmmo = {}
        stub( ACF.Classes.AmmoTypes, "Get" ).returns( state.TestAmmo )
        stub( ACF.Ballistics, "BulletClient" )
        stub( ACF.Ballistics, "CalcBulletFlight" )
        stub( ACF.Ballistics, "IterateBullets" )

        state.Bullet = {
            Type = "TestType"
        }
    end,

    afterEach = function()
        table.Empty( ACF.Ballistics.Bullets )
    end,

    cases = {
        {
            name = "Does not create a bullet if no Index can be acquired",
            func = function()
                stub( ACF.Ballistics, "GetBulletIndex" ).returns( nil )

                local res = ACF.Ballistics.CreateBullet( {} )
                expect( res ).to.beNil()
            end
        },

        {
            name = "Adds the Bullet to the Bullets table",
            func = function( state )
                local CreatedBullet = ACF.Ballistics.CreateBullet( state.Bullet )

                local CreatedIndex = CreatedBullet.Index
                expect( ACF.Ballistics.Bullets[CreatedIndex] ).to.equal( CreatedBullet )
            end,
        },

        {
            name = "Sets Bullet.Filter to empty table if not provided and invalid Gun",
            func = function( state )
                local CreatedBullet = ACF.Ballistics.CreateBullet( state.Bullet )
                local CreatedFilter = CreatedBullet.Filter

                expect( CreatedFilter ).to.exist()
                expect( CreatedFilter ).to.beA( "table" )
                expect( #CreatedFilter ).to.equal( 0 )
            end
        },

        {
            name = "Sets Bullet.Filter to Bullet.Gun if not provided and valid Gun",
            func = function( state )
                state.Bullet.Gun = { IsValid = function() return true end, Test = "Test" }

                local CreatedBullet = ACF.Ballistics.CreateBullet( state.Bullet )
                local CreatedFilter = CreatedBullet.Filter

                expect( CreatedFilter ).to.exist()
                expect( CreatedFilter ).to.beA( "table" )
                expect( #CreatedFilter ).to.equal( 1 )
                expect( CreatedFilter[1].Test ).to.equal( "Test" )
            end
        },

        {
            name = "Does not overwrite Bullet.Filter if set",
            func = function( state )
                state.Bullet.Filter = { { Test = "Test" } }

                local CreatedBullet = ACF.Ballistics.CreateBullet( state.Bullet )
                local CreatedFilter = CreatedBullet.Filter

                expect( CreatedFilter ).to.exist()
                expect( CreatedFilter ).to.beA( "table" )
                expect( CreatedFilter[1].Test ).to.equal( "Test" )
            end
        },

        {
            name = "Converts given Fuze to detonation time",
            func = function( state )
                local FuzeTime = 1
                state.Bullet.Fuze = FuzeTime

                local CreatedBullet = ACF.Ballistics.CreateBullet( state.Bullet )
                local CreatedFuze = CreatedBullet.Fuze

                expect( CreatedFuze ).to.beGreaterThan( FuzeTime )
            end
        },

        {
            name = "GetPenetration returns the Ammo Type's GetPenetration",
            func = function( state )
                state.TestAmmo.GetPenetration = function()
                    return 12345
                end

                local CreatedBullet = ACF.Ballistics.CreateBullet( state.Bullet )
                local Penetration = CreatedBullet:GetPenetration()

                expect( Penetration ).to.equal( 12345 )
            end
        },
    }
}
