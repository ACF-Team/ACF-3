return {
    groupName = "ACF.Check",

    beforeEach = function( state )
        local mass = 1
        local physObj = {
            GetMass = function() return mass end,
            IsValid = function() return true end
        }

        state.ent = {
            ACF = {
                Type = "Test",
                PhysObj = physObj,
                Mass = mass
            },
            IsValid = function() return true end,
            IsWorld = function() return false end,
            IsWeapon = function() return false end,
            GetClass = function() return "prop_physics" end,
            GetPhysicsObject = function() return physObj end,
        }
    end,

    cases = {
        {
            name = "Returns Entity.ACF.Type",
            func = function( state )
                local ent = state.ent

                print( "IsValid", not IsValid( ent ) )
                print( "Class", ACF.GlobalFilter[ent:GetClass()] )
                print( "PhsObj IsValid", not IsValid( ent:GetPhysicsObject() ) )

                expect( ACF.Check( ent ) ).to.equal( "Test" )
            end
        },

        {
            name = "Returns false if Entity is invalid",
            func = function()
                expect( ACF.Check() ).to.beFalse()
            end
        },

        {
            name = "Returns false if Entity has a bad class",
            func = function( state )
                local ent = state.ent
                ent.GetClass = function() return "acf_debris" end

                expect( ACF.Check( ent ) ).to.beFalse()
            end
        },

        {
            name = "Returns false if Entity has invalid physics object",
            func = function( state )
                local ent = state.ent
                ent.GetPhysicsObject = function() return nil end

                expect( ACF.Check ( ent ) ).to.beFalse()
            end
        },

        {
            name = "Returns false and does not Activate when Ent.ACF is not set, and Entity is World",
            func = function( state )
                local ent = state.ent
                ent.ACF = nil

                -- ACF Caches this class if we get this far, so we need to use
                -- a different class name, otherwise we halt on the first class check
                ent.GetClass = function() return "prop_physics1" end
                ent.IsWorld = function() return true end

                local activate = stub( ACF, "Activate" )

                expect( ACF.Check( ent ) ).to.beFalse()
                expect( activate ).notTo.haveBeenCalled()
            end
        },

        {
            name = "Returns false and does not Activate when Ent.ACF is not set, and Entity is a Weapon",
            func = function( state )
                local ent = state.ent
                ent.ACF = nil
                ent.GetClass = function() return "prop_physics2" end
                ent.IsWeapon = function() return true end

                local activate = stub( ACF, "Activate" )

                expect( ACF.Check( ent ) ).to.beFalse()
                expect( activate ).notTo.haveBeenCalled()
            end
        },

        {
            name = "Returns false and does not Activate when Ent.ACF is not set, and Entity has a func_ class",
            func = function( state )
                local ent = state.ent
                ent.ACF = nil
                ent.GetClass = function() return "func_test" end

                local activate = stub( ACF, "Activate" )

                expect( ACF.Check( ent ) ).to.beFalse()
                expect( activate ).notTo.haveBeenCalled()
            end
        },

        {
            name = "Calls Activate if Entity.ACF is not set",
            func = function( state )
                local ent = state.ent
                ent.ACF = nil

                local activate = stub( ACF, "Activate" ).with( function( e )
                    e.ACF = { Type = "Test" }
                end )

                expect( ACF.Check( ent ) ).to.equal( "Test" )
                expect( activate ).to.haveBeenCalled()
            end
        },

        {
            name = "Calls Activate if ForceUpdate param is set",
            func = function( state )
                local ent = state.ent

                local activate = stub( ACF, "Activate" ).with( function( e )
                    e.ACF = { Type = "Test" }
                end )

                expect( ACF.Check( ent, true ) ).to.equal( "Test" )
                expect( activate ).to.haveBeenCalled()
            end
        },

        {
            name = "Calls Activate if Entity.ACF.Mass differs from PhysObj",
            func = function( state )
                local ent = state.ent
                ent.ACF.Mass = ent.ACF.Mass + 1

                local activate = stub( ACF, "Activate" ).with( function( e )
                    e.ACF = { Type = "Test" }
                end )

                expect( ACF.Check( ent ) ).to.equal( "Test" )
                expect( activate ).to.haveBeenCalled()
            end
        },

        {
            name = "Calls Activate if Entity.ACF.PhysObj differs from PhysObj",
            func = function( state )
                local ent = state.ent
                ent.ACF.PhysObj = {}

                local activate = stub( ACF, "Activate" ).with( function( e )
                    e.ACF = { Type = "Test" }
                end )

                expect( ACF.Check( ent ) ).to.equal( "Test" )
                expect( activate ).to.haveBeenCalled()
            end
        },

    }
}
