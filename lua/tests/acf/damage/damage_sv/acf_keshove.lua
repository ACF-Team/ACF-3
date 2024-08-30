local Ones = Vector( 1, 1, 1 )

return {
    groupName = "ACF.KeShove",

    beforeEach = function( State )
        State.applyForceStub = stub()

        State.Ent = {
            acftotal = 1,
            acfphystotal = 1,
            acflastupdatemass = math.huge,

            IsValid = function() return true end,
            WorldToLocal = function() return Ones end,
            LocalToWorld = function() return Ones end,
            GetPhysicsObject = function()
                return {
                    IsValid = function() return true end,
                    ApplyForceOffset = State.applyForceStub,
                    GetMass = function() return 1 end,
                }
            end,
            GetChildren = function() return {} end,
            GetAncestor = function() return State.Ent end, -- For simplicity's sake, we'll pretend the ent's ancestor is itself
        }
    end,

    cases = {
        {
            name = "Shoves the target",
            func = function( State )
                local Ent = State.Ent

                ACF.KEShove( Ent, Ones, Ones, 1 )

                expect( State.applyForceStub ).was.called()
            end
        },

        {
            name = "Does not shove invalid targets",
            func = function( State )
                local Ent = State.Ent
                Ent.IsValid = function() return false end

                ACF.KEShove( Ent, Ones, Ones, 1 )

                expect( State.applyForceStub ).wasNot.called()
            end
        },
        {
            name = "Does not shove the entity if ACF_KEShove hook returns false",
            func = function( State )
                hook.Add( "ACF_OnPushEntity", "Test", function() return false end )
                local Ent = State.Ent

                ACF.KEShove( Ent, Ones, Ones, 1 )

                expect( State.applyForceStub ).wasNot.called()
            end,

            cleanup = function()
                hook.Remove( "ACF_OnPushEntity", "Test" )
            end
        },

        {
            name = "Calculates the Mass if acflastupdatemass is absent",
            func = function( State )
                local Ent = State.Ent
                Ent.acflastupdatemass = nil

                local calcMass = stub( ACF.Contraption, "CalcMassRatio" )
                ACF.KEShove( Ent, Ones, Ones, 1 )

                expect( calcMass ).was.called()
            end
        },

        {
            name = "Calculates the Mass if acflastupdatemass is stale",
            func = function( State )
                local Ent = State.Ent
                Ent.acflastupdatemass = -math.huge

                local calcMass = stub( ACF.Contraption, "CalcMassRatio" )
                ACF.KEShove( Ent, Ones, Ones, 1 )

                expect( calcMass ).was.called()
            end
        }
    }
}
