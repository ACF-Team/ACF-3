local ACF     = ACF
local Classes = ACF.Classes

ACF.Menu      = ACF.Menu or {}
ACF.Menu.Copy = ACF.Menu.Copy or {}

local Copy = ACF.Menu.Copy

local function ParseType(TypeStr)
	if TypeStr:sub(-2) == "[]" then return TypeStr:sub(1, -3), true end
	return TypeStr, false
end

local function CopyValue(Value)
	return istable(Value) and table.Copy(Value) or Value
end

--- Whether the entity's settings can be copied into the menu
function Copy.CanCopy(Entity)
	return IsValid(Entity) and Entity.ACF_ClassDef ~= nil and not ACF.Entities.BaseOnlyClasses[Entity:GetClass()]
end

--- Whether a field gets copied
function Copy.IsCopyable(Field)
	if not Field.Menu then return false end

	return ParseType(Field.Type) ~= "Entity"
end

--- The class of a non-array class-typed field, nil for anything else
function Copy.GetNestedClass(Field)
	local ElemType, IsArray = ParseType(Field.Type)
	if IsArray then return end

	return Classes.GetTypeByName(ElemType)
end

local function CollectPaths(Class, Instance, Prefix, Out)
	for _, Field in ipairs(Classes.GetTypeFields(Class)) do
		if not Copy.IsCopyable(Field) then continue end

		local Path   = Prefix .. Field.Name
		local Nested = Copy.GetNestedClass(Field) and Instance and Instance[Field.Name]

		Out[#Out + 1] = Path

		if istable(Nested) and Nested.GetType then
			CollectPaths(Nested:GetType(), Nested, Path .. ".", Out)
		end
	end

	return Out
end

--- Every field path the copy window shows for a class instance, nested ones included
function Copy.GetPaths(Class, Instance)
	return CollectPaths(Class, Instance, "", {})
end

-- Serialized nested values are either { Type, Data } or a bare type name
local function AsNested(Value)
	if isstring(Value) then return { Type = Value, Data = {} } end
	if not istable(Value) or not isstring(Value.Type) then return end

	return { Type = Value.Type, Data = istable(Value.Data) and Value.Data or {} }
end

local Merge

local function MergeNested(Field, Target, Source, Skip, Path)
	Target = AsNested(Target)
	Source = AsNested(Source)

	if not Source then return Target end

	local TypeName = Source.Type

	if Skip[Path] then
		TypeName = Target and Target.Type or Field.Options.InstantiateTypeForDefault
	end

	local Class = Classes.GetTypeByName(TypeName)
	if not Class then return Target end

	local Base = {}

	if Target and Target.Type == TypeName then
		Base = Target.Data
	elseif Target then
		-- New type, keep whatever the target had for fields both types share
		for _, SubField in ipairs(Classes.GetTypeFields(Class)) do
			local Value = Target.Data[SubField.Name]

			if Value ~= nil then Base[SubField.Name] = CopyValue(Value) end
		end
	end

	return { Type = TypeName, Data = Merge(Class, Base, Source.Data, Skip, Path .. ".") }
end

--- Puts the copyable fields of Source onto a copy of Target, leaving out the paths in Skip.
--- Target and Source are serialized class data (Serialization.Serialize). Target can be nil for a fresh spawn.
--- Skip is a set of paths like "FinalDrive", "AmmoType" (the type itself) or "AmmoType.RoundLength".
function Merge(Class, Target, Source, Skip, Prefix)
	local Out = table.Copy(Target or {})

	if not istable(Source) then return Out end

	Skip   = Skip or {}
	Prefix = Prefix or ""

	for _, Field in ipairs(Classes.GetTypeFields(Class)) do
		if not Copy.IsCopyable(Field) then continue end

		local Name = Field.Name
		local Path = Prefix .. Name

		if Copy.GetNestedClass(Field) then
			Out[Name] = MergeNested(Field, Out[Name], Source[Name], Skip, Path)
		elseif not Skip[Path] and Source[Name] ~= nil then
			Out[Name] = CopyValue(Source[Name])
		end
	end

	return Out
end

Copy.Merge = Merge
