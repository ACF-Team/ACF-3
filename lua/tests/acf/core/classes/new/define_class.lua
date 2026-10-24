local Classes = ACF.Classes
local Prefix  = "ACF.Tests.DefineClass" .. math.random( 1e8 ) .. "."

local function Name( Suffix )
    return Prefix .. Suffix
end

local function Define( Suffix, BaseSuffix, OnInit )
    if BaseSuffix then
        return Classes.DefineClass( Name( Suffix ), Name( BaseSuffix ), OnInit or function() end )
    end

    return Classes.DefineClass( Name( Suffix ), OnInit or function() end )
end

local function CountSubtypes( Suffix )
    local Count = 0

    for _, Class in ipairs( Classes.GetSubtypesAsList( Name( Suffix ) ) ) do
        if Class then Count = Count + 1 end
    end

    return Count
end

local function RemoveTestClasses()
    for ClassName in pairs( Classes.Registry ) do
        if ClassName:sub( 1, #Prefix ) == Prefix then
            Classes.Registry[ClassName] = nil
        end
    end
end

return {
    groupName = "ACF.Classes.DefineClass",

    afterEach = RemoveTestClasses,

    cases = {
        {
            name = "A child defined before its parent is registered once the parent is defined",
            func = function()
                Define( "Late.Child", "Late" )

                expect( Classes.GetTypeByName( Name( "Late.Child" ) ) ).to.beNil()

                Define( "Late", nil, function( CLASS ) CLASS.Static = "parent" end )

                local Child = Classes.GetTypeByName( Name( "Late.Child" ) )

                expect( Child ).to.exist()
                expect( Classes.GetBaseClass( Child ) ).to.equal( Classes.GetTypeByName( Name( "Late" ) ) )
                expect( Child.Static ).to.equal( "parent" )
            end
        },

        {
            name = "A whole chain defined child first is registered once the root is defined",
            func = function()
                Define( "Chain.A.B", "Chain.A" )
                Define( "Chain.A", "Chain" )
                Define( "Chain" )

                expect( Classes.GetSubtypeByName( Name( "Chain" ), Name( "Chain.A.B" ) ) ).to.exist()
            end
        },

        {
            name = "A child defined before its parent inherits the parent's fields",
            func = function()
                Define( "Fields.Child", "Fields" )
                Define( "Fields", nil, function() FIELD( "Number", "Count", { Default = 3 } ) end )

                local Child = Classes.GetTypeByName( Name( "Fields.Child" ) )()

                expect( Child.Count ).to.equal( 3 )
            end
        },

        {
            name = "A base class' __inherited runs for every subclass, including ones defined first",
            func = function()
                local Seen = {}

                Define( "Hooked.Early", "Hooked" )
                Define( "Hooked", nil, function( CLASS )
                    function CLASS.__inherited( NewClass ) Seen[Classes.GetTypeName( NewClass )] = true end
                end )
                Define( "Hooked.Later", "Hooked" )

                expect( Seen[Name( "Hooked.Early" )] ).to.beTrue()
                expect( Seen[Name( "Hooked.Later" )] ).to.beTrue()
            end
        },

        {
            name = "Redefining a class keeps the same class table",
            func = function()
                local First  = Define( "Reload" )
                local Second = Define( "Reload" )

                expect( Second ).to.equal( First )
                expect( Classes.GetTypeByName( Name( "Reload" ) ) ).to.equal( First )
            end
        },

        {
            name = "Redefining a class applies its new statics and methods",
            func = function()
                Define( "Reload", nil, function( CLASS )
                    CLASS.Static = "old"
                    function CLASS:Method() return "old" end
                end )

                local Instance = Classes.GetTypeByName( Name( "Reload" ) )()

                Define( "Reload", nil, function( CLASS )
                    CLASS.Static = "new"
                    function CLASS:Method() return "new" end
                end )

                expect( Instance.Static ).to.equal( "new" )
                expect( Instance:Method() ).to.equal( "new" )
            end
        },

        {
            name = "Redefining a class with a new field gives new instances that field",
            func = function()
                Define( "Reload" )
                Define( "Reload", nil, function() FIELD( "Number", "Added", { Default = 4 } ) end )

                local Instance = Classes.GetTypeByName( Name( "Reload" ) )()

                expect( Instance.Added ).to.equal( 4 )
            end
        },

        {
            name = "Redefining a parent keeps its existing children",
            func = function()
                Define( "Parent" )
                Define( "Parent.Child", "Parent" )
                Define( "Parent" )

                local Parent = Name( "Parent" )

                expect( Classes.GetSubtypeByName( Parent, Name( "Parent.Child" ) ) ).to.exist()
                expect( Classes.GetChildren( Classes.GetTypeByName( Parent ) )[Name( "Parent.Child" )] ).to.exist()
                expect( CountSubtypes( "Parent" ) ).to.equal( 1 )
            end
        },

        {
            name = "Redefining a parent keeps its grandchildren",
            func = function()
                Define( "Parent" )
                Define( "Parent.Child", "Parent" )
                Define( "Parent.Child.Grandchild", "Parent.Child" )
                Define( "Parent" )

                expect( Classes.GetSubtypeByName( Name( "Parent" ), Name( "Parent.Child.Grandchild" ) ) ).to.exist()
                expect( CountSubtypes( "Parent" ) ).to.equal( 2 )
            end
        },

        {
            name = "Children inherit from the redefined parent",
            func = function()
                Define( "Parent", nil, function( CLASS ) CLASS.Static = "old" end )
                Define( "Parent.Child", "Parent" )
                Define( "Parent", nil, function( CLASS ) CLASS.Static = "new" end )

                expect( Classes.GetTypeByName( Name( "Parent.Child" ) ).Static ).to.equal( "new" )
            end
        },

        {
            name = "Redefining a child does not list it twice",
            func = function()
                Define( "Parent" )
                Define( "Parent.Child", "Parent" )
                Define( "Parent.Child", "Parent" )

                expect( CountSubtypes( "Parent" ) ).to.equal( 1 )
            end
        },

        {
            name = "Redefining a parent, then its children, keeps every class listed once",
            func = function()
                Define( "Parent" )
                Define( "Parent.A", "Parent" )
                Define( "Parent.B", "Parent" )

                Define( "Parent" )
                Define( "Parent.A", "Parent" )
                Define( "Parent.B", "Parent" )

                expect( CountSubtypes( "Parent" ) ).to.equal( 2 )
                expect( Classes.GetSubtypeByName( Name( "Parent" ), Name( "Parent.A" ) ) ).to.exist()
                expect( Classes.GetSubtypeByName( Name( "Parent" ), Name( "Parent.B" ) ) ).to.exist()
            end
        },
    }
}
