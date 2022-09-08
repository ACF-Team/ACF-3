return {
    groupName = "ACF.Networking.CreateSender",
    cases = {
        {
            name = "Creates a sender with valid data",
            func = function()
                local Name = "ValidName"
                local Function = function() end

                ACF.Networking.CreateSender( Name, Function )

                local Sender = ACF.Networking.Sender[Name]
                expect( Sender ).to.equal( Function )
            end
        },

        {
            name = "Does not create a sender with nil Name",
            func = function()
                local Name = nil
                local Function = stub()

                local function CreateSender()
                    ACF.Networking.CreateSender( Name, Function )
                end

                -- Sender[nil] = blah would fail
                expect( CreateSender ).to.succeed()
            end
        },

        {
            name = "Does not create a sender with a numbered name",
            func = function()
                local Name = 5
                local Function = stub()

                ACF.Networking.CreateSender( Name, Function )

                local Sender = ACF.Networking.Sender[Name]
                expect( Sender ).toNot.exist()
            end
        },

        {
            name = "Does not create a sender with a nil Function",
            func = function()
                local Name = "Example"
                local Function = nil

                ACF.Networking.CreateSender( Name, Function )

                local Sender = ACF.Networking.Sender[Name]
                expect( Sender ).to.beNil()
            end
        },

        {
            name = "Does not create a sender with a string Function",
            func = function()
                local Name = "Example"
                local Function = "Example"

                ACF.Networking.CreateSender( Name, Function )

                local Sender = ACF.Networking.Sender[Name]
                expect( Sender ).to.beNil()
            end
        }
    }
}
