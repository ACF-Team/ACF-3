local function Patch( Data )
    ACF.Entities.RunCompatPatches( Data.Class, Data )

    return Data.ACF_UserData
end

return {
    groupName = "Legacy weapon compat patches",

    cases = {
        {
            name = "Flare launcher guns resolve to the 40mm option instead of the group",
            func = function()
                local Data = Patch( { Class = "acf_gun", Weapon = "FGL", Caliber = 40 } )

                expect( Data.Weapon.Type ).to.equal( "ACF.Guns.40mmFlareLauncher" )
            end
        },

        {
            name = "Flare launcher ammo resolves to the 40mm option instead of the group",
            func = function()
                local Data = Patch( { Class = "acf_ammo", Weapon = "FGL", Caliber = 40, AmmoType = "FLR" } )

                expect( Data.Weapon.Type ).to.equal( "ACF.Guns.40mmFlareLauncher" )
            end
        },

        {
            name = "Scalable weapon groups still resolve to the group",
            func = function()
                local Data = Patch( { Class = "acf_gun", Weapon = "C", Caliber = 120 } )

                expect( Data.Weapon.Type ).to.equal( "ACF.Guns.Cannon" )
                expect( Data.Weapon.Data.Caliber ).to.equal( 120 )
            end
        },

        {
            name = "Pre-scalable weapon items resolve to their group and caliber",
            func = function()
                local Data = Patch( { Class = "acf_gun", Id = "20mmHRAC" } )

                expect( Data.Weapon.Type ).to.equal( "ACF.Guns.RotaryAutocannon" )
                expect( Data.Weapon.Data.Caliber ).to.equal( 20 )
            end
        },

        {
            name = "Every patched legacy gun resolves to a class without subtypes",
            func = function()
                for _, ID in ipairs( { "AC", "C", "FGL", "GL", "HW", "LAC", "MG", "MO", "RAC", "SA", "SC", "SL", "SB", "40mmFGL" } ) do
                    local Data  = Patch( { Class = "acf_gun", Weapon = ID, Caliber = 40 } )
                    local Class = ACF.Classes.GetTypeByName( Data.Weapon.Type )

                    expect( Class ).to.exist()
                    expect( next( ACF.Classes.GetChildren( Class ) ) ).to.beNil()
                end
            end
        },
    }
}
