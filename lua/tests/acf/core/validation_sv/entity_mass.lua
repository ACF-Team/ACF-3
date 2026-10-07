local function Spawn( Class, Data )
    local Ent = ACF.Entities.DoSpawnInternal( Class, nil, Vector( 0, 0, 500 ), Angle(), Data )

    return Ent, IsValid( Ent ) and Ent:GetPhysicsObject():GetMass()
end

return {
    groupName = "ACF entity mass after spawning",

    beforeEach = function( State )
        stub( FindMetaTable( "Entity" ), "CPPISetOwner" )
        State.Ents = {}
    end,

    afterEach = function( State )
        for _, Ent in ipairs( State.Ents ) do
            if IsValid( Ent ) then Ent:Remove() end
        end
    end,

    cases = {
        {
            name = "Gearboxes keep their scaled mass",
            func = function( State )
                local Class = ACF.Classes.GetTypeByName( "ACF.Gearboxes.Manual-L" )
                local Expected = ACF.GetGearboxStats( Class.Mass, 1.5, Class.MaxTorque, 6 )
                local Ent, Mass = Spawn( "acf_gearbox", { Gearbox = "ACF.Gearboxes.Manual-L", GearboxScale = 1.5, GearAmount = 6 } )
                State.Ents[1] = Ent

                expect( Mass ).to.equal( Expected )
            end
        },

        {
            name = "Entities without their own ACF_Activate keep their class mass",
            func = function( State )
                local Cases = {
                    { "acf_computer", { Computer = "ACF.Components.LaserGuidanceComputer" }, "ACF.Components.LaserGuidanceComputer" },
                    { "acf_rack", { Rack = "ACF.Racks.2xRK" }, "ACF.Racks.2xRK" },
                    { "acf_turret_gyro", { Gyro = "ACF.Turrets.Gyro.Dual" }, "ACF.Turrets.Gyro.Dual" },
                }

                for I, Case in ipairs( Cases ) do
                    local Ent, Mass = Spawn( Case[1], Case[2] )
                    State.Ents[I] = Ent

                    expect( Mass ).to.equal( ACF.Classes.GetTypeByName( Case[3] ).Mass )
                end
            end
        },

        {
            name = "A stale mass modifier does not override an ACF entity's mass",
            func = function( State )
                local Ent, Mass = Spawn( "acf_rack", { Rack = "ACF.Racks.2xRK" } )
                State.Ents[1] = Ent

                duplicator.StoreEntityModifier( Ent, "mass", { Mass = 1 } )
                ACF.Activate( Ent, true )

                expect( Ent:GetPhysicsObject():GetMass() ).to.equal( Mass )
            end
        },
    }
}
