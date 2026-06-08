local Classes    = ACF.Classes
local Entities   = Classes.Entities

--- Table mapping entity class names to their class tables
--- @type table<string, table>
local Entries    = {}

--- Represents the arguments of an entity class (and information about them)
--- @class EntityTable
--- @field Lookup table 		# Maps argument name to true
--- @field Count number 		# The total number of arguments
--- @field List table 			# An array of all arguments
--- @field Restrictions table 	# Maps an argument name to its restrictions (See: ACF_UserVars)

--- Represents an entity argument (and its restriction) in the new API
--- @class Restriction
--- @field Type string			# The type of the restriction
--- @field ClientData bool		# Whether this property should be updated from the menu
--- @field Default any			# The default value if none is provided

--- Gets the entity table of a certain class
--- If an entity table doesn't exist for the class, it will register one.
--- @param Class table The class to get the entity table from
--- @return EntityTable # The entity table of this class
local function GetEntityTable(Class)
    local Data = Entries[Class]

    if not Data then
        Data = {
            Lookup       = {},
            Count        = 0,
            List         = {},
            Restrictions = {}
        }

        Entries[Class] = Data
    end

    return Data
end
Entities.GetEntityTable = GetEntityTable -- for autoreg V1


--- Adds arguments to an entity for storage in duplicators
--- The Entity.Lookup, Entity.Count and Entity.List variables allow us to iterate over this information in different ways. 
--- @param Entity EntityTable The entity table to add arguments to
--- @param Arguments any[] # An array of arguments to attach to the entity (usually {...})
--- @return any[] # An array of arguments attached to the entity
local function AddArguments(Entity, Arguments)
    local Lookup = Entity.Lookup
    local Count  = Entity.Count
    local List   = Entity.List

    for _, V in ipairs(Arguments) do
        if Lookup[V] then continue end	-- Ignore adding what's already registered

        Count = Count + 1				-- Increment the count of arguments
        Lookup[V]   = true				-- Index the entity argument as used
        List[Count] = V					-- Append the entity argument to the list
    end

    Entity.Count = Count				-- Update the count of arguments

    return List
end
Entities.AddArgumentsRaw = AddArguments

--- Adds extra arguments to a class which has already been called in Entities.Register  
--- Should be called after Entities.Register if you want to specify any additional arguments
--- @param Class string A class previously registered as an entity class
--- @param ... any #A vararg of arguments
function Entities.AddArguments(Class, ...)
    if not isstring(Class) then return end

    local Entity    = GetEntityTable(Class)
    local Arguments = istable(...) and ... or { ... }
    local List      = AddArguments(Entity, Arguments)

    if Entity.Spawn then
        local function SpawnFunction(Player, Pos, Angle, Data)
            local _, SpawnedEntity = Entities.Spawn(Class, Player, Pos, Angle, Data, true)

            return SpawnedEntity
        end

        duplicator.RegisterEntityClass(Class, SpawnFunction, "Pos", "Angle", "Data", unpack(List))
    end
end

--- Returns an array of the entity's arguments
--- @param Class string The entity class to get arguments from
--- @return any[] # An array of arguments attached to the entity
function Entities.GetArguments(Class)
    if not isstring(Class) then return end

    local Entity = GetEntityTable(Class)
    local List   = {}

    for K, V in ipairs(Entity.List) do
        List[K] = V
    end

    return List
end

-- Entity classes use the simple class system
-- As we are trying to deprecate it, the code for that has been repeated here.
-- In the future, this file should just be refactored entirely.

--- Gets the entry from the namespace with the given ID
--- @param ID string The ID of the entry
--- @return table | nil # The entry
function Entities.Get(ID) return isstring(ID) and Entries[ID] or nil end

--- Gets all the entries in the namespace  
--- If aliases exist in the namespace, they will be ignored in the returned table
--- @return table<string,table> # A table mapping the an entry's ID to itself 
function Entities.GetEntries()
    local Result = {}
    for _, V in pairs(Entries) do Result[V.ID] = V end
    return Result
end

--- Gets the stored entries table
--- Returns the original reference
--- Allows the class system to restore itself later
--- @return table # The stored entries table
function Entities.GetStored() return Entries end

--- Gets all the entries in the namespace  
--- If aliases exist in the namespace, they will be included in the returned table
--- @return table<number,table> # An "array" (e.g. {class1,class2,...}) containing entries
function Entities.GetList()
    local Result = {}
    local Count  = 0

    for _, V in pairs(Entries) do
        Count = Count + 1

        Result[Count] = V
    end

    return Result
end

--- Registers a class as a spawnable entity class
--- @param Class string The class to register
--- @param Function fun(Player:entity, Pos:vector, Ang:angle, Data:table):Entity A function defining how to spawn your class (This should be your ACF.Make<something> function)
--- @param ... any #A vararg of arguments to attach to the entity
function Entities.LegacyRegister(Class, Function, ...)
    if not isstring(Class) then return end
    if not isfunction(Function) then return end

    local Entity    = GetEntityTable(Class)
    local Arguments = istable(...) and ... or { ... }
    local List      = AddArguments(Entity, Arguments)

    Entity.Spawn = Function

    local function SpawnFunction(Player, Pos, Angle, Data)
        local _, SpawnedEntity = Entities.Spawn(Class, Player, Pos, Angle, Data, true)

        return SpawnedEntity
    end

    duplicator.RegisterEntityClass(Class, SpawnFunction, "Pos", "Angle", "Data", unpack(List))
end

-- Autoreg also gets handled this way, since it all uses the same legacy backbone
hook.Add("ACF_TemporaryHook_InstantiateEntity", "Legacy", function(Class, Player, Position, Angles, Data)
    local ClassData = Entities.Get(Class)

    if not ClassData then return end
    if not ClassData.Spawn then return end

    local Entity = ClassData.Spawn(Player, Position, Angles, Data)
    if IsValid(Entity) then return Entity end
end)