local Classes        = ACF.Classes
Classes.Serialization = Classes.Serialization or {}

local Serialization  = Classes.Serialization
local GetTypeByName  = Classes.GetTypeByName
local IsAssignableTo = Classes.IsAssignableTo

local function ParseType(TypeStr)
    if TypeStr:sub(-2) == "[]" then
        return TypeStr:sub(1, -3), true
    end
    return TypeStr, false
end

local function ValidateNumber(Value, Options)
    local N = tonumber(Value)
    if N == nil then return Options.Default end
    if Options.Min ~= nil then N = math.max(N, Options.Min) end
    if Options.Max ~= nil then N = math.min(N, Options.Max) end
    if Options.Decimals ~= nil then N = math.Round(N, Options.Decimals) end
    return N
end

local function ValidateBoolean(Value, Options)
    if type(Value) == "boolean" then return Value end
    return Options.Default
end

local function ValidateString(Value, Options)
    local ValueType = type(Value)
    if ValueType == "string" then return Value end
    if ValueType == "number" or ValueType == "boolean" then return tostring(Value) end
    return Options.Default
end

local function ValidateEntity(Ent, Options)
    if not IsValid(Ent) then return NULL end
    local AcceptableClasses = Options.AcceptableClasses
    if AcceptableClasses and not AcceptableClasses[Ent:GetClass()] then return NULL end
    return Ent
end

local function SerializeValue(ElemType, Value)
    if ElemType == "Number" then
        return tonumber(Value)
    elseif ElemType == "Boolean" then
        return Value == true
    elseif ElemType == "String" then
        return tostring(Value)
    elseif ElemType == "Entity" then
        return IsValid(Value) and Value:EntIndex() or -1
    else
        local ClassType = GetTypeByName(ElemType)
        if ClassType and Value then
            local ActualType = Value.GetType and Value:GetType() or ClassType
            if ActualType == Value then return Value.ID end
            return {
                Type = ActualType.ID,
                Data = Serialization.Serialize(ActualType, Value)
            }
        end
        return nil
    end
end

local function DeserializeValue(ElemType, Raw, Options)
    if ElemType == "Number" then
        return ValidateNumber(Raw, Options)
    elseif ElemType == "Boolean" then
        return ValidateBoolean(Raw, Options)
    elseif ElemType == "String" then
        return ValidateString(Raw, Options)
    else
        local ClassType = GetTypeByName(ElemType)
        if ClassType then
            if type(Raw) == "string" then
                local TypeObj = GetTypeByName(Raw)
                if TypeObj and IsAssignableTo(TypeObj, ClassType) then
                    return TypeObj()
                end
            elseif type(Raw) == "table" and Raw.Type then
                -- Class instance: serialized as { Type, Data }
                local ActualType = GetTypeByName(Raw.Type)
                if ActualType and IsAssignableTo(ActualType, ClassType) then
                    return Serialization.DeserializePartial(ActualType, Raw.Data)
                end
            end
        end
        return nil
    end
end

