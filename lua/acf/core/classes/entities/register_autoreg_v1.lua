--[[
The purpose of this class is to define a class that represents an entity, storing its spawn function as well as registering the arguments attached to the entity with duplicators.
--]]


local UserArgumentTypes = {}

--- Populates the Restrictions table of an entity class under `Restrictions` after verifying the format is correct.
local function AddArgumentRestrictions(Entity, ArgumentRestrictions)
	local Restrictions = Entity.Restrictions

	for k, v in pairs(ArgumentRestrictions) do
		-- Basic check to make sure the argument restrictions have the proper format
		if not v.Type                then error("Argument '" .. tostring(k or "<NIL>") .. "' didn't have a Type!") end
		if not isstring(v.Type)      then error("Argument '" .. tostring(k or "<NIL>") .. "' has a non-string Type! (" .. tostring(v.Type) .. ")") end
		if not UserArgumentTypes[v.Type] then error("Argument '" .. tostring(k or "<NIL>") .. "' has a non-registered Type! (" .. tostring(v.Type) .. ")") end

		Restrictions[k] = v
	end
end

--- Adds an argument type and verifier to the ArgumentTypes dictionary.
--- @param Type string The type of data
local function AddUserArgumentType(Type)
	if UserArgumentTypes[Type] then return end

	-- Def can contain Validator, PreCopy, PostPaste, Getter
	local Def = {
		IsClientData = true
	}
	UserArgumentTypes[Type] = Def
	return Def
end

local NumberType = AddUserArgumentType("Number")
function NumberType.Validator(Ctx, Value)
	if not isnumber(Value) then Value = ACF.CheckNumber(Value, Ctx:GetSpec("Default") or 0) end

	if Ctx:HasSpec("Decimals") then Value = math.Round(Value, Ctx:GetSpec("Decimals")) end
	if Ctx:HasSpec("Min")      then Value = math.max(Value, Ctx:GetSpec("Min")) end
	if Ctx:HasSpec("Max")      then Value = math.min(Value, Ctx:GetSpec("Max")) end

	return Value
end

local StringType = AddUserArgumentType("String")
function StringType.Validator(Ctx, Value)
	local Specs = Ctx:GetSpecs()
	if not isstring(Value) then
		Value = Specs.Default or "N/A"
	end

	return Value
end

local BooleanType = AddUserArgumentType("Boolean")
function BooleanType.Validator(Ctx, Value)
	local Specs = Ctx:GetSpecs()
	if not isbool(Value) then
		Value = Specs.Default or false
	end

	return Value
end

-- These should be removed in a future class rewrite
local SimpleClassType = AddUserArgumentType("SimpleClass")
function SimpleClassType.Validator(Ctx, Value)
	local Specs = Ctx:GetSpecs()
	if not isstring(Value) then
		Value = Specs.Default or "N/A"
	end

	local ClassDef = ACF.Classes[Specs.ClassName]
	if not ClassDef then error("Bad classname '" .. Specs.ClassName .. "'.") end

	if not ClassDef.Get(Value) then
		error("Classdef resolve failed. Likely data corruption/outdated contraption + default value not set by entity implementor. (value was " .. Value .. ")")
	end

	return Value
end

function SimpleClassType.Getter(self, Ctx, Key)
	local Specs = Ctx:GetSpecs()
	return ACF.Classes[Specs.ClassName].Get(Key)
end

local GroupClassType = AddUserArgumentType("GroupClass")
function GroupClassType.Validator(Ctx, Value)
	local Specs = Ctx:GetSpecs()
	if not isstring(Value) then
		Value = Specs.Default or "N/A"
	end

	local ClassDef = ACF.Classes[Specs.ClassName]
	if not ClassDef then error("Bad classname '" .. Specs.ClassName .. "'.") end

	local Group, Item = ACF.Classes.GetGroup(ClassDef, Value)

	if not Item then
		Item = Group
	end

	if not Item then
		Item = ACF.Classes.GetGroup(ClassDef, Specs.Default or "N/A")
		Value = Specs.Default or "N/A"
	end

	if not Item then
		error("Classdef resolve failed. Likely data corruption/outdated contraption + default value not set by entity implementor. (value was " .. Value .. ")")
	end

	return Value
