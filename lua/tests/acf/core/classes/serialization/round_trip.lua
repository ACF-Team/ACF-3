local Classes       = ACF.Classes
local Serialization = Classes.Serialization
local Prefix        = "ACF.Tests.RoundTrip" .. math.random( 1e8 ) .. "."

local PART    = Prefix .. "Part"
local PART_A  = Prefix .. "Part.A"
local PART_B  = Prefix .. "Part.B"
local OUTSIDE = Prefix .. "Outside"
local THING   = Prefix .. "Thing"

local function DefineTestClasses()
    Classes.DefineClass( PART, function() end )
    Classes.DefineClass( PART_A, PART, function()
        MENU_FIELD( "Number", "Size", { Default = 1 } )
    end )
    Classes.DefineClass( PART_B, PART, function()
        MENU_FIELD( "String", "Label", { Default = "b" } )
    end )
    Classes.DefineClass( OUTSIDE, function() end )

    Classes.DefineClass( THING, function()
        MENU_FIELD( "Number", "Count", { Min = 0, Max = 10, Decimals = 1, Default = 5 } )
        MENU_FIELD( "Boolean", "Flag", { Default = false } )
        MENU_FIELD( "String", "Text", { Default = "text" } )
        MENU_FIELD( "Vector", "Offset", { Default = Vector( 1, 2, 3 ) } )
        MENU_FIELD( "Angle", "Turn", { Default = Angle( 0, 90, 0 ) } )
        MENU_FIELD( "Number[]", "List", { Default = 0 } )
        MENU_FIELD( PART, "Part", { OnlyAllowSubtypes = true, InstantiateTypeForDefault = PART_A } )
    end )
end

local function RemoveTestClasses()
    for ClassName in pairs( Classes.Registry ) do
        if ClassName:sub( 1, #Prefix ) == Prefix then
            Classes.Registry[ClassName] = nil
        end
    end
end

local function Thing()
    return Classes.GetTypeByName( THING )
end

local function RoundTrip( Instance )
    return Serialization.DeserializePartial( Thing(), Serialization.Serialize( Thing(), Instance ) )
end

return {
    groupName = "ACF.Classes.Serialization round trip",

    beforeAll = DefineTestClasses,
    afterAll  = RemoveTestClasses,

    cases = {
        {
            name = "Serialize then DeserializePartial gives back the same scalar values",
            func = function()
                local Instance = Thing()()
                Instance.Count  = 7.5
                Instance.Flag   = true
                Instance.Text   = "hello"
                Instance.Offset = Vector( 4, 5, 6 )
                Instance.Turn   = Angle( 10, 20, 30 )

                local Copy = RoundTrip( Instance )

                expect( Copy.Count ).to.equal( 7.5 )
                expect( Copy.Flag ).to.beTrue()
                expect( Copy.Text ).to.equal( "hello" )
                expect( Copy.Offset ).to.equal( Vector( 4, 5, 6 ) )
                expect( Copy.Turn ).to.equal( Angle( 10, 20, 30 ) )
            end
        },

        {
            name = "Arrays keep their values and order",
            func = function()
                local Instance = Thing()()
                Instance.List = { 3, 1, 2 }

                local Copy = RoundTrip( Instance )

                expect( #Copy.List ).to.equal( 3 )
                expect( Copy.List[1] ).to.equal( 3 )
                expect( Copy.List[2] ).to.equal( 1 )
                expect( Copy.List[3] ).to.equal( 2 )
            end
        },

        {
            name = "Nested class fields keep their type and values",
            func = function()
                local Instance = Thing()()
                Instance.Part = Classes.GetTypeByName( PART_B )()
                Instance.Part.Label = "changed"

                local Copy = RoundTrip( Instance )

                expect( Copy.Part:GetType() ).to.equal( Classes.GetTypeByName( PART_B ) )
                expect( Copy.Part.Label ).to.equal( "changed" )
            end
        },

        {
            name = "Deserializing gives a new nested instance instead of reusing the original",
            func = function()
                local Instance = Thing()()

                local Copy = RoundTrip( Instance )

                expect( rawequal( Copy.Part, Instance.Part ) ).to.beFalse()
            end
        },

        {
            name = "Missing fields get their defaults",
            func = function()
                local Copy = Serialization.DeserializePartial( Thing(), {} )

                expect( Copy.Count ).to.equal( 5 )
                expect( Copy.Flag ).to.beFalse()
                expect( Copy.Offset ).to.equal( Vector( 1, 2, 3 ) )
                expect( Copy.Part:GetType() ).to.equal( Classes.GetTypeByName( PART_A ) )
            end
        },

        {
            name = "Numbers are clamped and rounded",
            func = function()
                local High = Serialization.DeserializePartial( Thing(), { Count = 50 } )
                local Low  = Serialization.DeserializePartial( Thing(), { Count = -5 } )
                local Long = Serialization.DeserializePartial( Thing(), { Count = 3.14159 } )

                expect( High.Count ).to.equal( 10 )
                expect( Low.Count ).to.equal( 0 )
                expect( Long.Count ).to.equal( 3.1 )
            end
        },

        {
            name = "A nested type of the wrong family falls back to the default type",
            func = function()
                local Copy = Serialization.DeserializePartial( Thing(), { Part = { Type = OUTSIDE, Data = {} } } )

                expect( Copy.Part:GetType() ).to.equal( Classes.GetTypeByName( PART_A ) )
            end
        },

        {
            name = "An unknown nested type falls back to the default type",
            func = function()
                local Copy = Serialization.DeserializePartial( Thing(), { Part = { Type = Prefix .. "Missing", Data = {} } } )

                expect( Copy.Part:GetType() ).to.equal( Classes.GetTypeByName( PART_A ) )
            end
        },

        {
            name = "The base type is rejected when only subtypes are allowed",
            func = function()
                local Copy = Serialization.DeserializePartial( Thing(), { Part = { Type = PART, Data = {} } } )

                expect( Copy.Part:GetType() ).to.equal( Classes.GetTypeByName( PART_A ) )
            end
        },
    }
}
