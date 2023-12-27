return {
    groupName = "ACF.IsLegal",

    beforeEach = function( State )
        local PhysObj = {}

        -- A technically Legal entity mock
        State.Ent = {
            ACF = { PhysObj = PhysObj },

            GetPhysicsObject = function()
                return PhysObj
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
            name = "Is Legal when checks are disabled",

            func = function( State )
                State.OriginalLegalChecks = ACF.LegalChecks
                ACF.LegalChecks = false

                expect( ACF.IsLegal() ).to.beTrue()
            end,

            cleanup = function( State )
                ACF.LegalChecks = State.OriginalLegalChecks
            end
        },

        {
            name = "Is not Legal with custom PhysObj",
            func = function( State )
                local Ent = State.Ent
                Ent.ACF.PhysObj = {}
                Ent.GetPhysicsObject = function()
                    return { GetVolume = function() return nil end }
                end

                local IsLegal, Err = ACF.IsLegal( Ent )

                expect( IsLegal ).to.beFalse()
                expect( Err ).to.equal( "Invalid Physics" )
            end
        },

        {
            name = "Is not Legal when Entity is not solid",
            func = function( State )
                local Ent = State.Ent
                Ent.IsSolid = function() return false end

                local IsLegal, Err = ACF.IsLegal( Ent )

                expect( IsLegal ).to.beFalse()
                expect( Err ).to.equal( "Not Solid" )
            end
        },

        {
            name = "Is not Legal with an illegal collision group",
            func = function( State )
                local CollisionGroup

                local Ent = State.Ent
                Ent.GetCollisionGroup = function()
                    return CollisionGroup
                end

                local IsLegal, Err

                -- COLLISION_GROUP_DEBRIS
                CollisionGroup = COLLISION_GROUP_DEBRIS
                IsLegal, Err = ACF.IsLegal( Ent )

                expect( IsLegal ).to.beFalse()
                expect( Err ).to.equal( "Invalid Collisions" )

                -- COLLISION_GROUP_IN_VEHICLE
                CollisionGroup = COLLISION_GROUP_IN_VEHICLE
                IsLegal, Err = ACF.IsLegal( Ent )

                expect( IsLegal ).to.beFalse()
                expect( Err ).to.equal( "Invalid Collisions" )

                -- COLLISION_GROUP_VEHICLE_CLIP
                CollisionGroup = COLLISION_GROUP_VEHICLE_CLIP
                IsLegal, Err = ACF.IsLegal( Ent )

                expect( IsLegal ).to.beFalse()
                expect( Err ).to.equal( "Invalid Collisions" )

                -- COLLISION_GROUP_DOOR_BLOCKER
                CollisionGroup = COLLISION_GROUP_DOOR_BLOCKER
                IsLegal, Err = ACF.IsLegal( Ent )

                expect( IsLegal ).to.beFalse()
                expect( Err ).to.equal( "Invalid Collisions" )
            end
        },

        {
            name = "Is not Legal with not-empty ClipData",
            func = function( State )
                local Ent = State.Ent
                Ent.ClipData = { "clip" }

                local IsLegal, Err = ACF.IsLegal( Ent )
                expect( IsLegal ).to.beFalse()
                expect( Err ).to.equal( "Visual Clip" )
            end
        },

        {
            name = "Gun is not Legal when Guns cannot fire",
            func = function( State )
                ACF.GunsCanFire = false

                local Ent = State.Ent
                Ent.IsACFWeapon = true

                local IsLegal, Err = ACF.IsLegal( Ent )
                expect( IsLegal ).to.beFalse()
                expect( Err ).to.equal( "Cannot fire" )
            end,

            cleanup = function() ACF.GunsCanFire = true end
        },

        {
            name = "Rack is not Legal when Racks cannot fire",
            func = function( State )
                ACF.RacksCanFire = false

                local Ent = State.Ent
                Ent.IsRack = true

                local IsLegal, Err = ACF.IsLegal( Ent )
                expect( IsLegal ).to.beFalse()
                expect( Err ).to.equal( "Cannot fire" )
            end,

            cleanup = function() ACF.RacksCanFire = true end
        },

        {
            name = "Is not Legal when ACF_IsLegal hook returns",
            func = function( State )
                hook.Add( "ACF_IsLegal", "TestFailure", function()
                    return false, "Test reason", "Test message", "Test timeout"
                end )

                local Ent = State.Ent
                local IsLegal, Reason, Message, Timeout = ACF.IsLegal( Ent )

                expect( IsLegal ).to.beFalse()
                expect( Reason ).to.equal( "Test reason" )
                expect( Message ).to.equal( "Test message" )
                expect( Timeout ).to.equal( "Test timeout" )
            end,

            cleanup = function() hook.Remove( "ACF_IsLegal", "TestFailure" ) end
        },

        {
            name = "Is Legal when all conditions are met",
            func = function( State )
                local Ent = State.Ent

                local IsLegal, Err = ACF.IsLegal( Ent )
                expect( IsLegal ).to.beTrue()
                expect( Err ).to.beNil()
            end
        }
    }
}