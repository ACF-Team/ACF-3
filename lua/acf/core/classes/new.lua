-- API Notes =================================================================================
-- You should only need to use DefineClass
-- Base/Super/Parent class all refer to the same thing here.

-- A class is created in this order:
--    Stage 1: The class table (holds ID, OnInit) is initialized when DefineClass is called
--    Stage 2: The class metatable (makes inheritance and instantiation work, holds __PARENT and __CHILDREN) is initialized when the parent class initializes (see: InitializeClass)
--    Stage 3: The class table is indexed into Classes
--    Stage 5: The class table's OnInit method is ran
--    Stage 6: The children of this class are initialized (Stage 1-6) recursively

-- Internal Notes ============================================================================
-- A class has initialized <-> Classes[ID] = ClassTable
-- A class is waiting on its parent to initialize <-> Queued[BaseID][ID] = ClassTable

local Classes = ACF.Classes

local ClassRegistry = Classes.Registry or {} --- A mapping from a class' ID to its table
Classes.Registry = ClassRegistry


local Queued = {} -- A mapping from a class' ID to a (mapping from its children's IDs to their tables)

local READ_ONLY_MT = {__newindex = function() end}

local UpdateFlattenedChildrenLookupRecursive function UpdateFlattenedChildrenLookupRecursive(BaseClass, FullyQualifiedName, NewClass)
    local MT = getmetatable(BaseClass)
    if not MT then return end
    if not MT.__CHILDREN_FLATTENED[FullyQualifiedName] then
        MT.__CHILDREN_FLATTENED_CONTIGUOUS[#MT.__CHILDREN_FLATTENED_CONTIGUOUS + 1] = NewClass
        MT.__CHILDREN_NAMES_CONTIGUOUS[#MT.__CHILDREN_NAMES_CONTIGUOUS + 1] = FullyQualifiedName
    end
    MT.__CHILDREN_FLATTENED[FullyQualifiedName] = NewClass
    local P = MT.__index
    if not P then return end
    UpdateFlattenedChildrenLookupRecursive(P, FullyQualifiedName, NewClass)
end

do
    --- Initializes a class by adding its metatable and running callbacks/hooks.
    --- Recursively initializes children waiting on this class
    --- This is called when a class and its parent are both initialized
    --- @param ID string The ID of the class
    --- @param NewClass table The class table of the class
    --- @param BaseClass table The class table of the base class
    local function InitializeClass(FullyQualifiedName, NewClass, BaseClass)
        local TypeName = string.format("Type (%s)", FullyQualifiedName)

        local InstantiateFields
        local ClassMeta = {
            __index = BaseClass, -- If I don't have it, check my super (inheritance)
            __tostring = function() return TypeName end,
            __CLASS_ID = FullyQualifiedName,
            __CHILDREN = {},            -- A mapping from a child class' ID to its table
            -- The tables below are for optimizations...
            __CHILDREN_FLATTENED = {},  -- The same as above but flattened hierarchy
            __CHILDREN_FLATTENED_CONTIGUOUS = {},  -- The same as above but an array
            __CHILDREN_NAMES_CONTIGUOUS = {},  -- The same as above but the names
            -- Instantiation
            __call = function(self, ...)
                local Instance    = {}
                local Address     = tostring(Instance):sub(8)
                local Stringified = string.format("%s: %s", FullyQualifiedName, Address)
                setmetatable(Instance, {
                    __index = self, -- Instances should use their class' static methods/variables if they dont have them set
                    __tostring = function(self) return self.ToString and self:ToString() or Stringified end, -- Avoid ambiguity/shadowing of self and the instance
                })
                InstantiateFields(self) -- run field instantiators first
                if self.new then self.new(Instance, ...) end -- Constructor if applicable
                return Instance
            end
        }
        setmetatable(NewClass, ClassMeta)

        -- Index and Initialize ourselves
        ClassRegistry[FullyQualifiedName] = NewClass
        if BaseClass then
            getmetatable(BaseClass).__CHILDREN[FullyQualifiedName] = NewClass
            UpdateFlattenedChildrenLookupRecursive(BaseClass, FullyQualifiedName, NewClass)
        end -- Register ourselves as a child of our parent
        ClassMeta.__PARENT = BaseClass
        -- We should define GetType before calling the initializer
        local function GetType() return NewClass end
        NewClass.GetType = GetType

        -- Initialize Fields, inheriting from base class
        ClassMeta.__FIELDS = { List = {}, Lookup = {} }
        local BaseClassMT = BaseClass and getmetatable(BaseClass)
        if BaseClassMT and BaseClassMT.__FIELDS then
            for _, Field in ipairs(BaseClassMT.__FIELDS.List) do
                local Copy = table.Copy(Field)
                table.insert(ClassMeta.__FIELDS.List, Copy)
                ClassMeta.__FIELDS.Lookup[Field.Name] = Copy
            end
        end

        function InstantiateFields(Instance)
            for _, Field in ipairs(ClassMeta.__FIELDS.List) do
                -- Check default of field def
                local Options = Field.Options
                -- This can either be a type name, a factory, or a value
                -- factories are used for things like table data if we ever store that or userdata like vectors/angles
                if Options.InstantiateTypeForDefault then
                    local Type = Classes.GetTypeByName(Options.InstantiateTypeForDefault)
                    if Classes.IsAssignableTo(Type, Classes.GetTypeByName(Field.Type)) then
                        Instance[Field.Name] = Type()
                    end
                elseif Options.DefaultFactory then
                    Instance[Field.Name] = Options.DefaultFactory()
                elseif Options.Default ~= nil then
                    Instance[Field.Name] = Options.Default
                end
            end
        end

        if NewClass.OnInit then
            local Environment = {}
            Environment.CLASS = NewClass
            Environment.BASE  = BaseClass

            local function AddField(Menu, FieldType, Name, Options)
                local NewClassMT = getmetatable(NewClass)
                local Existing = NewClassMT.__FIELDS.Lookup[Name]
                if Existing then
                    Existing.Type    = FieldType
                    Existing.Options = Options or {}
                    Existing.Menu    = Menu
                else
                    local Field = { Type = FieldType, Name = Name, Options = Options or {}, Menu = Menu }
                    table.insert(NewClassMT.__FIELDS.List, Field)
                    NewClassMT.__FIELDS.Lookup[Name] = Field
                end
            end

            Environment.FIELD       = function(FieldType, Name, Options) AddField(false, FieldType, Name, Options) end
            Environment.MENU_FIELD  = function(FieldType, Name, Options) AddField(true,  FieldType, Name, Options) end

            Environment.LINKED_ENTITY_FIELD = function(Name, Options)
                local NewClassMT = getmetatable(NewClass)
                local Existing = NewClassMT.__FIELDS.Lookup[Name]
                if Existing then
                    Existing.Type    = "Entity"
                    Existing.Options = Options or {}
                    Existing.Menu    = false
                    Existing.Linked  = true
                else
                    local Field = { Type = "Entity", Name = Name, Options = Options or {}, Menu = false, Linked = true }
                    table.insert(NewClassMT.__FIELDS.List, Field)
                    NewClassMT.__FIELDS.Lookup[Name] = Field
                end
            end

            Environment.LINKED_ENTITY_ARRAY_FIELD = function(Name, Options)
                local NewClassMT = getmetatable(NewClass)
                local Existing = NewClassMT.__FIELDS.Lookup[Name]
                if Existing then
                    Existing.Type    = "Entity[]"
                    Existing.Options = Options or {}
                    Existing.Menu    = false
                    Existing.Linked  = true
                else
                    local Field = { Type = "Entity[]", Name = Name, Options = Options or {}, Menu = false, Linked = true }
                    table.insert(NewClassMT.__FIELDS.List, Field)
                    NewClassMT.__FIELDS.Lookup[Name] = Field
                end
            end

            setmetatable(Environment, {__index = _G})
            setfenv(NewClass.OnInit, Environment)

            NewClass.OnInit()
            ClassMeta.__inherited = NewClass.__inherited
        end
        -- Just in case GetType is no longer the same function...
        if NewClass.GetType ~= GetType then error("Class defined 'GetType' method, which is reserved") end
        -- This allows base classes to be aware when they initialize children.
        -- It is recursive.
        -- This is a bit of a weird method and you should only use it when you have to
        local Ancestor = BaseClass
        while Ancestor ~= nil do
            local MT = getmetatable(Ancestor)
            local __inherited = MT and MT.__inherited
            if __inherited then
                __inherited(NewClass)
            end
            Ancestor = MT and MT.__PARENT
        end

        -- Initialize children waiting on us, the parent, to initialize
        if Queued[FullyQualifiedName] then
            for WaitingID, WaitingClass in pairs(Queued[FullyQualifiedName]) do
                InitializeClass(WaitingID, WaitingClass, NewClass)
                ClassMeta.__CHILDREN[WaitingID] = WaitingClass
            end
            Queued[FullyQualifiedName] = nil
        end

        -- Don't allow these to be modified by users, just in case someone is stupid
        setmetatable(ClassMeta.__FIELDS, READ_ONLY_MT)
        setmetatable(ClassMeta.__FIELDS.List, READ_ONLY_MT)
        setmetatable(ClassMeta.__FIELDS.Lookup, READ_ONLY_MT)
    end

    --- Defines and returns a class' table, which you can define methods on.
    --- @param ID string The ID of the class
    --- @param BaseID string? The ID of the parent class
    --- @param OnInit function? Ran when both the class and its parent are initialized. New and base class tables are passed as args.
    --- @return NewClass table The table of the new class
    local function DefineClass(ID, ...)
        local BaseID, OnInit
        local Args = select('#', ...)
        for I = 1, Args do
            local Arg = select(I, ...)
            local ArgType = type(Arg)
            if ArgType == "string" then -- todo: future strings after baseid would be interfaces if those are implemented
                BaseID = Arg
            elseif ArgType == "function" then
                OnInit = Arg
                break
            end
        end

        local BaseClass = ClassRegistry[BaseID]
        local NewClass = ClassRegistry[ID] or {} -- This should allow for hot-reloading?
        NewClass.OnInit = OnInit

        -- If we have a parent and they don't exist
        if BaseID and not BaseClass then
            Queued[BaseID] = Queued[BaseID] or {}
            Queued[BaseID][ID] = NewClass
            return NewClass
        end

        -- Otherwise initialize
        InitializeClass(ID, NewClass, BaseClass)
        return NewClass
    end

    Classes.DefineClass = DefineClass
end

local ReadOnlyTable = setmetatable({}, nil)

-- NOTE: When I specify a name, I will say "ClassName".
-- When I specify a class object, I will say "ClassType"
-- When I specify a class instance, I will say "ClassInstance"
function Classes.GetTypeByName(ClassName)
    if not ClassName then return end
    return ClassRegistry[ClassName]
end

function Classes.GetTypeName(Class)
    return Class and getmetatable(Class).__CLASS_ID or "none"
end

-- Returns a contiguous read-only array of fields
function Classes.GetTypeFields(Class)
    return Class and getmetatable(Class).__FIELDS.List or ReadOnlyTable
end

-- Looks up a field on a class by name
function Classes.GetTypeFieldByName(Class, Name)
    if Class == nil then return nil end
    return getmetatable(Class).__FIELDS.Lookup[Name]
end

-- Returns the base/parent class type, or nil if there is none
function Classes.GetBaseClass(Class)
    local MT = Class and getmetatable(Class)
    return MT and MT.__PARENT
end

-- Returns the mapping of direct child IDs to their class tables
function Classes.GetChildren(Class)
    local MT = Class and getmetatable(Class)
    return MT and MT.__CHILDREN or ReadOnlyTable
end

-- Returns the mapping of flattened-hierarchy child IDs to their class tables
-- If the class name does not exist, a read only table is returned.
-- This can serve as a replacement for Namespace.GetEntries.
function Classes.GetSubtypes(ClassName)
    local Class = ClassRegistry[ClassName]
    if not Class then return ReadOnlyTable end
    return getmetatable(Class).__CHILDREN_FLATTENED
end

-- Returns a contiguous array of flattened-hierarchy child IDs to their class tables
-- If the class name does not exist, a read only table is returned.
-- This can serve as a replacement for Namespace.GetList.
function Classes.GetSubtypesAsList(ClassName)
    local Class = ClassRegistry[ClassName]
    if not Class then return ReadOnlyTable end
    return getmetatable(Class).__CHILDREN_FLATTENED_CONTIGUOUS
end

-- Returns a contiguous array of flattened-hierarchy child IDs to their class tables.
-- If the class name does not exist, a read only table is returned.
-- This can serve as a replacement for Namespace.GetList, where the list was only used
-- to create a list of Type.ID's (where ID is no longer guaranteed) and should be faster
-- than iterating through GetSubtypesAsList and calling GetTypeName.
-- (FQN == Fully Qualified Name)
function Classes.GetSubtypeFQNs(ClassName)
    local Class = ClassRegistry[ClassName]
    if not Class then return ReadOnlyTable end
    return getmetatable(Class).__CHILDREN_NAMES_CONTIGUOUS
end

-- Returns a subtype of BaseClassName with the fully qualified name of WantedClassName.
-- If one does not exist, then nil is returned.
-- This can serve as a replacement for Namespace.Get.
function Classes.GetSubtypeByName(BaseClassName, WantedClassName)
    local Class = ClassRegistry[BaseClassName]
    if not Class then return nil end

    return getmetatable(Class).__CHILDREN_FLATTENED[WantedClassName] or nil
end

-- This checks if ClassA can be basically "down-casted" down to ClassB by going down its parent tree.
function Classes.IsAssignableTo(ClassTypeA, ClassTypeB)
    if ClassTypeA == ClassTypeB then return true end
    local C = ClassTypeA

    while C ~= nil do
        C = Classes.GetBaseClass(C)
        if C == ClassTypeB then
            return true
        end
    end

    return false
end

function Classes.IsAssignableFrom(ClassTypeA, ClassTypeB)
    return Classes.IsAssignableTo(ClassTypeB, ClassTypeA)
end