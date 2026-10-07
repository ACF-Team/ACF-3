local function WaitForContraption()
    if ACF.Contraption.SetModel then return end

    local Co = coroutine.running()

    timer.Create( "ACF Tests Wait For Contraption", 0, 0, function()
        if not ACF.Contraption.SetModel then return end

        timer.Remove( "ACF Tests Wait For Contraption" )
        coroutine.resume( Co )
    end )

    coroutine.yield()
end

local function GetClassDef( Class )
    return scripted_ents.GetStored( Class ).t.ACF_ClassDef
end

local function Sanitize( Class, Data )
    return ACF.Classes.Serialization.SanitizeClassFields( GetClassDef( Class ), Data )
end

return {
    groupName = "ACF.Classes.Serialization.SanitizeClassFields",

    cases = {
        {
            name = "Keeps a valid class field",
            func = function()
                local Data = Sanitize( "acf_radar", { Sensor = { Type = "ACF.Sensors.Radar.Targeting.SmallDirectional", Data = { Foo = 1 } } } )

                expect( Data.Sensor.Type ).to.equal( "ACF.Sensors.Radar.Targeting.SmallDirectional" )
                expect( Data.Sensor.Data.Foo ).to.equal( 1 )
            end
        },

        {
            name = "Converts a plain class name into a class field table",
            func = function()
                local Data = Sanitize( "acf_radar", { Sensor = "ACF.Sensors.Radar.Targeting.SmallDirectional" } )

                expect( Data.Sensor.Type ).to.equal( "ACF.Sensors.Radar.Targeting.SmallDirectional" )
                expect( Data.Sensor.Data ).to.beA( "table" )
            end
        },

        {
            name = "Drops classes from another family",
            func = function()
                local Data = Sanitize( "acf_radar", { Sensor = { Type = "ACF.Ammunition.AP", Data = {} } } )

                expect( Data.Sensor ).to.beNil()
            end
        },

        {
            name = "Drops group classes on leaf-only fields",
            func = function()
                expect( Sanitize( "acf_radar", { Sensor = "ACF.Sensors.Radar.Targeting" } ).Sensor ).to.beNil()
                expect( Sanitize( "acf_engine", { Engine = "ACF.Engines.V8" } ).Engine ).to.beNil()
                expect( Sanitize( "acf_gun", { Weapon = "ACF.Guns.BaseScalableGun" } ).Weapon ).to.beNil()
                expect( Sanitize( "acf_gun", { Weapon = "ACF.Guns.FlareLauncher" } ).Weapon ).to.beNil()
            end
        },

        {
            name = "Keeps group ammo types, since they are spawnable",
            func = function()
                expect( Sanitize( "acf_ammo", { AmmoType = "ACF.Ammunition.AP" } ).AmmoType.Type ).to.equal( "ACF.Ammunition.AP" )
            end
        },

        {
            name = "Drops non-computer components from computers",
            func = function()
                expect( Sanitize( "acf_computer", { Computer = "ACF.Components.Autoloader" } ).Computer ).to.beNil()
                expect( Sanitize( "acf_computer", { Computer = "ACF.Components.Joystick" } ).Computer.Type ).to.equal( "ACF.Components.Joystick" )
            end
        },

        {
            name = "Drops values that are not class names or class tables",
            func = function()
                for _, Value in ipairs( { 5, true, {}, { Type = 5 } } ) do
                    expect( Sanitize( "acf_radar", { Sensor = Value } ).Sensor ).to.beNil()
                end
            end
        },

        {
            name = "Replaces invalid class data with a table",
            func = function()
                local Data = Sanitize( "acf_radar", { Sensor = { Type = "ACF.Sensors.Radar.Targeting.SmallDirectional", Data = "Junk" } } )

                expect( Data.Sensor.Data ).to.beA( "table" )
            end
        },

        {
            name = "Spawning with an invalid class field uses the default instead of erroring",
            async = true,
            coroutine = true,
            timeout = 10,
            func = function()
                WaitForContraption()

                stub( FindMetaTable( "Entity" ), "CPPISetOwner" )

                local Ent = ACF.Entities.DoSpawnInternal( "acf_radar", nil, Vector(), Angle(), { Sensor = { Type = "ACF.Ammunition.AP" } } )

                expect( Ent ).to.beValid()
                expect( ACF.Classes.GetTypeName( Ent:ACF_GetUserVar( "Sensor" ):GetType() ) ).to.equal( "ACF.Sensors.Radar.Targeting.SmallDirectional" )

                Ent:Remove()

                done()
            end
        },
    }
}
