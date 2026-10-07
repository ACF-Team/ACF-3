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

local function GetCheckedLimit( Class, ClientData )
    local Checked
    local Player = {
        CheckLimit = function( _, Name )
            Checked = Name
            return true
        end
    }

    scripted_ents.GetStored( Class ).t.ACF_CheckSpawnLimit( Player, "_" .. Class, ClientData )

    return Checked
end

return {
    groupName = "ACF entity spawn limits",

    cases = {
        {
            name = "Every limit checked by an ACF entity is registered",
            func = function()
                for Class, Stored in pairs( scripted_ents.GetList() ) do
                    local Check = Stored.t.ACF_CheckSpawnLimit

                    if Stored.t.IsACFEntity and Check then
                        local Name = GetCheckedLimit( Class, {} )

                        expect( Name ).to.exist()
                        expect( ConVarExists( "sbox_max" .. Name ) ).to.beTrue()
                    end
                end
            end
        },

        {
            name = "Every weapon class limit is registered",
            func = function()
                for _, Class in ipairs( ACF.Classes.GetSubtypesAsList( "ACF.Guns.BaseGun" ) ) do
                    expect( Class.LimitConVar ).to.exist()
                    expect( ConVarExists( "sbox_max" .. Class.LimitConVar.Name ) ).to.beTrue()
                end
            end
        },

        {
            name = "Weapons check the limit of their weapon class",
            func = function()
                local Data = { Weapon = { Type = "ACF.Guns.RotaryAutocannon", Data = { Caliber = 20 } } }

                expect( GetCheckedLimit( "acf_gun", Data ) ).to.equal( "_acf_rotaryautocannon" )
            end
        },

        {
            name = "Weapons accept a plain class name",
            func = function()
                expect( GetCheckedLimit( "acf_gun", { Weapon = "ACF.Guns.SmokeLauncher" } ) ).to.equal( "_acf_smokelauncher" )
            end
        },

        {
            name = "Weapons fall back to the cannon limit for unknown or missing classes",
            func = function()
                expect( GetCheckedLimit( "acf_gun", { Weapon = { Type = "ACF.Guns.NotAGun" } } ) ).to.equal( "_acf_weapon" )
                expect( GetCheckedLimit( "acf_gun", { Weapon = "ACF.Guns.BaseGun" } ) ).to.equal( "_acf_weapon" )
                expect( GetCheckedLimit( "acf_gun", nil ) ).to.equal( "_acf_weapon" )
            end
        },

        {
            name = "Radars and receivers share the sensor limit",
            func = function()
                expect( GetCheckedLimit( "acf_radar", {} ) ).to.equal( "_acf_sensor" )
                expect( GetCheckedLimit( "acf_receiver", {} ) ).to.equal( "_acf_sensor" )
            end
        },

        {
            name = "Turret components share the turret limit",
            func = function()
                for _, Class in ipairs( { "acf_turret", "acf_turret_motor", "acf_turret_gyro", "acf_turret_computer" } ) do
                    expect( GetCheckedLimit( Class, {} ) ).to.equal( "_acf_turret" )
                end
            end
        },

        {
            name = "Spawning without a player skips limit checks",
            async = true,
            coroutine = true,
            timeout = 10,
            func = function()
                WaitForContraption()

                stub( FindMetaTable( "Entity" ), "CPPISetOwner" )

                local Ent = ACF.Entities.DoSpawnInternal( "acf_radar", nil, Vector(), Angle(), {} )

                expect( Ent ).to.beValid()

                Ent:Remove()

                done()
            end
        },
    }
}