end

function GroupClassType.Getter(self, Ctx, Key)
	local Group, Item = ACF.Classes.GetGroup(ACF.Classes[Ctx:GetSpecs().ClassName], Key)
	return Item or Group
end

-- Single entity link.
local LinkedEntityType = AddUserArgumentType("LinkedEntity")
LinkedEntityType.IsClientData = false

function LinkedEntityType.Validator(Specs, Value)
	if not isentity(Value) or not IsValid(Value) then Value = NULL return Value end

	if Specs.Classes then
		local class = Value:GetClass()
		if Specs.Classes[class] then return Value end

		return NULL
	end
	return Value
end
function LinkedEntityType.PreCopy(_, _, Value)
	return Value:EntIndex()
end

function LinkedEntityType.PostPaste(self, _, Value, CreatedEnts)
	local Ent = CreatedEnts[Value]
	if not IsValid(Ent) then return NULL end

	return self:Link(Ent) and Ent or NULL
end

-- Entity link LUT where Key == Entity and Value == true.
local LinkedEntitiesType = AddUserArgumentType("LinkedEntities")
LinkedEntitiesType.IsClientData = false

function LinkedEntitiesType.Validator(Specs, Value)
	if not istable(Value) then Value = {} return Value end

	if Specs.Classes then
		-- Check everything. What's valid?
		local NewTable = {}
		for Entity in pairs(Value) do
			if IsValid(Entity) and Specs.Classes[Entity:GetClass()] then
				NewTable[Entity] = true
			end
		end

		return NewTable
	else
		return Value
	end
end

function LinkedEntitiesType.Init(_)
	return {} -- Empty table
end

