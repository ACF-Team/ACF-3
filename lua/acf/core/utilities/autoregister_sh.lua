-- TODO: Localize globals for optimization? e.g. cache data var tables for this specific class, instead of looking them up through the ACF global variable

--[[
Call Order:
	ACF.SpawnEntity: Entry point for spawning an entity <- (Duplicator / Tool gun spawn)
	EntTable.Spawn: Internal Class specific spawn function. Don't use this.
	ACF_PreSpawn: Called before the entity is spawned.
	ACF.UpdateEntityData: Entry point for updating an entity's data variables. <- (Tool gun update)
	Entity.Update: Internal function that actually updates the entity's data variables. Don't use this.
	ACF_PostUpdateEntityData: Called after the entity's data variables have been updated.
	ACF_PostSpawn: Called after the entity is spawned and updated with the initial data variables.
	OnDuplicated: Called on any entity after it has been created by the duplicator and before any bone/entity modifiers have been applied. <- (Duplicator only)
	PostEntityPaste: Called after the duplicator pastes the entity, after the bone/entity modifiers have been applied to the entity. <- (Duplicator only)
	ACF_PostMenuSpawn: Called after all the above, if created with the toolgun <- (Tool gun only)
	---

Notable variables:
	ACF_LiveData: The current live data of the entity, updated whenever the entity is spawned or updated. Initialized by the toolgun on spawn, or by the duplicator when pasting.
		Certain datavar types like linked entities will have unsafe/garbage data until PostEntityPaste is called. Do not use them before then.	
	ACF_UserData: A copy of the live data at the time of duplication. PostEntityPaste updates it immediately before copying. It's really just for flushing data, don't use it.
]]--

ACF.EntityTables = ACF.EntityTables or {}

local empty_table = {}

-- Public entry point
function ACF.SpawnEntity(Class, Player, Pos, Angle, DataVarKVs, FromDupe, NoUndo)
	local EntityTable = ACF.EntityTables[Class]
	if not EntityTable then return false, Class .. " is not a registered ACF entity class." end
	if not EntityTable.Spawn then return false, Class .. " does not have a spawn function." end

	local Entity = EntityTable.Spawn(Player, Pos, Angle, DataVarKVs, FromDupe)

	if not IsValid(Entity) then return false, "The spawn function for " .. Class .. " failed to return a valid entity." end

	Entity:CPPISetOwner(Player)
	Entity:SetPlayer(Player)

	Entity.Owner = Player

	if not NoUndo then
		undo.Create(Entity.Name or Class)
		undo.AddEntity(Entity)
		undo.SetPlayer(Player)
		undo.Finish()
	end

	if Entity.UpdateOverlay then Entity:UpdateOverlay(true) end

	return true, Entity
end

-- Public entry point
function ACF.UpdateEntityData(Entity, DataVarKVs)
	if not IsValid(Entity) then return false, "Can't update invalid entities." end
	if not isfunction(Entity.Update) then return false, "This entity does not support updating." end

	local Result, Message = Entity:Update(DataVarKVs)

	if Result then
		if Entity.UpdateOverlay then Entity:UpdateOverlay(true) end
	else
		Message = "Couldn't update entity: " .. (Message or "No reason provided.")
	end

	return Result, Message
end

