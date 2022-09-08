return {
    groupName = "ACF.Ballistics.CreateBullet",

    beforeAll = function( State )
        State.IterateBullets = ACF.Ballistics.IterateBullets
        ACF.Ballistics.IterateBullets = function() end
    end,

    beforeEach = function( State )
        State.TestAmmo = {}
        stub( ACF.Classes.AmmoTypes, "Get" ).returns( State.TestAmmo )
        stub( ACF.Ballistics, "BulletClient" )
        stub( ACF.Ballistics, "CalcBulletFlight" )

        State.Bullet = {
            Type = "TestType"
        }
    end,

    afterEach = function()
        table.Empty( ACF.Ballistics.Bullets )
        hook.Remove( "ACF_OnClock", "ACF Iterate Bullets" )
    end,

    afterAll = function( State )
        ACF.Ballistics.IterateBullets = State.IterateBullets
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
            func = function( State )
                local CreatedBullet = ACF.Ballistics.CreateBullet( State.Bullet )

                local CreatedIndex = CreatedBullet.Index
                expect( ACF.Ballistics.Bullets[CreatedIndex] ).to.equal( CreatedBullet )
            end,
        },

        {
            name = "Sets Bullet.Filter to empty table if not provided and invalid Gun",
            func = function( State )
                local CreatedBullet = ACF.Ballistics.CreateBullet( State.Bullet )
                local CreatedFilter = CreatedBullet.Filter

                expect( CreatedFilter ).to.exist()
                expect( CreatedFilter ).to.beA( "table" )
                expect( #CreatedFilter ).to.equal( 0 )
            end
        },

        {
            name = "Sets Bullet.Filter to Bullet.Gun if not provided and valid Gun",
            func = function( State )
                State.Bullet.Gun = { IsValid = function() return true end, Test = "Test" }

                local CreatedBullet = ACF.Ballistics.CreateBullet( State.Bullet )
                local CreatedFilter = CreatedBullet.Filter

                expect( CreatedFilter ).to.exist()
                expect( CreatedFilter ).to.beA( "table" )
                expect( #CreatedFilter ).to.equal( 1 )
                expect( CreatedFilter[1].Test ).to.equal( "Test" )
            end
        },

        {
            name = "Does not overwrite Bullet.Filter if set",
            func = function( State )
                State.Bullet.Filter = { { Test = "Test" } }

                local CreatedBullet = ACF.Ballistics.CreateBullet( State.Bullet )
                local CreatedFilter = CreatedBullet.Filter

                expect( CreatedFilter ).to.exist()
                expect( CreatedFilter ).to.beA( "table" )
                expect( CreatedFilter[1].Test ).to.equal( "Test" )
            end
        },

        {
            name = "Converts given Fuze to detonation time",
            func = function( State )
                local FuzeTime = 1
                State.Bullet.Fuze = FuzeTime

                local CreatedBullet = ACF.Ballistics.CreateBullet( State.Bullet )
                local CreatedFuze = CreatedBullet.Fuze

                expect( CreatedFuze ).to.beGreaterThan( FuzeTime )
            end
        },

        {
            name = "GetPenetration returns the Ammo Type's GetPenetration",
            func = function( State )
                State.TestAmmo.GetPenetration = function()
                    return 12345
                end

                local CreatedBullet = ACF.Ballistics.CreateBullet( State.Bullet )
                local Penetration = CreatedBullet:GetPenetration()

                expect( Penetration ).to.equal( 12345 )
            end
        }
    }
}
