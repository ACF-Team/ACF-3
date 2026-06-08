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

local Classes = {} --- A mapping from a class' ID to its table
local Queued = {} -- A mapping from a class' ID to a (mapping from its children's IDs to their tables)

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
        NewClass.Fields = { List = {}, Lookup = {} }
        if BaseClass and BaseClass.Fields then
            for _, Field in ipairs(BaseClass.Fields.List) do
                local Copy = table.Copy(Field)
                table.insert(NewClass.Fields.List, Copy)
                NewClass.Fields.Lookup[Field.Name] = Copy
            end
        end

        if NewClass.OnInit then
            local Environment = {}
            Environment.CLASS = NewClass
            Environment.BASE  = BaseClass

            local function AddField(Menu, FieldType, Name, Options)
                local Existing = NewClass.Fields.Lookup[Name]
                if Existing then
                    Existing.Type    = FieldType
                    Existing.Options = Options or {}
                    Existing.Menu    = Menu
                else
                    local Field = { Type = FieldType, Name = Name, Options = Options or {}, Menu = Menu }
                    table.insert(NewClass.Fields.List, Field)
                    NewClass.Fields.Lookup[Name] = Field
                end
            end

            Environment.FIELD      = function(FieldType, Name, Options) AddField(false, FieldType, Name, Options) end
            Environment.MENU_FIELD = function(FieldType, Name, Options) AddField(true,  FieldType, Name, Options) end

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


-- NOTE: When I specify a name, I will say "ClassName".
-- When I specify a class object, I will say "ClassType"
-- When I specify a class instance, I will say "ClassInstance"
function ACF.Classes.GetTypeByName(ClassName)
    return Classes[ClassName]
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
