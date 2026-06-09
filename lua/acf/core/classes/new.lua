-- API Notes =================================================================================
-- You should only need to use DefineClass
-- Base/Super/Parent class all refer to the same thing here.

-- A class is created in this order:
--    Stage 1: The class table (holds ID, Parent, Children, OnInit) is initialized when DefineClass is called
--    Stage 2: The class metatable (makes inheritance and instantiation work) is initialized when the parent class initializes (see: InitializeClass)
--    Stage 3: The class table is indexed into Classes
--    Stage 5: The class table's OnInit method is ran
--    Stage 6: The children of this class are initialized (Stage 1-6) recursively

-- Internal Notes ============================================================================
-- A class has initialized <-> Classes[ID] = ClassTable
-- A class is waiting on its parent to initialize <-> Queued[BaseID][ID] = ClassTable

local Classes = ACF.Classes.Registry or {} --- A mapping from a class' ID to its table
ACF.Classes.Registry = Classes

local Queued = {} -- A mapping from a class' ID to a (mapping from its children's IDs to their tables)

local READ_ONLY_MT = {__newindex = function() end}

do
    --- Initializes a class by adding its metatable and running callbacks/hooks.
    --- Recursively initializes children waiting on this class
    --- This is called when a class and its parent are both initialized
    --- @param ID string The ID of the class
    --- @param NewClass table The class table of the class
    --- @param BaseClass table The class table of the base class
    local function InitializeClass(FullyQualifiedName, NewClass, BaseClass)
        local TypeName = string.format("Type (%s)", FullyQualifiedName)

        local ClassMeta = {
            __index = BaseClass, -- If I don't have it, check my super (inheritance)
            __tostring = function() return TypeName end,
            __CLASS_ID = FullyQualifiedName,
            -- Instantiation
            __call = function(self, ...)
                local Instance    = {}
                local Address     = tostring(Instance):sub(8)
                local Stringified = string.format("%s: %s", FullyQualifiedName, Address)
                setmetatable(Instance, {
                    __index = self, -- Instances should use their class' static methods/variables if they dont have them set
                    __tostring = function(self) return self.ToString and self:ToString() or Stringified end, -- Avoid ambiguity/shadowing of self and the instance
                })
                if self.new then self.new(Instance, ...) end -- Constructor if applicable
                return Instance
            end
        }
        setmetatable(NewClass, ClassMeta)

        -- Index and Initialize ourselves
        Classes[FullyQualifiedName] = NewClass
        if BaseClass then BaseClass.Children[FullyQualifiedName] = NewClass end -- Register ourselves as a child of our parent
        NewClass.Parent = BaseClass

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
        end
        -- Just in case GetType is no longer the same function...
        if NewClass.GetType ~= GetType then error("Class defined 'GetType' method, which is reserved") end

        -- Initialize children waiting on us, the parent, to initialize
        if Queued[FullyQualifiedName] then
            for WaitingID, WaitingClass in pairs(Queued[FullyQualifiedName]) do
                InitializeClass(WaitingID, WaitingClass, NewClass)
                NewClass.Children[WaitingID] = WaitingClass
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

        local BaseClass = Classes[BaseID]
        local NewClass = Classes[ID] or {
            ID = ID,
            Parent = nil,
            Children = {}
        } -- This should allow for hot-reloading?
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

    ACF.Classes.DefineClass = DefineClass
end

local ReadOnlyTable = setmetatable({}, nil)

-- NOTE: When I specify a name, I will say "ClassName".
-- When I specify a class object, I will say "ClassType"
-- When I specify a class instance, I will say "ClassInstance"
function ACF.Classes.GetTypeByName(ClassName)
    return Classes[ClassName]
end

function ACF.Classes.GetTypeName(Class)
    return Class and getmetatable(Class).__CLASS_ID or "none"
end

-- Returns a contiguous read-only array of fields
function ACF.Classes.GetTypeFields(Class)
    return Class and getmetatable(Class).__FIELDS.List or ReadOnlyTable
end

-- Looks up a field on a class by name
function ACF.Classes.GetTypeFieldByName(Class, Name)
    if Class == nil then return nil end
    return getmetatable(Class).__FIELDS.Lookup[Name]
end


function ACF.Classes.GetSubtypes(ClassName)
    local Class = Classes[ClassName]
    if not Class then return {} end

    local Result = {}
    local function Collect(C)
        for _, Child in pairs(C.Children) do
            Result[#Result + 1] = Child
            Collect(Child)
        end
    end
    Collect(Class)
    return Result
end

-- This checks if ClassA can be basically "down-casted" down to ClassB by going down its parent tree.
function ACF.Classes.IsAssignableTo(ClassTypeA, ClassTypeB)
    local C = ClassTypeA

    while C ~= nil do
        C = C.Parent
        if C == ClassTypeB then
            return true
        end
    end

    return false
end

function ACF.Classes.IsAssignableFrom(ClassTypeA, ClassTypeB)
    return ACF.Classes.IsAssignableTo(ClassTypeB, ClassTypeA)
end

