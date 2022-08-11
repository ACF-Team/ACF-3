local ones = Vector( 1, 1, 1 )

return {
    groupName = "ACF.KeShove",

    beforeEach = function( state )
        state.applyForceStub = stub()

        state.ent = {
            acftotal = 1,
            acfphystotal = 1,
            acflastupdatemass = math.huge,

            IsValid = function() return true end,
            WorldToLocal = function() return ones end,
            LocalToWorld = function() return ones end,
            GetPhysicsObject = function()
                return {
                    IsValid = function()
                        return true
                    end,

                    ApplyForceOffset = state.applyForceStub
                }
            end,
        }

        -- For simplicity's sake, we'll pretend the ent's ancestor is itself
        stub( _G, "ACF_GetAncestor" ).returns( state.ent )
    end,

    cases = {
        {
            name = "Shoves the target",
            func = function( state )
                local ent = state.ent

                ACF.KEShove( ent, ones, ones, 1 )

                expect( state.applyForceStub ).to.haveBeenCalled()
            end
        },

        {
            name = "Does not shove invalid targets",
            func = function( state )
                local ent = state.ent
                ent.IsValid = function() return false end

                ACF.KEShove( ent, ones, ones, 1 )

                expect( state.applyForceStub ).toNot.haveBeenCalled()
            end
        },
        {
            name = "Does not shove the entity if ACF_KEShove hook returns false",
            func = function( state )
                hook.Add( "ACF_KEShove", "Test", function() return false end )
                local ent = state.ent

                ACF.KEShove( ent, ones, ones, 1 )

                expect( state.applyForceStub ).toNot.haveBeenCalled()
            end,

            cleanup = function()
                hook.Remove( "ACF_KEShove", "Test" )
            end
        },

        {
            name = "Calculates the Mass if acflastupdatemass is absent",
            func = function( state )
                local ent = state.ent
                ent.acflastupdatemass = nil

                local calcMass = stub( _G, "ACF_CalcMassRatio" )
                ACF.KEShove( ent, ones, ones, 1 )

                expect( calcMass ).to.haveBeenCalled()
            end
        },

        {
            name = "Calculates the Mass if acflastupdatemass is stale",
            func = function( state )
                local ent = state.ent
                ent.acflastupdatemass = -math.huge

                local calcMass = stub( _G, "ACF_CalcMassRatio" )
                ACF.KEShove( ent, ones, ones, 1 )

                expect( calcMass ).to.haveBeenCalled()
            end
        }
    }
}
