local function SpawnCrate( State, Guidance )
    local Success, Crate = ACF.Entities.Spawn( "acf_ammo", nil, Vector( 0, 0, 500 ), Angle(), {
        Weapon = "ACF.Missiles.AntiTankGuided.AT-3",
        AmmoType = "ACF.Ammunition.HEAT",
        Guidance = Guidance,
        Fuze = "ACF.Missiles.Fuze.Contact",
        CrateProjectilesX = 1,
        CrateProjectilesY = 1,
        CrateProjectilesZ = 1,
    }, true )

    State.Crate = Crate

    return Success, Crate
end

return {
    groupName = "ACF.Missiles command guidance on crates",

    beforeEach = function()
        -- Prop protection addons error on an ownerless spawn
        stub( FindMetaTable( "Entity" ), "CPPISetOwner" )
    end,

    cases = {
        {
            name = "A crate holding command guided missiles spawns",
            func = function( State )
                local Success, Crate = SpawnCrate( State, "ACF.Missiles.Guidance.WireMCLOS" )

                expect( Success ).to.beTrue()
                expect( Crate ).to.beValid()
                expect( Crate.GuidanceData.Name ).to.equal( "Wire (MCLOS)" )
            end,
            cleanup = function( State )
                if IsValid( State.Crate ) then State.Crate:Remove() end
            end
        },

        {
            name = "A crate's command guidance has no source",
            func = function( State )
                local _, Crate = SpawnCrate( State, "ACF.Missiles.Guidance.WireMCLOS" )

                expect( Crate.GuidanceData.Source ).to.beNil()
            end,
            cleanup = function( State )
                if IsValid( State.Crate ) then State.Crate:Remove() end
            end
        },
    }
}