--- Sets an entity's class by inferring it from the folder it was called from
function ACF.SetupENT(ENT)
	local Class = string.Split(ENT.Folder, "/"); Class = Class[#Class]
	ENT.ACF_Class = Class
end

--- Detours an entity's method, allowing you to run code after the original method
--- This lets autoregister work on top of existing definitions
local function HijackBefore(MethodName, DetourFunc)
	local Old = ENT[MethodName]
	local Base = ENT.BaseClass and ENT.BaseClass[MethodName]

	ENT[MethodName] = function(self, ...)
		DetourFunc(self, ...)
		if Old then Old(self, ...) end
		if Base then Base(self, ...) end
	end
end

function ACF.AutoRegister(ENT)
	if CLIENT then return end -- TODO: Maybe this is wrong?

	local Class = ENT.ACF_Class

	function ENT:Update(DataVarKVs)
		ACF.SaveEntity(self)

		-- Update the live data with the new values
		for DataVarName, Value in pairs(DataVarKVs) do
			local DataVar = ACF.DataVarsByScopeAndName[Class] and ACF.DataVarsByScopeAndName[Class][DataVarName]
			if DataVar and not DataVar.Type.PostPaste then
				-- Data vars with postpaste should only be sanitized after pasting.
				local Sanitized = DataVar.Type.Sanitize and DataVar.Type.Sanitize(Value) or Value
				self.ACF_LiveData[DataVarName] = Sanitized
			end
		end

		if self.ACF_PostUpdateEntityData then self:ACF_PostUpdateEntityData() end
		ACF.RestoreEntity(self)
	end

	HijackBefore("OnRemove", function(self)
		WireLib.Remove(self)
	end)

	HijackBefore("PreEntityCopy", function(self)
		self.ACF_UserData = table.Copy(self.ACF_LiveData)
		for _, DataVarName in ipairs(ACF.DataVarScopesOrdered[Class] or empty_table) do
			local DataVar = ACF.DataVarsByScopeAndName[Class] and ACF.DataVarsByScopeAndName[Class][DataVarName]
			if DataVar and DataVar.Type.PreCopy then
				local ToDupe = DataVar.Type.PreCopy(self, DataVar, self.ACF_UserData[DataVarName])
				self.ACF_UserData[DataVarName] = ToDupe
			end
		end
	end)

	-- TODO: Need to update overlay etc. after this?
	HijackBefore("PostEntityPaste", function(self, _, _, CreatedEntities)
		for _, DataVarName in ipairs(ACF.DataVarScopesOrdered[Class] or empty_table) do
			local DataVar = ACF.DataVarsByScopeAndName[Class] and ACF.DataVarsByScopeAndName[Class][DataVarName]
			if DataVar and DataVar.Type.PostPaste then
				-- Sanitize the data var after pasting, using the created entities if needed.
				local FromDupe = DataVar.Type.PostPaste(self, DataVar, self.ACF_LiveData[DataVarName], CreatedEntities)
				local Sanitized = DataVar.Type.Sanitize and DataVar.Type.Sanitize(FromDupe) or FromDupe
				self.ACF_LiveData[DataVarName] = Sanitized
			end
		end
	end)

	local EntTable = ACF.EntityTables[Class] or {}
	ACF.EntityTables[Class] = EntTable

	-- Entity specific spawn function
	function EntTable.Spawn(Player, Pos, Angle, DataVarKVs, FromDupe)
		-- if ENT.ACF_Limit and not Player:CheckLimit(ENT.ACF_Limit) then return false, "You have reached the limit for this entity." end

		local New = ents.Create(Class)
		if not IsValid(New) then return end

		New:SetPos(Pos)
		New:SetAngles(Angle)
		if New.ACF_PreSpawn then
			New:ACF_PreSpawn(Player, Pos, Angle, DataVarKVs, FromDupe)
		end

		New:Spawn()
		Player:AddCount("_" .. Class, New)
		Player:AddCleanup(Class, New)

		New.ACF_LiveData = {}

		ACF.UpdateEntityData(New, DataVarKVs)
		if New.ACF_PostSpawn then
			New:ACF_PostSpawn(Player, Pos, Angle, DataVarKVs, FromDupe)
		end

		return New
	end

	-- Duplicator entry point
	local function SpawnFunction(Player, Pos, Angle, DataVarKVs)
		-- Collect the extra arguments passed in by duplicator into a KV format
		local _, Entity = ACF.SpawnEntity(Class, Player, Pos, Angle, DataVarKVs, true)
		return Entity
	end

	duplicator.RegisterEntityClass(Class, SpawnFunction, "Pos", "Angle", "ACF_UserData")
end