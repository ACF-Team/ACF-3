local Bases = {
    "ACF.Ammunition.BaseAmmo",
    "ACF.Engines.BaseEngine",
    "ACF.FuelTypes.FuelType",
    "ACF.Gearboxes.BaseGearbox",
    "ACF.Guns.BaseGun",
}

return {
    groupName = "ACF.GetSubtypeByLegacyStyleName",

    cases = {
        {
            name = "Every legacy style name resolves back to its own class",
            func = function()
                for _, Base in ipairs( Bases ) do
                    for _, FQN in ipairs( ACF.Classes.GetSubtypeFQNs( Base ) ) do
                        local Name  = ACF.GetLegacyStyleClassName( FQN )
                        local Class = ACF.GetSubtypeByLegacyStyleName( Base, Name )

                        expect( ACF.Classes.GetTypeName( Class ) ).to.equal( FQN )
                    end
                end
            end
        },

        {
            name = "Resolves fully qualified names",
            func = function()
                local Class = ACF.GetSubtypeByLegacyStyleName( "ACF.Guns.BaseGun", "ACF.Guns.Cannon" )

                expect( Class ).to.equal( ACF.Classes.GetTypeByName( "ACF.Guns.Cannon" ) )
            end
        },

        {
            name = "Resolves legacy weapon and engine names",
            func = function()
                expect( ACF.GetSubtypeByLegacyStyleName( "ACF.Guns.BaseGun", "C" ) ).to.equal( ACF.Classes.GetTypeByName( "ACF.Guns.Cannon" ) )
                expect( ACF.GetSubtypeByLegacyStyleName( "ACF.Guns.BaseGun", "40mmFGL" ) ).to.equal( ACF.Classes.GetTypeByName( "ACF.Guns.40mmFlareLauncher" ) )
                expect( ACF.GetSubtypeByLegacyStyleName( "ACF.Engines.BaseEngine", "5.7-V8" ) ).to.equal( ACF.Classes.GetTypeByName( "ACF.Engines.5.7-V8" ) )
            end
        },

        {
            name = "Does not resolve the base class itself",
            func = function()
                expect( ACF.GetSubtypeByLegacyStyleName( "ACF.Guns.BaseGun", "BaseGun" ) ).to.beNil()
            end
        },

        {
            name = "Returns nil for unknown names",
            func = function()
                expect( ACF.GetSubtypeByLegacyStyleName( "ACF.Guns.BaseGun", "NotAGun" ) ).to.beNil()
            end
        },
    }
}
