local Classes = ACF.Classes
local Prefix  = "ACF.Tests.Subtypes" .. math.random( 1e8 ) .. "."

local ROOT       = Prefix .. "Root"
local CHILD      = Prefix .. "Root.Child"
local SIBLING    = Prefix .. "Root.Sibling"
local GRANDCHILD = Prefix .. "Root.Child.Grandchild"
local OTHER      = Prefix .. "Other"

local function DefineTestClasses()
    Classes.DefineClass( ROOT, function() end )
    Classes.DefineClass( CHILD, ROOT, function() end )
    Classes.DefineClass( SIBLING, ROOT, function() end )
    Classes.DefineClass( GRANDCHILD, CHILD, function() end )
    Classes.DefineClass( OTHER, function() end )
end

local function RemoveTestClasses()
    for ClassName in pairs( Classes.Registry ) do
        if ClassName:sub( 1, #Prefix ) == Prefix then
            Classes.Registry[ClassName] = nil
        end
    end
end

local function Type( ClassName )
    return Classes.GetTypeByName( ClassName )
end

return {
    groupName = "ACF.Classes subtype lookups",

    beforeAll = DefineTestClasses,
    afterAll  = RemoveTestClasses,

    cases = {
        {
            name = "GetSubtypes includes children and grandchildren, keyed by name",
            func = function()
                local Subtypes = Classes.GetSubtypes( ROOT )

                expect( Subtypes[CHILD] ).to.equal( Type( CHILD ) )
                expect( Subtypes[SIBLING] ).to.equal( Type( SIBLING ) )
                expect( Subtypes[GRANDCHILD] ).to.equal( Type( GRANDCHILD ) )
            end
        },

        {
            name = "GetSubtypes does not include the class itself or unrelated classes",
            func = function()
                local Subtypes = Classes.GetSubtypes( ROOT )

                expect( Subtypes[ROOT] ).to.beNil()
                expect( Subtypes[OTHER] ).to.beNil()
            end
        },

        {
            name = "GetSubtypesAsList lists every subtype once",
            func = function()
                local Seen = {}

                for _, Class in ipairs( Classes.GetSubtypesAsList( ROOT ) ) do
                    local ClassName = Classes.GetTypeName( Class )
                    Seen[ClassName] = ( Seen[ClassName] or 0 ) + 1
                end

                expect( Seen[CHILD] ).to.equal( 1 )
                expect( Seen[SIBLING] ).to.equal( 1 )
                expect( Seen[GRANDCHILD] ).to.equal( 1 )
                expect( table.Count( Seen ) ).to.equal( 3 )
            end
        },

        {
            name = "GetSubtypeFQNs lists the same names as GetSubtypesAsList, in the same order",
            func = function()
                local Names = Classes.GetSubtypeFQNs( ROOT )
                local List  = Classes.GetSubtypesAsList( ROOT )

                expect( #Names ).to.equal( #List )

                for Index, Class in ipairs( List ) do
                    expect( Names[Index] ).to.equal( Classes.GetTypeName( Class ) )
                end
            end
        },

        {
            name = "Subtype lookups on an unknown class return an empty table",
            func = function()
                expect( next( Classes.GetSubtypes( Prefix .. "Missing" ) ) ).to.beNil()
                expect( #Classes.GetSubtypesAsList( Prefix .. "Missing" ) ).to.equal( 0 )
                expect( #Classes.GetSubtypeFQNs( Prefix .. "Missing" ) ).to.equal( 0 )
            end
        },

        {
            name = "GetSubtypeByName finds a grandchild",
            func = function()
                expect( Classes.GetSubtypeByName( ROOT, GRANDCHILD ) ).to.equal( Type( GRANDCHILD ) )
            end
        },

        {
            name = "GetSubtypeByName returns nil outside the hierarchy, for the class itself, or an unknown base",
            func = function()
                expect( Classes.GetSubtypeByName( ROOT, OTHER ) ).to.beNil()
                expect( Classes.GetSubtypeByName( ROOT, ROOT ) ).to.beNil()
                expect( Classes.GetSubtypeByName( Prefix .. "Missing", CHILD ) ).to.beNil()
            end
        },

        {
            name = "GetChildren only includes direct children",
            func = function()
                local Children = Classes.GetChildren( Type( ROOT ) )

                expect( Children[CHILD] ).to.equal( Type( CHILD ) )
                expect( Children[SIBLING] ).to.equal( Type( SIBLING ) )
                expect( Children[GRANDCHILD] ).to.beNil()
            end
        },

        {
            name = "GetBaseClass returns the parent, or nil for a root class",
            func = function()
                expect( Classes.GetBaseClass( Type( GRANDCHILD ) ) ).to.equal( Type( CHILD ) )
                expect( Classes.GetBaseClass( Type( ROOT ) ) ).to.beNil()
            end
        },

        {
            name = "IsAssignableTo follows the parent chain upwards only",
            func = function()
                expect( Classes.IsAssignableTo( Type( GRANDCHILD ), Type( ROOT ) ) ).to.beTrue()
                expect( Classes.IsAssignableTo( Type( CHILD ), Type( CHILD ) ) ).to.beTrue()
                expect( Classes.IsAssignableTo( Type( ROOT ), Type( CHILD ) ) ).to.beFalse()
                expect( Classes.IsAssignableTo( Type( SIBLING ), Type( CHILD ) ) ).to.beFalse()
                expect( Classes.IsAssignableTo( Type( OTHER ), Type( ROOT ) ) ).to.beFalse()
            end
        },

        {
            name = "IsAssignableFrom is IsAssignableTo with the arguments swapped",
            func = function()
                expect( Classes.IsAssignableFrom( Type( ROOT ), Type( GRANDCHILD ) ) ).to.beTrue()
                expect( Classes.IsAssignableFrom( Type( GRANDCHILD ), Type( ROOT ) ) ).to.beFalse()
            end
        },

        {
            name = "GetTypeName and GetTypeUnqualifiedName return the full and short names",
            func = function()
                expect( Classes.GetTypeName( Type( GRANDCHILD ) ) ).to.equal( GRANDCHILD )
                expect( Classes.GetTypeUnqualifiedName( Type( GRANDCHILD ) ) ).to.equal( "Grandchild" )
            end
        },

        {
            name = "An instance's GetType returns its class",
            func = function()
                local Instance = Type( GRANDCHILD )()

                expect( Instance:GetType() ).to.equal( Type( GRANDCHILD ) )
            end
        },
    }
}
