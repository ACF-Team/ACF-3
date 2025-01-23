--[[
The purpose of this class is to define a class that represents an entity, storing its spawn function as well as registering the arguments attached to the entity with duplicators.
--]]

local duplicator = duplicator
local isfunction = isfunction
local isstring   = isstring
local istable    = istable
local unpack     = unpack
local Classes    = ACF.Classes
local Entities   = Classes.Entities
local Entries    = {}

--- Gets the entity table of a certain class
--- If an entity table doesn't exist for the class, it will register one.
--- @param Class table The class to get the entity table from
--- @return {Lookup:table, Count:number, List:table} # The entity table of this class
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

--- Adds arguments to an entity for storage in duplicators
--- The Entity.Lookup, Entity.Count and Entity.List variables allow us to iterate over this information in different ways. 
--- @param Entity entity The entity to add arguments to
--- @param Arguments any[] # An array of arguments to attach to the entity (usually {...})
--- @return any[] # An array of arguments attached to the entity
local function AddArguments(Entity, Arguments)
	local Lookup = Entity.Lookup
	local Count  = Entity.Count
	local List   = Entity.List

	for _, V in ipairs(Arguments) do
		if Lookup[V] then continue end

		Count = Count + 1

		Lookup[V]   = true
		List[Count] = V
	end

	Entity.Count = Count

	return List
end

local UserArgumentTypes = {}
local DataArgumentTypes = {}

local function AddArgumentRestrictions(Entity, ArgumentRestrictions)
	local Restrictions = Entity.Restrictions

	for k, v in pairs(ArgumentRestrictions) do
		if not v.Type                then error("Argument '" .. tostring(k or "<NIL>") .. "' didn't have a Type!") end
		if not isstring(v.Type)      then error("Argument '" .. tostring(k or "<NIL>") .. "' has a non-string Type! (" .. tostring(v.Type) .. ")") end
		if not UserArgumentTypes[v.Type] and not DataArgumentTypes[v.Type] then error("Argument '" .. tostring(k or "<NIL>") .. "' has a non-registered Type! (" .. tostring(v.Type) .. ")") end

		Restrictions[k] = v
	end
end


--- Adds an argument type and verifier to the ArgumentTypes dictionary.
--- @param Type string The type of data
--- @param Validator function The verification function. Arguments are: Value:any, Restrictions:table. Must return a Value of the same type and NOT nil!
function Entities.AddUserArgumentType(Type, Validator)
	if UserArgumentTypes[Type] then return end

	UserArgumentTypes[Type] = {
		Validator = Validator
	}
end

function Entities.AddDataArgumentType(Type, Validator, PreCopy, PostPaste)
	if DataArgumentTypes[Type] then return end

	DataArgumentTypes[Type] = {
		Validator  = Validator,
		PreCopy   = PreCopy,
		PostPaste = PostPaste
	}
end

Entities.AddUserArgumentType("Number", function(Value, Specs)
	if not isnumber(Value) then Value = ACF.CheckNumber(Value, Specs.Default or 0) end

	if Specs.Decimals then Value = math.Round(Value, Specs.Decimals) end
	if Specs.Min then Value = math.max(Value, Specs.Min) end
	if Specs.Max then Value = math.min(Value, Specs.Max) end

	return Value
end)

Entities.AddUserArgumentType("String", function(Value, Specs)
	if not isstring(Value) then
		Value = Specs.Default or "N/A"
	end

	return Value
end)

Entities.AddDataArgumentType("LinkedEntity",
	function(Value, Specs)
		if not isentity(Value) or not IsValid(Value) then Value = NULL return Value end

		if Specs.Classes then
			local class = Value:GetClass()
			if Specs.Classes[class] then return Value end

			return NULL
		end
	end,
	function(_, value)
		return value:EntIndex()
	end,
	function(self, value, createdEnts)
		self:Link(createdEnts[value])
		return createdEnts[value]
	end
)

-- MARCH: Untested!
-- And if this code stays here, fix the PascalCase issue
--[[
Entities.AddDataArgumentType("LinkedEntities",
	function(Value, Specs)
		if not Value then return {} end
		if isentity(Value) then Value = {Value} end
		if not istable(Value) then return {} end

		local Ret = {}
		local max = Specs.Max
		for k, v in ipairs(Value) do
			if max and k > max then break end
			if not isentity(v) or not IsValid(v) then
				v = NULL
			else
				if Specs.Classes then
					local class = v:GetClass()
					if not Specs.Classes[class] then
						v = NULL
					end
				end
			end

			Ret[k] = v
		end

		return Value
	end,
	function(_, value)
		local ret = {}

		for k, v in ipairs(value) do
			ret[k] = v:EntIndex()
		end

		return ret
	end,
	function(self, value, createdEnts)
		local ret = {}

		for k, v in ipairs(value) do
			local realEnt = createdEnts[v]
			ret[k] = realEnt
			self:Link(realEnt)
		end

		return ret
	end
)]]

