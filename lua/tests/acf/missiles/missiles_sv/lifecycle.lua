local function NewSpec()
    return ACF.Missiles.CreateSpec( { Missile = "AT-3", AmmoType = "ACF.Ammunition.HEAT" } )
end

local function NewMissile( State, Options )
    Options = Options or {}
    Options.Owner = Options.Owner or game.GetWorld()
    Options.Pos   = Options.Pos or Vector( 0, 0, 2000 )
    Options.Ang   = Options.Ang or Angle( 0, 0, 0 )

    local Missile = ACF.Missiles.Create( NewSpec(), Options )
    State.Missile = Missile

    return Missile
end

local function RemoveMissile( State )
    if IsValid( State.Missile ) then
        State.Missile:Remove()
    end
end

return {
    groupName = "ACF.Missiles lifecycle",

    cases = {
        {
            name = "Create spawns an unlaunched, inactive acf_missile",
            func = function( State )
                local Missile = NewMissile( State )

                expect( Missile ).to.beValid()
                expect( Missile:GetClass() ).to.equal( "acf_missile" )
                expect( Missile.Launched ).to.beNil()
                expect( ACF.Missiles.IsActive( Missile ) ).to.beFalse()
            end,
            cleanup = RemoveMissile
        },

        {
            name = "Create places the missile at the given world position",
            func = function( State )
                local Missile = NewMissile( State, { Pos = Vector( 10, 20, 2000 ) } )

                expect( Missile:GetPos():Distance( Vector( 10, 20, 2000 ) ) ).to.beLessThan( 0.1 )
            end,
            cleanup = RemoveMissile
        },

        {
            name = "Create returns the spec it was built from",
            func = function( State )
                local Spec    = NewSpec()
                local Missile = ACF.Missiles.Create( Spec, { Owner = game.GetWorld(), Pos = Vector( 0, 0, 2000 ), Ang = Angle() } )
                State.Missile = Missile

                expect( Missile:GetSpec() ).to.equal( Spec )
            end,
            cleanup = RemoveMissile
        },

        {
            name = "Missiles from one spec get their own guidance, fuze and navigation",
            func = function( State )
                local Spec = NewSpec()
                local A    = ACF.Missiles.Create( Spec, { Owner = game.GetWorld(), Pos = Vector( 0, 0, 2000 ), Ang = Angle() } )
                local B    = ACF.Missiles.Create( Spec, { Owner = game.GetWorld(), Pos = Vector( 0, 50, 2000 ), Ang = Angle() } )
                State.Missiles = { A, B }

                expect( A.GuidanceData ).notTo.equal( B.GuidanceData )
                expect( A.FuzeData ).notTo.equal( B.FuzeData )
                expect( A.NavigationData ).notTo.equal( B.NavigationData )
                expect( A.GuidanceData ).notTo.equal( Spec.Guidance )
            end,
            cleanup = function( State )
                for _, Missile in ipairs( State.Missiles or {} ) do
                    if IsValid( Missile ) then Missile:Remove() end
                end
            end
        },

        {
            name = "Create fails on an invalid spec",
            func = function()
                local Missile, Err = ACF.Missiles.Create( {}, { Owner = game.GetWorld(), Pos = Vector(), Ang = Angle() } )

                expect( Missile ).to.beNil()
                expect( Err ).to.equal( "Invalid spec" )
            end
        },

        {
            name = "Create fails without an owner",
            func = function()
                local Missile, Err = ACF.Missiles.Create( NewSpec(), { Pos = Vector(), Ang = Angle() } )

                expect( Missile ).to.beNil()
                expect( Err ).to.equal( "Options.Owner must be a valid player or the world" )
            end
        },

        {
            name = "Create fails without a position",
            func = function()
                local Missile, Err = ACF.Missiles.Create( NewSpec(), { Owner = game.GetWorld(), Ang = Angle() } )

                expect( Missile ).to.beNil()
                expect( Err ).to.equal( "Options.Pos must be a vector" )
            end
        },

        {
            name = "Create returns false when ACF_PreSpawnEntity blocks it",
            func = function()
                hook.Add( "ACF_PreSpawnEntity", "ACF Missiles Test Block", function( Class )
                    if Class == "acf_missile" then return false end
                end )

                local Missile = ACF.Missiles.Create( NewSpec(), { Owner = game.GetWorld(), Pos = Vector(), Ang = Angle() } )

                expect( Missile ).to.beFalse()
            end
        },

        {
            name = "Launch makes the missile active and unparents it",
            func = function( State )
                local Parent = ents.Create( "prop_physics" )
                Parent:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
                Parent:SetPos( Vector( 0, 0, 2000 ) )
                Parent:Spawn()
                State.Parent = Parent

                local Missile = NewMissile( State, { Parent = Parent } )
                ACF.Missiles.Launch( Missile )

                expect( Missile.Launched ).to.beTrue()
                expect( ACF.Missiles.IsActive( Missile ) ).to.beTrue()
                expect( IsValid( Missile:GetParent() ) ).to.beFalse()
            end,
            cleanup = function( State )
                RemoveMissile( State )
                if IsValid( State.Parent ) then State.Parent:Remove() end
            end
        },

        {
            name = "Launch flies along the given direction, adding the given velocity",
            func = function( State )
                local Missile = NewMissile( State )
                local Boost   = Missile.SpeedBoost

                ACF.Missiles.Launch( Missile, { Direction = Vector( 0, 0, 1 ), Velocity = Vector( 100, 0, 0 ) } )

                expect( Missile.ACF_Velocity.x ).to.aboutEqual( 100, 0.01 )
                expect( Missile.ACF_Velocity.z ).to.aboutEqual( Boost, 0.01 )
            end,
            cleanup = RemoveMissile
        },

        {
            name = "Launch does nothing on an already launched missile",
            func = function( State )
                local Missile = NewMissile( State )
                local Hook    = stub()

                ACF.Missiles.Launch( Missile )
                hook.Add( "ACF_OnLaunchMissile", "ACF Missiles Test Launch", Hook )
                ACF.Missiles.Launch( Missile )

                expect( Hook ).wasNot.called()
            end,
            cleanup = RemoveMissile
        },

        {
            name = "A misfired missile is not active",
            func = function( State )
                local Missile = NewMissile( State )

                ACF.Missiles.Launch( Missile, { Misfire = true } )

                expect( Missile.Detonated ).to.beTrue()
                expect( ACF.Missiles.IsActive( Missile ) ).to.beFalse()
            end,
            cleanup = RemoveMissile
        },

        {
            name = "Detonate blows the missile up",
            func = function( State )
                local Missile = NewMissile( State )
                ACF.Missiles.Launch( Missile )

                ACF.Missiles.Detonate( Missile )

                expect( Missile.Detonated ).to.beTrue()
                expect( ACF.Missiles.IsActive( Missile ) ).to.beFalse()
            end,
            cleanup = RemoveMissile
        },

        {
            name = "Detonate does nothing when ACF_PreExplodeMissile cancels it",
            func = function( State )
                local Missile = NewMissile( State )
                ACF.Missiles.Launch( Missile )

                hook.Add( "ACF_PreExplodeMissile", "ACF Missiles Test Cancel", function() return false end )
                ACF.Missiles.Detonate( Missile )

                expect( Missile.Detonated ).to.beNil()
            end,
            cleanup = RemoveMissile
        },

        {
            name = "GetLaunchOrigin falls back to where the missile was launched",
            func = function( State )
                local Missile = NewMissile( State, { Pos = Vector( 5, 5, 2000 ) } )
                ACF.Missiles.Launch( Missile )

                local Pos = Missile:GetLaunchOrigin()

                expect( Pos:Distance( Vector( 5, 5, 2000 ) ) ).to.beLessThan( 0.1 )
            end,
            cleanup = RemoveMissile
        },

        {
            name = "GetLaunchOrigin uses the launcher's origin when it has one",
            func = function( State )
                local Launcher = { GetLaunchOrigin = function() return Vector( 1, 2, 3 ), Angle() end }
                local Missile  = NewMissile( State, { Launcher = Launcher } )

                local Pos = Missile:GetLaunchOrigin()

                expect( Pos ).to.equal( Vector( 1, 2, 3 ) )
            end,
            cleanup = RemoveMissile
        },

        {
            name = "The launcher is told when an unlaunched missile is removed",
            async = true,
            timeout = 1,
            func = function( State )
                local Removed  = stub()
                local Missile  = NewMissile( State, { Launcher = { OnMissileRemoved = Removed } } )

                Missile:Remove()

                timer.Simple( 0.1, function()
                    expect( Removed ).was.called()
                    expect( Removed.callHistory[1][3] ).to.beFalse()

                    done()
                end )
            end,
            cleanup = RemoveMissile
        },

        {
            name = "GetLauncherEntity returns the launcher's entity",
            func = function( State )
                local Prop = ents.Create( "prop_physics" )
                Prop:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
                Prop:Spawn()
                State.Prop = Prop

                local Missile = NewMissile( State, { Launcher = { GetEntity = function() return Prop end } } )

                expect( Missile:GetLauncherEntity() ).to.equal( Prop )
            end,
            cleanup = function( State )
                RemoveMissile( State )
                if IsValid( State.Prop ) then State.Prop:Remove() end
            end
        },

        {
            name = "GetLauncherEntity is nil without a launcher",
            func = function( State )
                local Missile = NewMissile( State )

                expect( Missile:GetLauncherEntity() ).to.beNil()
            end,
            cleanup = RemoveMissile
        },

        {
            name = "The spawn hooks get the class name, the owner or missile, and the spec",
            func = function( State )
                local Pre, Post = {}, {}

                hook.Add( "ACF_PreSpawnEntity", "ACF Missiles Test Args", function( ... ) Pre = { ... } end )
                hook.Add( "ACF_OnSpawnEntity", "ACF Missiles Test Args", function( ... ) Post = { ... } end )

                local Spec    = NewSpec()
                local Missile = ACF.Missiles.Create( Spec, { Owner = game.GetWorld(), Pos = Vector( 0, 0, 2000 ), Ang = Angle() } )
                State.Missile = Missile

                expect( Pre[1] ).to.equal( "acf_missile" )
                expect( Pre[2] ).to.equal( game.GetWorld() )
                expect( Pre[3] ).to.equal( Spec )
                expect( Post[1] ).to.equal( "acf_missile" )
                expect( Post[2] ).to.equal( Missile )
                expect( Post[3] ).to.equal( Spec )
            end,
            cleanup = RemoveMissile
        },

        {
            name = "Launch adds the launcher's filter to the missile's filter",
            func = function( State )
                local Ignored  = game.GetWorld()
                local Missile  = NewMissile( State, { Launcher = { GetMissileFilter = function() return { Ignored } end } } )

                ACF.Missiles.Launch( Missile )

                expect( table.HasValue( Missile.Filter, Ignored ) ).to.beTrue()
            end,
            cleanup = RemoveMissile
        },
    }
}
