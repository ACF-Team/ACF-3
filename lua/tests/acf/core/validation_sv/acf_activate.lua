return {
    groupName = "ACF.Activate",

    beforeEach = function( state )
        local physObj = {
            IsValid = function() return true end
        }

        state.ent = {
            ACF = {},
            GetPhysicsObject = function() return physObj end
        }
    end,

    cases = {
        {
            name = "Sets up the ACF table if Entity is valid",
            func = function( state )
                local ent = state.ent
                ent.ACF = nil

                stub( ACF, "GetEntityType" ).returns( "Prop" )
                stub( ACF, "UpdateArea" ).returns( 1 )
                stub( ACF, "UpdateThickness" ).returns( 1 )

                ACF.Activate( ent )

                expect( ent.ACF ).to.exist()
            end
        },

        {
            name = "Does not set up ACF table if Entity has invalid physics object",
            func = function( state )
                local ent = state.ent
                ent.ACF = nil
                ent.GetPhysicsObject = function() return nil end

                ACF.Activate( ent )

                expect( ent.ACF ).notTo.exist()
            end
        },

        {
            name = "Runs the Entity's ACF_Activate method if present",
            func = function( state )
                local ent = state.ent
                ent.ACF_Activate = stub()

                stub( ACF, "GetEntityType" ).returns( "TestType" )

                ACF.Activate( ent )
                expect( ent.ACF_Activate ).to.haveBeenCalled()
                expect( ent.ACF.Type ).to.equal( "TestType" )
            end
        },

        {
            -- Sort of a Snapshot test to check for calculation changes
            name = "Sets the proper values for a 1x1x1 Cube",
            func = function( state )
                local function roundValues( t )
                    for key, value in pairs( t ) do
                        if isnumber( value ) then
                            t[key] = math.Round( value, 6 )
                        end
                    end
                end

                -- Acquired by spawning a 1x1x1 cube on plain sandbox and running ACF.Activate on it
                local expected = {
                    Area      = 45749.315111603,
                    Armour    = 1.7934974950143,
                    Ductility = 0,
                    Health    = 172.83458674576,
                    Mass      = 64,
                    MaxArmour = 1.7934974950143,
                    MaxHealth = 172.83458674576,
                }
                roundValues( expected )

                -- Set up the cube
                state.cube = ents.Create( "prop_physics" )
                local cube = state.cube

                cube:SetModel( "models/hunter/blocks/cube1x1x1.mdl" )
                cube:SetPos( Vector( 0, 0, 0 ) )
                cube:Spawn()

                ACF.Activate( cube )

                -- Run the expectations
                expect( cube.ACF ).to.exist()

                local actual = cube.ACF
                roundValues( actual )

                expect( actual.Area ).to.equal( expected.Area )
                expect( actual.Armour ).to.equal( expected.Armour )
                expect( actual.Ductility ).to.equal( expected.Ductility )
                expect( actual.Health ).to.equal( expected.Health )
                expect( actual.Mass ).to.equal( expected.Mass )
                expect( actual.MaxArmour ).to.equal( expected.MaxArmour )
                expect( actual.MaxHealth ).to.equal( expected.MaxHealth )
            end,

            cleanup = function( state )
                if IsValid( state.cube ) then
                    SafeRemoveEntity( state.cube )
                end
            end
        }
    }
}
