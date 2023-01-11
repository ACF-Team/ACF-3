return {
    groupName = "ACF.Check",

    beforeEach = function( State )
        local Mass = 1
        local PhysObj = {
            GetMass = function() return Mass end,
            IsValid = function() return true end
        }

        State.Ent = {
            ACF = {
                Type = "Test",
                PhysObj = PhysObj,
                Mass = Mass
            },
            IsValid = function() return true end,
            IsWorld = function() return false end,
            IsWeapon = function() return false end,
            GetClass = function() return "prop_physics" end,
            GetPhysicsObject = function() return PhysObj end,
        }
    end,

    cases = {
        {
            name = "Returns Entity.ACF.Type",
            func = function( State )
                local Ent = State.Ent

                expect( ACF.Check( Ent ) ).to.equal( "Test" )
            end
        },

        {
            name = "Returns false if Entity is invalid",
            func = function( State )
                local Ent = State.Ent
                Ent.IsValid = function() return false end

                expect( ACF.Check() ).to.beFalse()
            end
        },

        {
            name = "Returns false if Entity has a bad class",
            func = function( State )
                local Ent = State.Ent
                Ent.GetClass = function() return "acf_debris" end

                expect( ACF.Check( Ent ) ).to.beFalse()
            end
        },

        {
            name = "Returns false if Entity has invalid physics object",
            func = function( State )
                local Ent = State.Ent
                Ent.GetPhysicsObject = function() return nil end

                expect( ACF.Check( Ent ) ).to.beFalse()
            end
        },

        {
            name = "Returns false and does not Activate when Ent.ACF is not set, and Entity is World",
            func = function( State )
                local Ent = State.Ent
                Ent.ACF = nil

                -- ACF Caches this class if we get this far, so we need to use
                -- a different class name, otherwise we halt on the first class check
                Ent.GetClass = function() return "prop_physics1" end
                Ent.IsWorld = function() return true end

                local Activate = stub( ACF, "Activate" )

                expect( ACF.Check( Ent ) ).to.beFalse()
                expect( Activate ).wasNot.called()
            end
        },

        {
            name = "Returns false and does not Activate when Ent.ACF is not set, and Entity is a Weapon",
            func = function( State )
                local Ent = State.Ent
                Ent.ACF = nil
                Ent.GetClass = function() return "prop_physics2" end
                Ent.IsWeapon = function() return true end

                local Activate = stub( ACF, "Activate" )

                expect( ACF.Check( Ent ) ).to.beFalse()
                expect( Activate ).wasNot.called()
            end
        },

        {
            name = "Returns false and does not Activate when Ent.ACF is not set, and Entity has a func_ class",
            func = function( State )
                local Ent = State.Ent
                Ent.ACF = nil
                Ent.GetClass = function() return "func_test" end

                local Activate = stub( ACF, "Activate" )

                expect( ACF.Check( Ent ) ).to.beFalse()
                expect( Activate ).wasNot.called()
            end
        },

        {
            name = "Calls Activate if Entity.ACF is not set",
            func = function( State )
                local Ent = State.Ent
                Ent.ACF = nil

                local Activate = stub( ACF, "Activate" ).with( function( e )
                    e.ACF = { Type = "Test" }
                end )

                expect( ACF.Check( Ent ) ).to.equal( "Test" )
                expect( Activate ).was.called()
            end
        },

        {
            name = "Calls Activate if ForceUpdate param is set",
            func = function( State )
                local Ent = State.Ent

                local Activate = stub( ACF, "Activate" ).with( function( e )
                    e.ACF = { Type = "Test" }
                end )

                expect( ACF.Check( Ent, true ) ).to.equal( "Test" )
                expect( Activate ).was.called()
            end
        },

        {
            name = "Calls Activate if Entity.ACF.Mass differs from PhysObj",
            func = function( State )
                local Ent = State.Ent
                Ent.ACF.Mass = Ent.ACF.Mass + 1

                local Activate = stub( ACF, "Activate" ).with( function( e )
                    e.ACF = { Type = "Test" }
                end )

                expect( ACF.Check( Ent ) ).to.equal( "Test" )
                expect( Activate ).was.called()
            end
        },

        {
            name = "Calls Activate if Entity.ACF.PhysObj differs from PhysObj",
            func = function( State )
                local Ent = State.Ent
                Ent.ACF.PhysObj = {}

                local Activate = stub( ACF, "Activate" ).with( function( e )
                    e.ACF = { Type = "Test" }
                end )

                expect( ACF.Check( Ent ) ).to.equal( "Test" )
                expect( Activate ).was.called()
            end
        }
    }
}
