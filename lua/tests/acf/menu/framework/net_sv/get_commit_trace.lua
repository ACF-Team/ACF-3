return {
    groupName = "ACF.Menu.GetCommitTrace",

    beforeEach = function( State )
        State.Trace = { HitPos = Vector(), HitNormal = Vector( 0, 0, 1 ) }
        State.Allowed = true
        State.Mode = "acf_menu"
        State.Class = "gmod_tool"

        State.Tool = {
            Allowed = function() return State.Allowed end
        }

        State.Weapon = {
            IsValid = function() return true end,
            GetClass = function() return State.Class end,
            GetMode = function() return State.Mode end,
            GetToolObject = function() return State.Tool end,
            DoToolTrace = function() return State.Trace end,
        }

        State.Player = {
            IsValid = function() return true end,
            GetActiveWeapon = function() return State.Weapon end,
        }
    end,

    cases = {
        {
            name = "Returns the tool trace when the tool is allowed",
            func = function( State )
                stub( gamemode, "Call" ).returns( true )

                expect( ACF.Menu.GetCommitTrace( State.Player, 1 ) ).to.equal( State.Trace )
            end
        },

        {
            name = "Runs CanTool with the acf_menu mode and the given button",
            func = function( State )
                local CanTool = stub( gamemode, "Call" ).returns( true )

                ACF.Menu.GetCommitTrace( State.Player, 2 )

                expect( CanTool ).was.called()

                local Args = CanTool.callHistory[1]
                expect( Args[1] ).to.equal( "CanTool" )
                expect( Args[2] ).to.equal( State.Player )
                expect( Args[3] ).to.equal( State.Trace )
                expect( Args[4] ).to.equal( "acf_menu" )
                expect( Args[5] ).to.equal( State.Tool )
                expect( Args[6] ).to.equal( 2 )
            end
        },

        {
            name = "Returns nil when CanTool denies the action",
            func = function( State )
                stub( gamemode, "Call" ).returns( false )

                expect( ACF.Menu.GetCommitTrace( State.Player, 1 ) ).to.beNil()
            end
        },

        {
            name = "Returns nil when the player isn't holding the toolgun",
            func = function( State )
                local CanTool = stub( gamemode, "Call" ).returns( true )
                State.Class = "weapon_physgun"

                expect( ACF.Menu.GetCommitTrace( State.Player, 1 ) ).to.beNil()
                expect( CanTool ).wasNot.called()
            end
        },

        {
            name = "Returns nil when the toolgun is on another mode",
            func = function( State )
                local CanTool = stub( gamemode, "Call" ).returns( true )
                State.Mode = "weld"

                expect( ACF.Menu.GetCommitTrace( State.Player, 1 ) ).to.beNil()
                expect( CanTool ).wasNot.called()
            end
        },

        {
            name = "Returns nil when the tool is disallowed by the server",
            func = function( State )
                local CanTool = stub( gamemode, "Call" ).returns( true )
                State.Allowed = false

                expect( ACF.Menu.GetCommitTrace( State.Player, 1 ) ).to.beNil()
                expect( CanTool ).wasNot.called()
            end
        },

        {
            name = "Returns nil for an invalid player",
            func = function()
                expect( ACF.Menu.GetCommitTrace( nil, 1 ) ).to.beNil()
            end
        },
    }
}
