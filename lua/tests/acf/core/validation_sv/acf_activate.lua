return {
    groupName = "ACF.Activate",

    beforeEach = function( State )
        local PhysObj = { IsValid = function() return true end }

        State.Ent = {
            ACF = {},
            GetPhysicsObject = function() return PhysObj end
        }
    end,

    cases = {
        {
            name = "Sets up the ACF table if Entity is valid",
            func = function( State )
                local Ent = State.Ent
                Ent.ACF = nil

                stub( ACF, "GetEntityType" ).returns( "Prop" )
                stub( ACF, "UpdateArea" ).returns( 1 )
                stub( ACF, "UpdateThickness" ).returns( 1 )

                ACF.Activate( Ent )

                expect( Ent.ACF ).to.exist()
            end
        },

        {
            name = "Does not set up ACF table if Entity has invalid physics object",
            func = function( State )
                local Ent = State.Ent
                Ent.ACF = nil
                Ent.GetPhysicsObject = function() return nil end

                ACF.Activate( Ent )

                expect( Ent.ACF ).notTo.exist()
            end
        },

        {
            name = "Runs the Entity's ACF_Activate method if present",
            func = function( State )
                local Ent = State.Ent
                Ent.ACF_Activate = stub()

                stub( ACF, "GetEntityType" ).returns( "TestType" )

                ACF.Activate( Ent )
                expect( Ent.ACF_Activate ).was.called()
                expect( Ent.ACF.Type ).to.equal( "TestType" )
            end
        },

        {
            -- Sort of a Snapshot test to check for calculation changes
            name = "Sets the proper values for a 1x1x1 Cube",
            func = function( State )
                local function roundValues( t )
                    for key, value in pairs( t ) do
                        if isnumber( value ) then
                            t[key] = math.Round( value, 6 )
                        end
                    end
                end

                -- Acquired by spawning a 1x1x1 cube on plain sandbox and running ACF.Activate on it
                local Expected = {
                    Area      = 45749.315111603,
                    Armour    = 1.7934974950143,
                    Ductility = 0,
                    Health    = 172.83458674576,
                    Mass      = 64,
                    MaxArmour = 1.7934974950143,
                    MaxHealth = 172.83458674576,
                }
                roundValues( Expected )

                -- Set up the cube
                State.Cube = ents.Create( "prop_physics" )
                local Cube = State.Cube

                Cube:SetModel( "models/hunter/blocks/cube1x1x1.mdl" )
                Cube:SetPos( Vector( 0, 0, 0 ) )
                Cube:Spawn()

                ACF.Activate( Cube )

                -- Run the expectations
                expect( Cube.ACF ).to.exist()

                local Actual = Cube.ACF
                roundValues( Actual )

                expect( Actual.Area ).to.equal( Expected.Area )
                expect( Actual.Armour ).to.equal( Expected.Armour )
                expect( Actual.Ductility ).to.equal( Expected.Ductility )
                expect( Actual.Health ).to.equal( Expected.Health )
                expect( Actual.Mass ).to.equal( Expected.Mass )
                expect( Actual.MaxArmour ).to.equal( Expected.MaxArmour )
                expect( Actual.MaxHealth ).to.equal( Expected.MaxHealth )
            end,

            cleanup = function( State )
                if IsValid( State.Cube ) then
                    SafeRemoveEntity( State.Cube )
                end
            end
        }
    }
}
