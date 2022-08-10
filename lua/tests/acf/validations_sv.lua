return {
    groupName = "ACF.IsLegal",

    beforeEach = function( state )
        local physObj = {}

        -- A technically Legal entity mock
        state.ent = {
            ACF = { PhysObj = physObj },

            GetPhysicsObject = function()
                return physObj
            end,

            IsSolid = function()
                return true
            end,

            GetCollisionGroup = function()
                return COLLISION_GROUP_NONE
            end
        }
    end,

    cases = {
        {
            name = "Is Legal when Gamemode is Sandbox",

            before = function( state )
                state.OriginalGamemode = ACF.Gamemode
            end,

            cleanup = function( state )
                ACF.Gamemode = state.OriginalGamemode
            end,

            func = function()
                expect( ACF.IsLegal( {} ) ).to.beTrue()
            end
        },

        {
            name = "Is not Legal with custom PhysObj",
            func = function( state )
                local ent = state.ent
                ent.ACF.PhysObj = {}
                ent.GetPhysicsObject = function()
                    return { GetVolume = function() return nil end }
                end

                local isLegal, err = ACF.IsLegal( ent )

                expect( isLegal ).to.beFalse()
                expect( err ).to.equal( "Invalid Physics" )
            end
        },

        {
            name = "Is not Legal when Entity is not solid",
            func = function( state )
                local ent = state.ent
                ent.IsSolid = function() return false end

                local isLegal, err = ACF.IsLegal( ent )

                expect( isLegal ).to.beFalse()
                expect( err ).to.equal( "Not Solid" )
            end
        },

        {
            name = "Is not Legal with an illegal collision group",
            func = function( state )
                local collisionGroup

                local ent = state.ent
                ent.GetCollisionGroup = function()
                    return collisionGroup
                end

                local isLegal, err

                -- COLLISION_GROUP_DEBRIS
                collisionGroup = COLLISION_GROUP_DEBRIS
                isLegal, err = ACF.IsLegal( ent )

                expect( isLegal ).to.beFalse()
                expect( err ).to.equal( "Invalid Collisions" )

                -- COLLISION_GROUP_IN_VEHICLE
                collisionGroup = COLLISION_GROUP_IN_VEHICLE
                isLegal, err = ACF.IsLegal( ent )

                expect( isLegal ).to.beFalse()
                expect( err ).to.equal( "Invalid Collisions" )

                -- COLLISION_GROUP_VEHICLE_CLIP
                collisionGroup = COLLISION_GROUP_VEHICLE_CLIP
                isLegal, err = ACF.IsLegal( ent )

                expect( isLegal ).to.beFalse()
                expect( err ).to.equal( "Invalid Collisions" )

                -- COLLISION_GROUP_DOOR_BLOCKER
                collisionGroup = COLLISION_GROUP_DOOR_BLOCKER
                isLegal, err = ACF.IsLegal( ent )

                expect( isLegal ).to.beFalse()
                expect( err ).to.equal( "Invalid Collisions" )
            end
        },

        {
            name = "Is not Legal with empty ClipData",
            func = function( state )
                local ent = state.ent
                ent.ClipData = {}

                local isLegal, err = ACF.IsLegal( ent )
                expect( isLegal ).to.beFalse()
                expect( err ).to.equal( "Visual Clip" )
            end
        },

        {
            name = "Gun is not Legal when Guns cannot fire",

            before = function() ACF.GunsCanFire = false end,
            cleanup = function() ACF.GunsCanFire = true end,

            func = function( state )
                local ent = state.ent
                ent.IsACFWeapon = true

                local isLegal, err = ACF.IsLegal( ent )
                expect( isLegal ).to.beFalse()
                expect( err ).to.equal( "Cannot fire" )
            end
        },

        {
            name = "Rack is not Legal when Racks cannot fire",

            before = function() ACF.RacksCanFire = false end,
            cleanup = function() ACF.RacksCanFire = true end,

            func = function( state )
                local ent = state.ent
                ent.IsRack = true

                local isLegal, err = ACF.IsLegal( ent )
                expect( isLegal ).to.beFalse()
                expect( err ).to.equal( "Cannot fire" )
            end
        },

        {
            name = "Is not Legal when ACF_IsLegal hook returns",

            before = function()
                hook.Add( "ACF_IsLegal", "TestFailure", function()
                    return false, "Test reason", "Test message", "Test timeout"
                end )
            end,

            cleanup = function() hook.Remove( "ACF_IsLegal", "TestFailure" ) end,

            func = function( state )
                local ent = state.ent

                local isLegal, reason, message, timeout = ACF.IsLegal( ent )

                expect( isLegal ).to.beFalse()
                expect( reason ).to.equal( "Test reason" )
                expect( message ).to.equal( "Test message" )
                expect( timeout ).to.equal( "Test timeout" )
            end
        },

        {
            name = "Is Legal when all conditions are met",
            func = function( state )
                local ent = state.ent

                local isLegal, err = ACF.IsLegal( ent )
                expect( isLegal ).to.beTrue()
                expect( err ).to.beNil()
            end
        }
    }
}