--- Adds extra arguments to a class which has been created via Entities.AutoRegister() (or Entities.Register() with no arguments)
--- @param Class string A class previously registered as an entity class
--- @param DataKeys table A key-value table, where key is the name of the data and value defines the type and restrictions of the data.
function Entities.AddStrictArguments(Class, UserVariables, DataVariables)
	if not isstring(Class) then return end

	local Entity    = GetEntityTable(Class)

	local UserVars  = table.GetKeys(UserVariables)
	local DataVars  = table.GetKeys(DataVariables)
	local ArgumentNames  = {}
	local Arguments = {}
	for _, v in ipairs(UserVars) do ArgumentNames[#ArgumentNames + 1] = v; Arguments[v] = UserVars[v] end
	for _, v in ipairs(DataVars) do ArgumentNames[#ArgumentNames + 1] = v; Arguments[v] = UserVars[v] end

	local List      = AddArguments(Entity, ArgumentNames)
	AddArgumentRestrictions(Entity, Arguments)
	return List
end

-- Automatically registers an entity. This MUST be the last line in entity/init.lua for everything to work properly
-- Can be passed with an ENT table if you have some weird usecase, but auto defaults to _G.ENT
--- @param ENT table A scripted entity class definition (see https://wiki.facepunch.com/gmod/Structures/ENT)
function Entities.AutoRegister(ENT)
	if ENT == nil then ENT = _G.ENT end
	if not ENT then error("Called Entities.AutoRegister(), but no entity was in the process of being created.") end

	local Class  = string.Split(ENT.Folder, "/"); Class = Class[#Class]
	ENT.ACF_Class = Class

	local Entity = GetEntityTable(Class)
	local ArgsList = Entities.AddStrictArguments(Class, ENT.ACF_UserVars or {}, ENT.ACF_DataVars or {})

	local DataVars = ENT.ACF_DataVars

	if CLIENT then return end

	if isnumber(ENT.ACF_Limit) then
		CreateConVar(
			"sbox_max_" .. Class,
			ENT.ACF_Limit,
			FCVAR_ARCHIVE + FCVAR_NOTIFY,
			"Maximum amount of " .. (ENT.PluralName or (Class .. " entities")) .. " a player can create."
		)
	end

	-- Verification function
	local function VerifyClientData(ClientData)
		local Entity       = GetEntityTable(Class)
		local List         = Entity.List
		local Restrictions = Entity.Restrictions

		for _, argName in ipairs(List) do
			if Restrictions[argName] then
				local RestrictionSpecs = Restrictions[argName]
				local ArgumentVerification = UserArgumentTypes[RestrictionSpecs.Type] or DataArgumentTypes[RestrictionSpecs.Type]
				if not ArgumentVerification then error("No verification function for type '" .. tostring(RestrictionSpecs.Type or "<NIL>") .. "'") end
				ClientData[argName] = ArgumentVerification.Validator(ClientData[argName], RestrictionSpecs)
			end
		end

		if ENT.ACF_OnVerifyClientData then ENT.ACF_OnVerifyClientData(ClientData) end
	end

	local function UpdateEntityData(self, ClientData)
		local Entity = GetEntityTable(Class)
		local List   = Entity.List

		if self.ACF_PreUpdateEntityData then self:ACF_PreUpdateEntityData(ClientData) end
		self.ACF = self.ACF or {}
		for _, v in ipairs(List) do
			self[v] = ClientData[v]
		end

		if self.ACF_PostUpdateEntityData then self:ACF_PostUpdateEntityData(ClientData) end

		ACF.Activate(self, true)
	end

	function ENT:Update(ClientData)
		VerifyClientData(ClientData)

		hook.Run("ACF_OnEntityLast", Class, self)

		ACF.SaveEntity(self)
		UpdateEntityData(self, ClientData)
		ACF.RestoreEntity(self)

		hook.Run("ACF_OnUpdateEntity", Class, self, ClientData)

		return true, (self.PrintName or Class) .. " updated successfully!"
	end

	local ACF_Limit       = ENT.ACF_Limit
	local PreEntityCopy   = ENT.PreEntityCopy
	local PostEntityPaste = ENT.PostEntityPaste

	function Entity.Spawn(Player, Pos, Angle, ClientData)
		if ACF_Limit then
			if isfunction(ACF_Limit) then
				if not ACF_Limit() then return end
			elseif isnumber(ACF_Limit) then
				if not Player:CheckLimit("_" .. Class) then return false end
			end
		end

		local CanSpawn = hook.Run("ACF_PreSpawnEntity", Class, Player, ClientData)
		if CanSpawn == false then return false end

		local New = ents.Create(Class)
		if not IsValid(New) then return end

		VerifyClientData(ClientData)

		New:SetPos(Pos)
		New:SetAngles(Angle)
		if New.ACF_PreSpawn then
			New:ACF_PreSpawn(Player, Pos, Angle, ClientData)
		end

		New:Spawn()
		Player:AddCount("_" .. Class, New)
		Player:AddCleanup("_" .. Class, New)

		hook.Run("ACF_OnSpawnEntity", Class, New, ClientData)

		if New.ACF_PostSpawn then
			New:ACF_PostSpawn(Player, Pos, Angle, ClientData)
		end

		New:ACF_UpdateEntityData(ClientData)

		ACF.CheckLegal(New)

		return New
	end

	function ENT:PreEntityCopy()
		for k, v in pairs(DataVars) do
			local typedef   = DataArgumentTypes[v.Type]
			local validated = typedef.Validator(self[k], v)
			local ret       = typedef.PreCopy(self, validated)
			if ret then
				duplicator.StoreEntityModifier(self, k, {ret})
			end
		end

		if PreEntityCopy then PreEntityCopy(self) end

		--Wire dupe info
		self.BaseClass.PreEntityCopy(self)
	end

	function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
		local EntMods = Ent.EntityMods

		for k, v in pairs(DataVars) do
			local typedef    = DataArgumentTypes[v.Type]
			local entmodData = EntMods[k][1]
			local ret        = typedef.PostPaste(Ent, entmodData, CreatedEntities)
			ret              = typedef.Validator(ret, v)
			if ret then Ent[k] = ret end
		end

		if PostEntityPaste then PostEntityPaste(Ent, Player, Ent, CreatedEntities) end
		Ent.BaseClass.PostEntityPaste(Ent, Player, Ent, CreatedEntities)
	end

	ENT.ACF_VerifyClientData = VerifyClientData
	ENT.ACF_UpdateEntityData = UpdateEntityData

	local function SpawnFunction(Player, Pos, Angle, Data)
		local _, SpawnedEntity = Entities.Spawn(Class, Player, Pos, Angle, Data, true)

		return SpawnedEntity
	end

	duplicator.RegisterEntityClass(Class, SpawnFunction, "Pos", "Angle", "Data", unpack(ArgsList))
end

--- Registers a class as a spawnable entity class
--- @param Class string The class to register
--- @param Function fun(Player:entity, Pos:vector, Ang:angle, Data:table):Entity A function defining how to spawn your class (This should be your MakeACF_<something> function)
--- @param ... any #A vararg of arguments to attach to the entity
function Entities.Register(Class, Function, ...)
	if Class == nil and Function == nil then
		-- Calling Entities.Register with no arguments performs an automatic registration
		Entities.AutoRegister(ENT)
		return
	end

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

Classes.AddSimpleFunctions(Entities, Entries)

if CLIENT then return end

do -- Spawning and updating
	local undo = undo

	--- Spawns an entity with the given parameters
	--- Internally calls the class' Spawn method
	--- @param Class string The class of entity to spawn
	--- @param Player entity The player creating the entity
	--- @param Position vector The position to create the entity at
	--- @param Angles angle The angles to create the entity at
	--- @param Data table The data to pass into the entity's spawn function
	--- @param NoUndo boolean Whether the entity is added to the undo list (can be z keyed)
	--- @return boolean, table? # Whether the spawning was successful and the reason why
	function Entities.Spawn(Class, Player, Position, Angles, Data, NoUndo)
		if not isstring(Class) then return false end

		local ClassData = Entities.Get(Class)

		if not ClassData then return false, Class .. " is not a registered ACF entity class." end
		if not ClassData.Spawn then return false, Class .. " doesn't have a spawn function assigned to it." end

		local Entity = ClassData.Spawn(Player, Position, Angles, Data)

		if not IsValid(Entity) then return false, "The spawn function for " .. Class .. " didn't return an entity." end

		Entity:CPPISetOwner(Player)
		Entity:SetPlayer(Player)

		Entity.ACF       = Entity.ACF or {}
		Entity.Owner     = Player -- MUST be stored on ent for PP (supposedly)
		Entity.DataStore = Entities.GetArguments(Class)

		if not NoUndo then
			undo.Create(Entity.Name or Class)
				undo.AddEntity(Entity)
				undo.SetPlayer(Player)
			undo.Finish()
		end

		if Entity.UpdateOverlay then
			Entity:UpdateOverlay(true)
		end

		if Entity.Outputs and Entity.Outputs.Entity then
			WireLib.TriggerOutput(Entity, "Entity", Entity)
		end

		return true, Entity
	end

	--- Triggers the update function of an entity  
	--- Internally calls the ENT:Update(Data) metamethod that's implemented on all entities
	--- @param Entity table The entity to update
	--- @param Data table The data to pass into the entity on update
	--- @return boolean, string # Whether the update was successful and the reason why
	function Entities.Update(Entity, Data)
		if not IsValid(Entity) then return false, "Can't update invalid entities." end
		if not isfunction(Entity.Update) then return false, "This entity does not support updating." end

		Data = istable(Data) and Data or {}

		local Result, Message = Entity:Update(Data)

		if Result then
			if Entity.UpdateOverlay then
				Entity:UpdateOverlay(true)
			end

			-- Let the client know that we've updated this entity
			net.Start("ACF_UpdateEntity")
				net.WriteEntity(Entity)
			net.Broadcast()
		else
			Message = "Couldn't update entity: " .. (Message or "No reason provided.")
		end

		return Result, Message
	end
end