function LinkedEntitiesType.PreCopy(_, _, Value)
	local EntIndexTable = {}
	for Entity in pairs(Value) do
		EntIndexTable[#EntIndexTable + 1] = Entity:EntIndex()
	end
	return EntIndexTable
end

function LinkedEntitiesType.PostPaste(self, Ctx, Value, CreatedEnts)
	-- This will have been initialized by LinkedEntitiesType.Init.
	-- We need the old table in this case since the table is by-ref
	local EntTable = self:ACF_GetUserVar(Ctx:GetCurrentVarName())
	Value = table.Copy(Value)
	table.Empty(EntTable)

	for _, EntIndex in ipairs(Value) do
		local Created = CreatedEnts[EntIndex]
		if IsValid(Created) and self:Link(Created) then
			EntTable[Created] = true
		end
	end

	return EntTable
end

--- Adds extra arguments to a class which has been created via Entities.AutoRegister() (or Entities.Register() with no arguments)
--- @param Class string A class previously registered as an entity class
--- @param DataKeys table A key-value table, where key is the name of the data and value defines the type and restrictions of the data.
local function AddStrictArguments(Class, UserVariables)
	if not isstring(Class) then return end

	local Entity    = Entities.GetEntityTable(Class)

	local UserVars  = table.GetKeys(UserVariables)
	local ArgumentNames  = {}
	local Arguments = {}

	for _, v in ipairs(UserVars) do ArgumentNames[#ArgumentNames + 1] = v; Arguments[v] = UserVariables[v] end

	local List      = Entities.AddArgumentsRaw(Entity, ArgumentNames)
	AddArgumentRestrictions(Entity, Arguments)
	return List
end

-- Verification context object
local VerificationContext_MT_methods = {}
local VerificationContext_MT = {__index = VerificationContext_MT_methods}

function VerificationContext_MT_methods:GetCurrentVarName()
	return self.VarName
end

-- Sets the current var context. This is used by the internal verify client data methods.
function VerificationContext_MT_methods:SetCurrentVar(VarName)
	local RestrictionSpecs = self.Restrictions[VarName]
	if not RestrictionSpecs then error("No restriction specs for " .. VarName) end
	local ArgumentVerification = UserArgumentTypes[RestrictionSpecs.Type]

	self.VarName = VarName
	self.RestrictionSpecs = RestrictionSpecs
	self.ArgTypeInfo = ArgumentVerification
end

-- Checks if the current variable has restrictions or not.
function VerificationContext_MT_methods:CurrentVarHasRestrictions()
	return self.ArgTypeInfo ~= nil
end

-- Calls ipairs on the internal var list
function VerificationContext_MT_methods:IterateVars()
	return ipairs(self.List)
end

-- Gets the specs of the current variable, if in a variable validation context.
function VerificationContext_MT_methods:GetSpecs()
	return self.RestrictionSpecs or error("Not in variable validation context!")
end

function VerificationContext_MT_methods:HasSpec(Key)
	return self.RestrictionSpecs == nil and error("Not in variable validation context!") or self.RestrictionSpecs[Key] ~= nil
end

-- Gets the type object of the current variable
function VerificationContext_MT_methods:GetType()
	return self.ArgTypeInfo or error("Not in variable validation context!")
end

-- Gets a specification index by name. NeverCallbackFn is optional. If not provided/false, then
-- functions are considered of the delegate T DetermineSpecValueFn<T>(ValidationContext ctx, string key)
function VerificationContext_MT_methods:GetSpec(Key, NeverCallbackFn)
	local Spec = self:GetSpecs()[Key]
	if isfunction(Spec) then
		if NeverCallbackFn then
			return Spec
		else
			return Spec(self, Key)
		end
	else
		return Spec
	end
end

-- Validates the current variable.
function VerificationContext_MT_methods:ValidateCurrentVar(Value)
	local ArgumentVerification = self.ArgTypeInfo
	if not ArgumentVerification then error("No verification function for type '" .. tostring(self.RestrictionSpecs.Type or "<NIL>") .. "'") end

	return ArgumentVerification.Validator(self, Value)
end

function VerificationContext_MT_methods:StartClientData(ClientData)
	self.ClientData = ClientData
end

function VerificationContext_MT_methods:EndClientData()
	self.ClientData = nil
end

function VerificationContext_MT_methods:IsValidatingClientData()
	return self.ClientData ~= nil
end

-- Resolves a client data variable immediately. Note that this does not store the result - this is intentional
function VerificationContext_MT_methods:ResolveClientData(Key)
	if not self:IsValidatingClientData() then error("Cannot resolve client data when the verification context isn't working with client data!") end

	local RestoreVar = self:GetCurrentVarName()
	self:SetCurrentVar(Key)
	local Value
	do
		local Type  = self:GetType()
		Value = self:ValidateCurrentVar(Value)
		if Type.Getter then
			Value = Type.Getter(NULL, self, Value)
		end
	end
	self:SetCurrentVar(RestoreVar)
	return Value
end

local function VerificationContext(Class)
	local Entity = Entities.GetEntityTable(Class)
	return setmetatable({
		Class        = Class,
		List         = Entity.List,
		Restrictions = Entity.Restrictions
	}, VerificationContext_MT)
end

--[[

MARCH: This is the IDEAL way to create new entities within ACF. It is still experimental so report bugs to me.
We should try to refactor some critical components (fuel, for example) to use this system - which will likely require
some backwards compat layer, etc... we'll figure that out when we get to that point. 

LEN: "Strict" entity arguments are intended to be validated using the new API (see: UserData/UserVars).
"Non Strict" entity arguments exist mostly for backwards compatibility and are often validated outside the API.
Also, You should be able to do everything with the API functions we documented in this comment block.
If not, then please notify us and we will figure out how to support it.
Finally, note that autoreg does not use duplicator.StoreEntityModifier, it seems to work through duplicator.RegisterEntityClass.


AutoRegister calls should always be at the end of the file.
Some properties should always be defined in shared.lua.
See acf_baseplate's shared.lua for an example.

Here's what this entity API exposes/uses:

ENTITY METHODS AND FIELDS
	ENT.ACF_Limit (typeof number)
		Defines the maximum amount of entities of Classname, optional
		The convar will be "sbox_max_acf_<Classname>"
		where Classname is the name of the folder containing the file Entities.Autoregister was called in.
			E.g. entities/baseplates/shared.lua -> "baseplates"

	ENT.ACF_UserVars
		A table of (shared) key-value pairs. Key is the user variable name, value is a table defining
			Type (string)
			ClientData (boolean)
			Type-specific parameters (...kvargs) (e.g. Min, Max, Default)

	ENT.ACF_GetHookArguments(ClientData)
		Non-entity context function used to pass entity-specific arguments around throughout the entity's logic,
		usually in hook calls leading to external sources (e.g. ACF_Pre/OnSpawnEntity)

	ENT:ACF_PreUpdateEntityData(ClientData)
		Pre-update entity data hook, optional

	ENT:ACF_PostUpdateEntityData(ClientData)
		Post-update entity data hook, optional

	ENT.ACF_PreVerifyClientData(ClientData)
		Non-entity context clientdata verification. Called immediately before UserVar validation is performed.
		This is useful if you need to perform validation between entity arguments.
		Similar in use to the VerifyData functions in the old API.

	ENT.ACF_OnVerifyClientData(ClientData)
		Non-entity context clientdata verification. Called immediately after UserVar validation is performed.
		This is useful if you need to perform validation between entity arguments.
		Similar in use to the VerifyData functions in the old API.

	ENT.ACF_CustomGetterCache (table)
		ACF_GetUserVar/ACF_SetUserVar will check this table before ACF_LiveData for types with custom getters

	ENT.ACF_LiveData (table)
		The raw table behind ACF_GetUserVar/ACF_SetUserVar. Will not perform any validation on sets

	ENT.ACF_UserData (table)
		On PreEntityCopy, this table is populated by ACF_LiveData and variable pre-paste transformers for duplication. 
		On PostEntityPaste, this table populates ACF_LiveData using variable post-paste transformers.

	ENT:ACF_GetUserVar(Key)
		Gets a user variable by Key

	ENT:ACF_SetUserVar(Key, Value)
		Sets a user variable by Key to Value. Automatically pulls the typedef for the user and performs the validator.
		If you don't want to perform validation on sets, you can directly set Entity.ACF_LiveData[Key] = Value.

	ENT:OnRemove(IsFullUpdate)
		Identical to Garry's Mod's API with some generic ACF removal behavior surrounding your custom OnRemove.
		In the old API this was done manually.

	ENT:PreEntityCopy()
		Identical to Garry's Mod's API but autoreg automatically saves your user vars from
		the entity to the dupe before calling your custom PreEntityCopy.
		In the old API this was done manually.

	ENT:PostEntityPaste(Player, Ent, CreatedEntities)
		Identical to Garry's Mod's API but autoreg automatically loads and validates your user vars from
		the dupe to the entity, before calling your custom PostEntityPaste.
		In the old API this was done manually.

	ENT:PostMenuSpawn()
		If specified, called by the menu tool after the entity has been spawned.
		If not specified, menu tool will just drop it to the floor.

BASE TYPES
	-- ClientData or internal data
	Number {Default:double? (evals to Default ?? 0), Decimals:int, Min:double?, Max:double?}
	String {Default:string? (evals to Default ?? "N/A")}
	Boolean {Default:boolean? (evals to Default ?? false)}

	-- Internal data only
	SimpleClass {Default:string? (evals to Default ?? "N/A"), ClassName:string?}
	LinkedEntity {Classes:string[]?} -- classes is an allowed classes list

AUTOREG TYPE API (semi-internal...)
	T ValidateUserVarDelegate<T>(T untrustedValue, table variableSpecifications)
		Untrusted value comes from user land
		Variable specifications is a reference to the table you made in ENT.ACF_UserVars[InsertKeyHere]

	any PreCopyUserVarDelegate(Entity self, T currentValue)
		Allows mutating the user variable to any other type (say, an entity -> entity index)
		Is optional, but likely required if you defined PostPasteUserVarDelegate.

	T PostPasteUserVarDelegate(Entity newEntity, any dupeUntrustedValue, table createdEntities);
		Allows mutating the saved user variable to T again after a PreCopyUserVarDelegate
		You do not need to validate untrusted value, it is validated immediately after this delegate is called
		Is optional, but likely required if you defined PreCopyUserVarDelegate.

	AddUserArgumentType(TypeName, ValidateUserVarDelegate, PreCopyUserVarDelegate?, PostPasteUserVarDelegate?)
]]

-- NEW CHANGE: ACF_UserData has been split into ACF_UserData and ACF_LiveData. The reason being that
-- we need a "live real time" version (which is now UserData) and a "saveable without overwriting the real time
-- data" (which is now SavedUserData).

-- TODO: This sucks a lot. Need to re-review clientdata/uservar relationship
local function PrioritizeFieldDefFlag(FieldDef, TypeDef, Flag)
	local Value = FieldDef[Flag]
	if Value == nil then return TypeDef[Flag] end
	return Value
end

-- Automatically registers an entity. This MUST be the last line in entity/init.lua for everything to work properly
-- Can be passed with an ENT table if you have some weird usecase, but auto defaults to _G.ENT
--- @param ENT table A scripted entity class definition (see https://wiki.facepunch.com/gmod/Structures/ENT)
function Entities.AutoRegisterV1(ENT)
	if ENT == nil then ENT = _G.ENT end
	if not ENT then error("Called Entities.AutoRegister(), but no entity was in the process of being created.") end

	-- Class is the name of the subfolder within entities that Entities.Autoregister was called from
	-- e.g. entities/baseplates/shared.lua -> "baseplates"
	local Class  = string.Split(ENT.Folder, "/"); Class = Class[#Class]
	ENT.ACF_Class = Class

	local Entity = Entities.GetEntityTable(Class)
	local UserVars = ENT.ACF_UserVars or {}
	AddStrictArguments(Class, UserVars)

	local WireIO   = ACF.Utilities.WireIO
	local Wire_Inputs, Wire_Outputs = ENT.ACF_WireInputs, ENT.ACF_WireOutputs

	if isnumber(ENT.ACF_Limit) then
		Classes.AddSboxLimit({
			Name   = "_" .. Class,
			Amount = ENT.ACF_Limit,
			Text   = "Maximum amount of " .. (ENT.PluralName or (Class .. " entities")) .. " a player can create."
		})
	end

	if CLIENT then return end

	--- Used in various places throughout an entity to provide a variable number of entity-specific arguments.
	--- Does nothing by default.
	if not ENT.ACF_GetHookArguments then
		function ENT:ACF_GetHookArguments()
			return nil
		end
	end

	local VerificationCtx = VerificationContext(Class)

	-- Verification function
	local function VerifyClientData(ClientData)
		-- Perform general verification
		if ENT.ACF_PreVerifyClientData then ENT.ACF_PreVerifyClientData(ClientData, ENT.ACF_GetHookArguments(ClientData)) end

		VerificationCtx:StartClientData(ClientData)
		-- Perform per argument verification
		for _, argName in VerificationCtx:IterateVars() do
			VerificationCtx:SetCurrentVar(argName)
			local Typedef = VerificationCtx:GetType()
			local Specs   = VerificationCtx:GetSpecs()
			if VerificationCtx:CurrentVarHasRestrictions() and PrioritizeFieldDefFlag(Specs, Typedef, "IsClientData") then
				ClientData[argName] = VerificationCtx:ValidateCurrentVar(ClientData[argName])
			end
		end
		VerificationCtx:EndClientData()

		-- Perform general verification
		if ENT.ACF_OnVerifyClientData then ENT.ACF_OnVerifyClientData(ClientData, ENT.ACF_GetHookArguments(ClientData)) end

		-- Perform external verification
		hook.Run("ACF_OnVerifyData", Class, ClientData, ENT.ACF_GetHookArguments(ClientData))
	end

	--- Updates a specific user var and calls the getter cache.
	local function SetLiveData(self, Key, Value)
		local EntTable          = self:GetTable()
		local LiveData          = EntTable.ACF_LiveData
		local CustomGetterCache = EntTable.ACF_CustomGetterCache

		local RestrictionSpecs = Entities.GetEntityTable(Class).Restrictions[Key]
		local TypeSpecs = UserArgumentTypes[RestrictionSpecs.Type]

		if RestrictionSpecs then
			local Validator = TypeSpecs.Validator
			if Validator then
				VerificationCtx:SetCurrentVar(Key)
				LiveData[Key] = VerificationCtx:ValidateCurrentVar(Value)
			else
				LiveData[Key] = Value
			end
			VerificationCtx:SetCurrentVar(Key)
			local Getter    = TypeSpecs.Getter
			if Getter then
				CustomGetterCache[Key] = Getter(self, VerificationCtx, Value)
			end
		else
			LiveData[Key] = Value
		end
	end

	--- Updates the entity's user vars with ClientData
	--- @param self table The entity to update
	--- @param ClientData table The client data to use for the update
	local function UpdateEntityData(self, ClientData)
		local Entity       = Entities.GetEntityTable(Class) -- THE ENTITY TABLE, NOT THE ENTITY ITSELF
		local List         = Entity.List

		if self.ACF_PreUpdateEntityData then self:ACF_PreUpdateEntityData(ClientData) end
		self.ACF = self.ACF or {} -- Why does this line exist? I feel like there's a reason and it scares me from removing it
		local FirstTimeLiveData = not self.ACF_LiveData
		self.ACF_LiveData = self.ACF_LiveData or {}
		local ACF_LiveData = self.ACF_LiveData
		self.ACF_CustomGetterCache = self.ACF_CustomGetterCache or {}

		VerificationCtx:StartClientData(ClientData)

		-- For entity arguments that are marked as client data, set them on the entity from ClientData
		for _, v in ipairs(List) do
			local RestrictionSpecs = Entity.Restrictions[v]
			if RestrictionSpecs then
				local Typedef = UserArgumentTypes[RestrictionSpecs.Type]

				if FirstTimeLiveData then
					if Typedef.Init then
						ACF_LiveData[v] = Typedef.Init(RestrictionSpecs)
					else
						ACF_LiveData[v] = RestrictionSpecs.Default
					end
				end

				if FirstTimeLiveData or PrioritizeFieldDefFlag(RestrictionSpecs, Typedef, "IsClientData") then
					SetLiveData(self, v, ClientData[v])
				end
			end
		end

		VerificationCtx:EndClientData()

		if Wire_Inputs then
			WireIO.SetupInputs(self, Wire_Inputs, ClientData, ENT.ACF_GetHookArguments(ClientData))
		end

		if Wire_Outputs then
			WireIO.SetupOutputs(self, Wire_Outputs, ClientData, ENT.ACF_GetHookArguments(ClientData))
		end

		if self.ACF_PostUpdateEntityData then self:ACF_PostUpdateEntityData(ClientData) end

		-- Storing all the relevant information on the entity for duping
		local DataStore = self.DataStore

		if DataStore then
			for _, V in ipairs(DataStore) do
				self[V] = ClientData[V]
			end
		end

		ACF.Activate(self, true)
	end

	--- Verifies then updates the entity with the provided client data
	function ENT:Update(ClientData)
		VerifyClientData(ClientData)

		local CanUpdate, Reason = hook.Run("ACF_PreUpdateEntity", Class, self, ClientData, ENT.ACF_GetHookArguments(ClientData))
		if CanUpdate == false then return CanUpdate, Reason end

		local OldClassData = self.ClassData

		if OldClassData and OldClassData.OnLast then
			OldClassData.OnLast(self, OldClassData)
		end

		hook.Run("ACF_OnEntityLast", Class, self, OldClassData)

		ACF.SaveEntity(self)
		UpdateEntityData(self, ClientData)
		ACF.RestoreEntity(self)

		hook.Run("ACF_OnUpdateEntity", Class, self, ClientData, ENT.ACF_GetHookArguments(ClientData))

		return true, (self.PrintName or Class) .. " updated successfully!"
	end

	--- Called elsewhere by the menu tool after spawning if specified
	if not ENT.ACF_PostMenuSpawn then
		function ENT:ACF_PostMenuSpawn()
			ACF.DropToFloor(self)
		end
	end

	--- Gets the value of a user variable
	function ENT:ACF_GetUserVar(Key)
		if not Key then error("Tried to get the value of a nil key.") end
		if not UserVars[Key] then error("No user-variable named '" .. Key .. "'.") end

		return self.ACF_CustomGetterCache[Key] or self.ACF_LiveData[Key]
	end

	--- Sets the value of a user variable after validating the value
	function ENT:ACF_SetUserVar(Key, Value)
		if not Key then error("Tried to set the value of a nil key.") end

		SetLiveData(self, Key, Value)
	end
	local ACF_Limit       = ENT.ACF_Limit
	local OnRemove        = ENT.OnRemove
	local PreEntityCopy   = ENT.PreEntityCopy
	local PostEntityPaste = ENT.PostEntityPaste

	--- Spawns the entity, verify the data, update/check the limits and check legality.
	--- @param Player Player The player who is spawning the entity
	--- @param Pos Vector The position to spawn the entity at
	--- @param Angle Angle The angle to spawn the entity at
	--- @param ClientData table The client data to use for the entity
	--- @return Entity # The created entity
	function Entity.Spawn(Player, Pos, Angle, ClientData)
		VerifyClientData(ClientData)

		if ACF_Limit then
			if isfunction(ACF_Limit) then
				if not ACF_Limit(Player, ClientData) then return end
			elseif isnumber(ACF_Limit) then
				if not Player:CheckLimit("_" .. Class) then return false end
			end
		end

		local CanSpawn = hook.Run("ACF_PreSpawnEntity", Class, Player, ClientData, ENT.ACF_GetHookArguments(ClientData))
		if CanSpawn == false then return false end

		local New = ents.Create(Class)
		if not IsValid(New) then return end

		New:SetPos(Pos)
		New:SetAngles(Angle)
		if New.ACF_PreSpawn then
			New:ACF_PreSpawn(Player, Pos, Angle, ClientData)
		end

		New:Spawn()
		Player:AddCount("_" .. Class, New)
		Player:AddCleanup(Class, New)

		if New.ACF_OnSpawn then
			New:ACF_OnSpawn(Player, Pos, Angle, ClientData)
		end
		hook.Run("ACF_OnSpawnEntity", Class, New, ClientData, ENT.ACF_GetHookArguments(ClientData))

		New:ACF_UpdateEntityData(ClientData)
		if New.ACF_PostSpawn then
			New:ACF_PostSpawn(Player, Pos, Angle, ClientData)
		end

		return New
	end

	--- Runs some generic removal behavior when the entity is deleted
	function ENT:OnRemove(IsFullUpdate)
		local ClassData = self.ClassData

		if ClassData and ClassData.OnLast then
			ClassData.OnLast(self, ClassData)
		end

		hook.Run("ACF_OnEntityLast", Class, self, ClassData)

		-- Call original ENT.OnRemove if any unique behavior needs to be run
		if OnRemove then OnRemove(self, IsFullUpdate) end

		WireLib.Remove(self)
	end

	--- Runs the Validator and PreCopy for methods for each user var
	function ENT:PreEntityCopy()
		if not self.ACF_UserData then
			self.ACF_UserData = {}
		else
			table.Empty(self.ACF_UserData)
		end

		VerificationCtx:StartClientData(self.ACF_UserData)
		for Var in pairs(UserVars) do
			VerificationCtx:SetCurrentVar(Var)
			local typedef   = VerificationCtx:GetType()
			local value     = VerificationCtx:ValidateCurrentVar(self.ACF_LiveData[Var])

			if typedef.PreCopy then
				value = typedef.PreCopy(self, VerificationCtx, value)
			end

			self.ACF_UserData[Var] = value
		end
		VerificationCtx:EndClientData()

		-- Call original ENT.PreEntityCopy
		if PreEntityCopy then PreEntityCopy(self) end

		-- Call the base class' PreEntityCopy (Wiremod base class probably uses this)
		self.BaseClass.PreEntityCopy(self)
	end

	--- Runs the PostPaste and Validator methods for each user var
	function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
		local UserData = Ent.ACF_UserData
		if not UserData then
			UserData = {}
			Ent.ACF_UserData = UserData
		end

		VerificationCtx:StartClientData(UserData)

		for Key in pairs(UserVars) do
			VerificationCtx:SetCurrentVar(Key)
			local typedef = VerificationCtx:GetType()

			local check = UserData and UserData[Key] or Ent[Key]
			if typedef.PostPaste then
				check = typedef.PostPaste(Ent, VerificationCtx, check, CreatedEntities)
			end

			SetLiveData(self, Key, check)
		end
		VerificationCtx:EndClientData()

		-- Call original ENT.PostEntityPaste
		if PostEntityPaste then PostEntityPaste(Ent, Player, Ent, CreatedEntities) end

		-- Call the base class' PostEntityPaste (Wiremod base class probably uses this)
		Ent.BaseClass.PostEntityPaste(Ent, Player, Ent, CreatedEntities)
	end

	ENT.ACF_VerifyClientData = VerifyClientData
	ENT.ACF_UpdateEntityData = UpdateEntityData

	local UserVarsKeys = table.GetKeys(UserVars)
	local BackwardsCompatKeys
	-- Check if the entity defined a method to get backwards compatibility keys.
	-- This needs to return a sequential table of all keys to read, and those keys CANNOT be userdata keys!
	if ENT.ACF_GetBackwardsCompatibilityDataKeys then
		BackwardsCompatKeys = ENT.ACF_GetBackwardsCompatibilityDataKeys()
		for I = 1, #BackwardsCompatKeys do
			if UserVars[BackwardsCompatKeys[I]] then
				error("Error while performing ACF entity autoregistration: ACF_GetBackwardsCompatibilityDataKeys returned key " ..
			          "'" .. BackwardsCompatKeys[I] .. "' at index " .. I .. " which conflicts with an already existing uservar key.")
			end
		end
	else
		BackwardsCompatKeys = {}
	end

	local ReadKeys = table.Copy(UserVarsKeys)
	for I = 1, #BackwardsCompatKeys do
		ReadKeys[#ReadKeys + 1] = BackwardsCompatKeys[I]
	end

	local function SpawnFunction(Player, Pos, Angle, UserData, ...)
		local ShouldTransferLegacyData = false

		if not istable(UserData) then
			local NewUserData, ArgCount = table.Pack(...)

			-- ACF_UserData doesn't exist, but other arguments do.
			-- This most likely means that the entity is one that was duped before it was converted to use
			-- the autoregistration system. Let's build a replacement table for it and clear the old data.
			UserData = {} -- Always create a table
			if ArgCount > 0 then
				for Index, ArgValue in ipairs(NewUserData) do
					UserData[ReadKeys[Index]] = ArgValue
				end

				ShouldTransferLegacyData = true
			end
		end

		local success, SpawnedEntity = Entities.Spawn(Class, Player, Pos, Angle, UserData, true)
		if not success then
			ErrorNoHaltWithStack(SpawnedEntity)
			return
		end

		if ShouldTransferLegacyData then
			for _, KeyName in ipairs(ReadKeys) do
				duplicator.ClearEntityModifier(SpawnedEntity, KeyName)
			end
		end
		SpawnedEntity.ACF_UserData = UserData -- Cache it away. PostEntityPaste might want it later anyway
		return SpawnedEntity
	end

	duplicator.RegisterEntityClass(Class, SpawnFunction, "Pos", "Angle", "ACF_UserData", unpack(ReadKeys))
end

