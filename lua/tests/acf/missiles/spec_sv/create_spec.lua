local function TypeName( Instance )
    return ACF.Classes.GetTypeName( Instance:GetType() )
end

return {
    groupName = "ACF.Missiles.CreateSpec",

    cases = {
        {
            name = "Builds a spec from a missile FQN and ammo type",
            func = function()
                local Spec = ACF.Missiles.CreateSpec( { Missile = "ACF.Missiles.AntiTankGuided.AT-3", AmmoType = "ACF.Ammunition.HEAT" } )

                expect( ACF.Classes.GetTypeName( Spec.Class ) ).to.equal( "ACF.Missiles.AntiTankGuided.AT-3" )
                expect( Spec.BulletData.AmmoType ).to.equal( "ACF.Ammunition.HEAT" )
                expect( Spec.BulletData.WeaponType ).to.equal( "ACF.Missiles.AntiTankGuided.AT-3" )
            end
        },

        {
            name = "Resolves a missile by its short id",
            func = function()
                local Spec = ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.HEAT" } )

                expect( ACF.Classes.GetTypeName( Spec.Class ) ).to.equal( "ACF.Missiles.AntiTankGuided.AT-3" )
            end
        },

        {
            name = "Has no crate",
            func = function()
                local Spec = ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.HEAT" } )

                expect( Spec.Crate ).to.beNil()
            end
        },

        {
            name = "Defaults to Dumb guidance, Contact fuze and the class' navigation",
            func = function()
                local Spec = ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.HEAT" } )

                expect( TypeName( Spec.Guidance ) ).to.equal( "ACF.Missiles.Guidance.Dumb" )
                expect( TypeName( Spec.Fuze ) ).to.equal( "ACF.Missiles.Fuze.Contact" )
                expect( TypeName( Spec.Navigation ) ).to.equal( ACF.Classes.GetTypeByName( "ACF.Missiles.AntiTankGuided.AT-3" ).Navigation )
            end
        },

        {
            name = "Uses the class' round lengths when no ammo inputs are given",
            func = function()
                local Round = ACF.Classes.GetTypeByName( "ACF.Missiles.AntiTankGuided.AT-3" ).Round
                local Spec  = ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.HEAT" } )
                local Total = Spec.BulletData.ProjLength + Spec.BulletData.PropLength

                expect( Total ).to.aboutEqual( Round.ProjLength + Round.PropLength, 0.05 )
            end
        },

        {
            name = "Uses the given Projectile and Propellant lengths",
            func = function()
                local Spec = ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.HEAT", Ammo = { Projectile = 10, Propellant = 10 } } )
                local Total = Spec.BulletData.ProjLength + Spec.BulletData.PropLength

                expect( Total ).to.aboutEqual( 20, 0.05 )
            end
        },

        {
            name = "Uses an allowed guidance given as { Type, Data }",
            func = function()
                local Spec = ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.HEAT", Guidance = { Type = "ACF.Missiles.Guidance.WireMCLOS" } } )

                expect( TypeName( Spec.Guidance ) ).to.equal( "ACF.Missiles.Guidance.WireMCLOS" )
            end
        },

        {
            name = "Overrides the navigation law",
            func = function()
                local Spec = ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.HEAT", Navigation = { Type = "ACF.Missiles.Navigation.APN" } } )

                expect( TypeName( Spec.Navigation ) ).to.equal( "ACF.Missiles.Navigation.APN" )
            end
        },

        {
            name = "Fails on a navigation given by short name",
            func = function()
                local Spec, Err = ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.HEAT", Navigation = { Type = "APN" } } )

                expect( Spec ).to.beNil()
                expect( Err ).to.equal( "Navigation type 'APN' is not a ACF.Missiles.Navigation" )
            end
        },

        {
            name = "Copies a guidance given as an instance instead of keeping it",
            func = function()
                local Guidance = ACF.Classes.GetTypeByName( "ACF.Missiles.Guidance.WireMCLOS" )()
                local Spec     = ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.HEAT", Guidance = Guidance } )

                expect( TypeName( Spec.Guidance ) ).to.equal( "ACF.Missiles.Guidance.WireMCLOS" )
                expect( Spec.Guidance ).notTo.equal( Guidance )
            end
        },

        {
            name = "Fails when Params is not a table",
            func = function()
                local Spec, Err = ACF.Missiles.CreateSpec( nil )

                expect( Spec ).to.beNil()
                expect( Err ).to.equal( "Params must be a table" )
            end
        },

        {
            name = "Fails on an unknown missile",
            func = function()
                local Spec, Err = ACF.Missiles.CreateSpec( { Missile = "NotAMissile", AmmoType = "ACF.Ammunition.HEAT" } )

                expect( Spec ).to.beNil()
                expect( Err ).to.equal( "Unknown missile 'NotAMissile'" )
            end
        },

        {
            name = "Fails on a missile group",
            func = function()
                local Spec, Err = ACF.Missiles.CreateSpec( { Missile = "ACF.Missiles.AntiTankGuided", AmmoType = "ACF.Ammunition.HEAT" } )

                expect( Spec ).to.beNil()
                expect( Err ).to.equal( "Missile 'ACF.Missiles.AntiTankGuided' is a group, not a missile" )
            end
        },

        {
            name = "Fails on an unknown ammo type",
            func = function()
                local Spec, Err = ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.Nope" } )

                expect( Spec ).to.beNil()
                expect( Err ).to.equal( "Unknown ammo type 'ACF.Ammunition.Nope'" )
            end
        },

        {
            name = "Fails on an ammo type the missile blacklists",
            func = function()
                local Spec, Err = ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.AP" } )

                expect( Spec ).to.beNil()
                expect( Err ).to.equal( "Ammo type 'ACF.Ammunition.AP' can't be used on 'ACF.Missiles.AntiTankGuided.AT-3'" )
            end
        },

        {
            name = "Fails on a guidance the missile doesn't allow",
            func = function()
                local Spec, Err = ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.HEAT", Guidance = { Type = "ACF.Missiles.Guidance.Laser" } } )

                expect( Spec ).to.beNil()
                expect( Err ).to.equal( "Guidance 'ACF.Missiles.Guidance.Laser' is not allowed on this missile" )
            end
        },

        {
            name = "Fails on a fuze type that isn't a fuze",
            func = function()
                local Spec, Err = ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.HEAT", Fuze = { Type = "ACF.Missiles.Guidance.Dumb" } } )

                expect( Spec ).to.beNil()
                expect( Err ).to.equal( "Fuze type 'ACF.Missiles.Guidance.Dumb' is not a ACF.Missiles.Fuze" )
            end
        },
    }
}
