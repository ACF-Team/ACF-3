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
                local Address     = tostring(Instance):sub(8) -- Maps "table: 0x80880a76edcedbf2" -> "80880a76edcedbf2"
                local Stringified = string.format("%s: %s", FullyQualifiedName, Address) -- Maps "Chihuahua" -> "Chihuahua: 80880a76edcedbf2"
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

        -- Call the initializer if it exists, with a custom environment that has access to the class and its base class as CLASS and BASE respectively.
        if NewClass.OnInit then
            local Environment = {}
            Environment.CLASS = NewClass
            Environment.BASE  = BaseClass
            setmetatable(Environment, {__index = _G})
            setfenv(NewClass.OnInit, Environment)
            NewClass.OnInit()
        end

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
    local function DefineClass(ID, BaseID, OnInit)
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

    ACF.Class = DefineClass
end

-- Testing code

-- do
--     print("Testing simpleclass_v3")
--     local Snake = ACF.Class("Snake", "Reptile")
--     local Frog = ACF.Class("Frog", "Reptile")
--     local Reptile = ACF.Class("Reptile", "Animal")

--     local Chihuahua = ACF.Class("Chihuahua", "Dog", function()
--         function CLASS:MakeNoise()
--             for i = 1, 5 do BASE.MakeNoise(self) end
--         end
--     end)

--     local Dog = ACF.Class("Dog", "ACF.Mammal", function()
--         function CLASS:MakeNoise()
--             print("Woof")
--         end
--     end)

--     local Cat = ACF.Class("Cat", "ACF.Mammal")
--     local Mammal = ACF.Class("ACF.Mammal", "Animal", function()
--         CLASS.Test = 3
--         function CLASS:new()
--             print(self.Test)
--         end

--         function CLASS:MakeNoise()
--             print("Roar")
--         end
--     end)

--     local Animal = ACF.Class("Animal", nil, function()
--         function CLASS:MakeNoise()
--             print("Animal Noise")
--         end
--     end)

--     local MyDog = Chihuahua()
--     MyDog:MakeNoise()
--     print(Dog)
--     print(MyDog)

--     local T = MyDog:GetType()
--     print(T)
--     print(T == Chihuahua)
-- end
