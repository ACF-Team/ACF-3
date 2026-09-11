local ACF           = ACF
local Classes       = ACF.Classes
local Serialization = Classes.Serialization

ACF.Menu = ACF.Menu or {}

local Context = {}
Context.__index = Context

local ANY = "*" -- callback key meaning "any field changed"

--- Reads a field's current value from the live instance.
function Context:Get(Field)
	return self.Instance[Field]
end

--- Returns the field definition ({ Type, Options, Menu, ... }) for a field name, or nil.
function Context:FieldDef(Field)
	return Classes.GetTypeFieldByName(self.Class, Field)
end

--- Runs the callbacks registered for a given field, then the "any field" callbacks.
function Context:_Fire(Field, Value)
	local PerField = self._Callbacks[Field]
	if PerField then
		for _, Fn in pairs(PerField) do Fn(self, Field, Value) end
	end

	local AnyField = self._Callbacks[ANY]
	if AnyField then
		for _, Fn in pairs(AnyField) do Fn(self, Field, Value) end
	end
end

--- Sets a field, clamping/validating it against the field metadata (identically to the server-side
--- deserializer), then fires change callbacks and queues a debounced persist write.
--- Pass Silent = true to skip callbacks/persist (used when hydrating from disk).
--- Returns the coerced value actually stored.
function Context:Set(Field, Value, Silent)
	local FieldDef = self:FieldDef(Field)
	local Coerced  = FieldDef and Serialization.CoerceField(FieldDef, Value) or Value

	self.Instance[Field] = Coerced

	if not Silent then
		self:_Fire(Field, Coerced)
		self:_Persist()
	end

	return Coerced
end

--- Persists this context's state. Sub-contexts (nested class-type fields) instead bubble the change
--- up to their parent so the whole owning entity is re-fired and written as one unit.
function Context:_Persist()
	if self.Parent then
		self.Parent:_Fire(self.ParentField, self.Parent.Instance[self.ParentField])
		self.Parent:_Persist()
	elseif ACF.Menu.QueuePersist then
		ACF.Menu.QueuePersist(self)
	end
end

--- Registers a change callback. Field may be nil (or omitted) to listen to every change.
--- Id lets you register/remove multiple callbacks independently. Returns an unsubscribe function.
--- Callback signature: Fn(Context, Field, Value).
function Context:OnChange(Id, Field, Fn)
	-- Allow OnChange(Id, Fn) as shorthand for "any field".
	if isfunction(Field) and Fn == nil then
		Fn    = Field
		Field = nil
	end

	local Key   = Field or ANY
	local Store = self._Callbacks[Key]

	if not Store then
		Store = {}
		self._Callbacks[Key] = Store
	end

	Store[Id] = Fn

	return function() self:RemoveCallback(Id, Field) end
end

--- Removes a previously registered callback.
function Context:RemoveCallback(Id, Field)
	local Store = self._Callbacks[Field or ANY]
	if Store then Store[Id] = nil end
end

--- Serializes the live instance into the flat/nested table used for networking and disk storage.
function Context:Serialize()
	return Serialization.Serialize(self.Class, self.Instance)
end

--- Applies a saved/serialized table onto the live instance (menu fields only), then refreshes any
--- bound widgets by firing change callbacks for every menu field. Does not re-persist.
function Context:Hydrate(Data)
	if not Data then return end

	Serialization.DeserializeInto(self.Class, self.Instance, Data)

	for _, Field in ipairs(Classes.GetTypeFields(self.Class)) do
		if Field.Menu then
			self:_Fire(Field.Name, self.Instance[Field.Name])
		end
	end

	self:_Fire(ANY, nil)
end

--- Merges preview ghost data ({ Model, Material, Scale, AbsoluteScale, PosOffset, AngOffset }) used
--- by the toolgun preview, and refreshes the live ghost if this context is the active one.
function Context:SetPreview(Data)
	self.Preview = self.Preview or {}
	for K, V in pairs(Data) do self.Preview[K] = V end

	if ACF.Menu.RefreshPreview then
		ACF.Menu.RefreshPreview(self)
	end
end

--- Creates a new EntityContext for the given entity class name (e.g. "acf_gun").
--- PersistKey defaults to the class name and controls the on-disk settings file.
function ACF.Menu.Context(ClassName, PersistKey)
	local Class = Classes.GetTypeByName(ClassName)

	if not Class then
		ErrorNoHaltWithStack("ACF.Menu.Context: unknown class '" .. tostring(ClassName) .. "'\n")
		return nil
	end

	local New = setmetatable({
		ClassName  = ClassName,
		Class      = Class,
		Instance   = Class(),
		PersistKey = PersistKey or ClassName,
		_Callbacks = {},
	}, Context)

	-- Restore the user's last-used settings from disk, if any.
	if ACF.Menu.LoadPersisted then
		ACF.Menu.LoadPersisted(New)
	end

	return New
end

--- Creates a sub-context wrapping a parent context's nested class-instance field. Edits made through
--- it mutate the shared nested instance and bubble up to the parent for persistence and callbacks.
--- Used by the field dispatcher to render the controls of a nested class type (e.g. the weapon inside
--- a gun, or an ammo type inside a crate).
function ACF.Menu.SubContext(Parent, FieldName)
	local Instance = Parent:Get(FieldName)
	if not (Instance and Instance.GetType) then return nil end

	return setmetatable({
		ClassName   = Classes.GetTypeName(Instance:GetType()),
		Class       = Instance:GetType(),
		Instance    = Instance,
		PersistKey  = Parent.PersistKey,
		_Callbacks  = {},
		Parent      = Parent,
		ParentField = FieldName,
	}, Context)
end
