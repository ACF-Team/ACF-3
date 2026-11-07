local Classes = ACF.Classes

local PART   = "ACF.Tests.Classes.Part"
local PART_A = "ACF.Tests.Classes.Part.A"
local THING  = "ACF.Tests.Classes.Thing"
local CHILD  = "ACF.Tests.Classes.Thing.Child"

local function DefineTestClasses()
    Classes.DefineClass( PART, function() end )
    Classes.DefineClass( PART_A, PART, function() end )

    Classes.DefineClass( THING, function( CLASS )
        CLASS.Static   = "static"
        CLASS.Shadowed = "class value"

        MENU_FIELD( "Number", "Count", { Default = 5 } )
        FIELD( "Boolean", "Flag", { Default = false } )
        FIELD( "String", "Shadowed", { Default = "field value" } )
        FIELD( "Vector", "Offset", { DefaultFactory = function() return Vector( 1, 2, 3 ) end } )
        MENU_FIELD( PART, "Part", { OnlyAllowSubtypes = true, InstantiateTypeForDefault = PART_A } )

        function CLASS:new()
            self.CountInConstructor = self.Count
            self.PartInConstructor  = rawget( self, "Part" )
        end

        function CLASS:Method()
            return "method"
        end
    end )

    Classes.DefineClass( CHILD, THING, function()
        MENU_FIELD( "Number", "Count", { Default = 10 } )
        FIELD( "Number", "Extra", { Default = 1 } )
    end )
end

local function RemoveTestClasses()
    for _, Name in ipairs( { CHILD, THING, PART_A, PART } ) do
        Classes.Registry[Name] = nil
    end
end

local function New( Name )
    return Classes.GetTypeByName( Name )()
end

return {
    groupName = "ACF.Classes instantiation",

    beforeAll = DefineTestClasses,
    afterAll  = RemoveTestClasses,

    cases = {
        {
            name = "An instance owns its field defaults",
            func = function()
                local Thing = New( THING )

                expect( rawget( Thing, "Count" ) ).to.equal( 5 )
                expect( rawget( Thing, "Flag" ) ).to.beFalse()
                expect( rawget( Thing, "Offset" ) ).to.equal( Vector( 1, 2, 3 ) )
                expect( rawget( Thing, "Part" ) ).to.exist()
            end
        },

        {
            name = "Object defaults are instances of the default type",
            func = function()
                local Thing = New( THING )

                expect( Thing.Part:GetType() ).to.equal( Classes.GetTypeByName( PART_A ) )
            end
        },

        {
            name = "Two instances get separate object defaults",
            func = function()
                local A = New( THING )
                local B = New( THING )

                expect( rawequal( A.Part, B.Part ) ).to.beFalse()
                expect( rawequal( A.Offset, B.Offset ) ).to.beFalse()
            end
        },

        {
            name = "Making an instance does not change another instance's defaults",
            func = function()
                local A      = New( THING )
                local Part   = A.Part
                local Offset = A.Offset

                New( THING )

                expect( rawequal( A.Part, Part ) ).to.beTrue()
                expect( rawequal( A.Offset, Offset ) ).to.beTrue()
            end
        },

        {
            name = "Changing one instance's default object leaves other instances alone",
            func = function()
                local A = New( THING )
                local B = New( THING )

                A.Offset.x = 99
                A.Part.Marked = true

                expect( B.Offset.x ).to.equal( 1 )
                expect( B.Part.Marked ).to.beNil()
            end
        },

        {
            name = "Making an instance does not write field defaults onto the class",
            func = function()
                New( THING )

                local Class = Classes.GetTypeByName( THING )

                expect( rawget( Class, "Count" ) ).to.beNil()
                expect( rawget( Class, "Offset" ) ).to.beNil()
                expect( rawget( Class, "Part" ) ).to.beNil()
            end
        },

        {
            name = "A class static is not overwritten by a field with the same name",
            func = function()
                local Thing = New( THING )

                expect( Classes.GetTypeByName( THING ).Shadowed ).to.equal( "class value" )
                expect( Thing.Shadowed ).to.equal( "field value" )
            end
        },

        {
            name = "Setting a field to nil clears it",
            func = function()
                local Thing = New( THING )

                Thing.Part = nil

                expect( Thing.Part ).to.beNil()
            end
        },

        {
            name = "The constructor runs after the defaults are set on the instance",
            func = function()
                local Thing = New( THING )

                expect( Thing.CountInConstructor ).to.equal( 5 )
                expect( Thing.PartInConstructor ).to.exist()
            end
        },

        {
            name = "Instances still read class statics and methods",
            func = function()
                local Thing = New( THING )

                expect( Thing.Static ).to.equal( "static" )
                expect( Thing:Method() ).to.equal( "method" )
                expect( Thing:GetType() ).to.equal( Classes.GetTypeByName( THING ) )
            end
        },

        {
            name = "A subclass instance gets inherited defaults and its own overrides",
            func = function()
                local Child = New( CHILD )

                expect( rawget( Child, "Count" ) ).to.equal( 10 )
                expect( rawget( Child, "Extra" ) ).to.equal( 1 )
                expect( rawget( Child, "Flag" ) ).to.beFalse()
                expect( Child.Part:GetType() ).to.equal( Classes.GetTypeByName( PART_A ) )
            end
        },

        {
            name = "DeserializePartial gives each instance its own object defaults when the data omits them",
            func = function()
                local Class = Classes.GetTypeByName( THING )
                local A = Classes.Serialization.DeserializePartial( Class, {} )
                local B = Classes.Serialization.DeserializePartial( Class, {} )

                expect( rawget( A, "Part" ) ).to.exist()
                expect( rawequal( A.Part, B.Part ) ).to.beFalse()
            end
        },

        {
            name = "DeserializeInto keeps an instance's own object defaults when the data omits them",
            func = function()
                local Class = Classes.GetTypeByName( THING )
                local A = Class()
                local B = Class()

                Classes.Serialization.DeserializeInto( Class, A, { Count = 7 } )
                New( THING )

                expect( A.Count ).to.equal( 7 )
                expect( rawget( A, "Part" ) ).to.exist()
                expect( rawequal( A.Part, B.Part ) ).to.beFalse()
            end
        },

        {
            name = "Missile weapon instances get their own guidance and fuze",
            func = function()
                local Missile = Classes.GetTypeByName( "ACF.Missiles.AntiTankGuided.AT-3" )
                local A = Missile()
                local B = Missile()

                expect( rawequal( A.Guidance, B.Guidance ) ).to.beFalse()
                expect( rawequal( A.Fuze, B.Fuze ) ).to.beFalse()
            end
        },
    }
}