-- Serialize a LiveData class instance into a flat table (ACF_UserData)
function Serialization.Serialize(Class, Instance)
    local Out = {}

    if not Instance then return Out end

    for _, Field in ipairs(Classes.GetTypeFields(Class)) do
        local ElemType, IsArray = ParseType(Field.Type)
        local Value = Instance[Field.Name]

        if IsArray then
            local Arr = {}
            if type(Value) == "table" then
                if Field.Linked then
                    for Ent in pairs(Value) do
                        if IsValid(Ent) then Arr[#Arr + 1] = SerializeValue(ElemType, Ent) end
                    end
                else
                    for I, V in ipairs(Value) do Arr[I] = SerializeValue(ElemType, V) end
                end
            end
            Out[Field.Name] = Arr
        else
            Out[Field.Name] = SerializeValue(ElemType, Value)
        end
    end

    return Out
end

-- The deserialization here is split into two steps, due to most deserialization going through an entity duplicator pipeline.
-- The first step is dedicated to handling every field that isn't an Entity, since those fields will be a different type. We
-- explicitly wait until later and do NOT store the number in place to avoid type confusion
-- The second step is dedicated to handling all Entity fields that were missing, since PostEntityPaste will provide the LUT of
-- old entity indices -> new entity references. TODO: integrate with linking, somehow, perhaps LINKED_ENTITY_FIELD macros

function Serialization.DeserializeInto(Class, Instance, Data)
    if not Instance or not Data then return Instance end

    for _, Field in ipairs(Classes.GetTypeFields(Class)) do
        if not Field.Menu then continue end

        local ElemType, IsArray = ParseType(Field.Type)
        if ElemType == "Entity" then continue end

        local Options = Field.Options
        local Raw     = Data[Field.Name]

        if IsArray then
            if type(Raw) == "table" then
                local Arr = {}
                for _, V in ipairs(Raw) do
                    local Deserialized = DeserializeValue(ElemType, V, Options)
                    if Deserialized ~= nil then Arr[#Arr + 1] = Deserialized end
                end
                Instance[Field.Name] = Arr
            end
        elseif Raw ~= nil then
            local Deserialized = DeserializeValue(ElemType, Raw, Options)
            if Deserialized ~= nil then
                Instance[Field.Name] = Deserialized
            elseif Options.InstantiateTypeForDefault and Instance[Field.Name] == nil then
                local DefaultType = GetTypeByName(Options.InstantiateTypeForDefault)
                Instance[Field.Name] = DefaultType and DefaultType() or nil
            end
        elseif Options.InstantiateTypeForDefault and Instance[Field.Name] == nil then
            local DefaultType = GetTypeByName(Options.InstantiateTypeForDefault)
            Instance[Field.Name] = DefaultType and DefaultType() or nil
        end
    end

    return Instance
end

function Serialization.DeserializePartial(Class, Data)
    local Instance = Class()
    if not Data then return Instance end

    for _, Field in ipairs(Classes.GetTypeFields(Class)) do
        local ElemType, IsArray = ParseType(Field.Type)

        if ElemType == "Entity" then
            if IsArray and Field.Linked then
                Instance[Field.Name] = Instance[Field.Name] or {}
            end
            continue
        end

        local Options = Field.Options
        local Raw     = Data[Field.Name]

        if IsArray then
            local Arr = {}
            if type(Raw) == "table" then
                for _, V in ipairs(Raw) do
                    local Deserialized = DeserializeValue(ElemType, V, Options)
                    if Deserialized ~= nil then
                        Arr[#Arr + 1] = Deserialized
                    end
                end
            end
            Instance[Field.Name] = Arr
        elseif Raw ~= nil then
            local Deserialized = DeserializeValue(ElemType, Raw, Options)
            if Deserialized ~= nil then
                Instance[Field.Name] = Deserialized
            elseif Options.InstantiateTypeForDefault then
                local DefaultType = GetTypeByName(Options.InstantiateTypeForDefault)
                Instance[Field.Name] = DefaultType and DefaultType() or nil
            end
        elseif Options.InstantiateTypeForDefault then
            local DefaultType = GetTypeByName(Options.InstantiateTypeForDefault)
            Instance[Field.Name] = DefaultType and DefaultType() or nil
        end
    end

    return Instance
end

function Serialization.ResolveEntities(Class, Instance, Data, CreatedEntities, Entity)
    if not Instance or not Data then return end

    for _, Field in ipairs(Classes.GetTypeFields(Class)) do
        local ElemType, IsArray = ParseType(Field.Type)
        local Options           = Field.Options

        if ElemType == "Entity" then
            local Raw = Data[Field.Name]

            if Field.Linked and Entity then
                if IsArray then
                    if type(Raw) == "table" then
                        for _, Idx in ipairs(Raw) do
                            local Ent = ValidateEntity(CreatedEntities[Idx], Options)
                            if IsValid(Ent) then Entity:Link(Ent) end
                        end
                    end
                else
                    local Ent = ValidateEntity(CreatedEntities[Raw], Options)
                    if IsValid(Ent) then Entity:Link(Ent) end
                end
            elseif IsArray then
                local Arr = {}
                if type(Raw) == "table" then
                    for _, Idx in ipairs(Raw) do
                        local Ent = ValidateEntity(CreatedEntities[Idx], Options)
                        if IsValid(Ent) then Arr[#Arr + 1] = Ent end
                    end
                end
                Instance[Field.Name] = Arr
            else
                Instance[Field.Name] = ValidateEntity(CreatedEntities[Raw], Options)
            end
        elseif GetTypeByName(ElemType) then
            if IsArray then
                local NestedArr = Instance[Field.Name]
                local RawArr    = Data[Field.Name]
                if type(NestedArr) == "table" and type(RawArr) == "table" then
                    for I, NestedInst in ipairs(NestedArr) do
                        local RawElem = RawArr[I]
                        if NestedInst and type(RawElem) == "table" and RawElem.Data then
                            local ActualClass = NestedInst.GetType and NestedInst:GetType() or GetTypeByName(ElemType)
                            Serialization.ResolveEntities(ActualClass, NestedInst, RawElem.Data, CreatedEntities)
                        end
                    end
                end
            else
                local NestedInst = Instance[Field.Name]
                local RawField   = Data[Field.Name]
                if NestedInst and type(RawField) == "table" and RawField.Data then
                    local ActualClass = NestedInst.GetType and NestedInst:GetType() or GetTypeByName(ElemType)
                    Serialization.ResolveEntities(ActualClass, NestedInst, RawField.Data, CreatedEntities)
                end
            end
        end
    end
end
