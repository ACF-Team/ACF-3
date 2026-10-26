local function FakeCrate( RoundData )
    return { IsValid = function() return true end, RoundData = RoundData }
end

return {
    groupName = "ACF.Missiles.SpecFromCrate",

    cases = {
        {
            name = "Builds a spec from the crate's round, keeping a reference to the crate",
            func = function()
                local Source = ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.HEAT" } )
                local Crate  = FakeCrate( Source.Ammo )
                local Spec   = ACF.Missiles.SpecFromCrate( Crate )

                expect( Spec.Crate ).to.equal( Crate )
                expect( Spec.Ammo ).to.equal( Source.Ammo )
                expect( ACF.Classes.GetTypeName( Spec.Class ) ).to.equal( "ACF.Missiles.AntiTankGuided.AT-3" )
            end
        },

        {
            name = "Fails on an invalid crate",
            func = function()
                local Spec, Err = ACF.Missiles.SpecFromCrate( NULL )

                expect( Spec ).to.beNil()
                expect( Err ).to.equal( "Invalid crate" )
            end
        },

        {
            name = "Fails on a crate without round data",
            func = function()
                local Spec, Err = ACF.Missiles.SpecFromCrate( FakeCrate( nil ) )

                expect( Spec ).to.beNil()
                expect( Err ).to.equal( "Crate has no round data" )
            end
        },

        {
            name = "Fails on a crate holding gun ammo",
            func = function()
                local Ammo = { Weapon = ACF.Classes.GetTypeByName( "ACF.Guns.Cannon" )() }
                local Spec, Err = ACF.Missiles.SpecFromCrate( FakeCrate( Ammo ) )

                expect( Spec ).to.beNil()
                expect( Err ).to.equal( "Crate does not hold missiles" )
            end
        },
    }
}
