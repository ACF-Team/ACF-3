local function FakeRack()
    local Rack = {
        IsValid       = function() return true end,
        Missiles      = {},
        InAirMissiles = {},
        LocalToWorld  = function( _, Pos ) return Pos + Vector( 100, 0, 0 ) end,
        LocalToWorldAngles = function( _, Ang ) return Ang end,
        UpdateLoadCalls = {},
    }

    function Rack:UpdateLoad( Point ) self.UpdateLoadCalls[#self.UpdateLoadCalls + 1] = Point end

    return Rack
end

local Point = { Position = Vector( 1, 0, 0 ), Angle = Angle() }

return {
    groupName = "ACF.Missiles.RackLauncher",

    cases = {
        {
            name = "Fires from the rack",
            func = function()
                local Rack = FakeRack()

                expect( ACF.Missiles.RackLauncher( Rack, Point ):GetEntity() ).to.equal( Rack )
            end
        },

        {
            name = "Filters the rack, its loaded missiles and its missiles in flight",
            func = function()
                local Rack = FakeRack()
                local Loaded, InAir = {}, {}
                Rack.Missiles[1] = Loaded
                Rack.InAirMissiles[InAir] = true

                local Filter = ACF.Missiles.RackLauncher( Rack, Point ):GetMissileFilter()

                expect( table.HasValue( Filter, Rack ) ).to.beTrue()
                expect( table.HasValue( Filter, Loaded ) ).to.beTrue()
                expect( table.HasValue( Filter, InAir ) ).to.beTrue()
            end
        },

        {
            name = "Launch origin is the mount point in world space",
            func = function()
                local Pos = ACF.Missiles.RackLauncher( FakeRack(), Point ):GetLaunchOrigin()

                expect( Pos ).to.equal( Vector( 101, 0, 0 ) )
            end
        },

        {
            name = "Uses the rack's sound only when it has one",
            func = function()
                local Rack = FakeRack()
                local Launcher = ACF.Missiles.RackLauncher( Rack, Point )

                Rack.SoundPath = ""
                expect( Launcher:GetLaunchSound() ).to.beNil()

                Rack.SoundPath = "some/sound.wav"
                expect( Launcher:GetLaunchSound() ).to.equal( "some/sound.wav" )
            end
        },

        {
            name = "Allows a motor delay only on racks that can drop missiles",
            func = function()
                local Rack = FakeRack()
                local Launcher = ACF.Missiles.RackLauncher( Rack, Point )

                expect( Launcher:CanDelayMotor() ).to.beFalse()

                Rack.CanDropMissile = true
                expect( Launcher:CanDelayMotor() ).to.beTrue()
            end
        },

        {
            name = "Frees the mount point when an unlaunched missile is removed",
            func = function()
                local Rack = FakeRack()

                ACF.Missiles.RackLauncher( Rack, Point ):OnMissileRemoved( {}, false )

                expect( #Rack.UpdateLoadCalls ).to.equal( 1 )
                expect( Rack.UpdateLoadCalls[1] ).to.equal( Point )
            end
        },

        {
            name = "Leaves the mount point alone when a launched missile is removed",
            func = function()
                local Rack = FakeRack()

                ACF.Missiles.RackLauncher( Rack, Point ):OnMissileRemoved( {}, true )

                expect( #Rack.UpdateLoadCalls ).to.equal( 0 )
            end
        },
    }
}
