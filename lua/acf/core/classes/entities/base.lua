
if CLIENT then return end

local Classes    = ACF.Classes
local Entities   = Classes.Entities

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

		local Entity = hook.Run("ACF_TemporaryHook_InstantiateEntity", Class, Player, Position, Angles, Data)
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

		ACF.CheckLegal(Entity)

		return true, Entity
	end

	--- Triggers the update function of an entity  
	--- Internally calls the ENT:Update(Data) metamethod that's implemented on all entities
	--- @param Entity table The entity to update
	--- @param Data table The data to pass into the entity on update
	--- @return boolean, string # Whether the update was successful and the reason why
	function Entities.Update(Entity, Data)
		if not IsValid(Entity) then return false, "Can't update invalid entities." end
		local UpdateFn = Entity.Update or Entity.ACF_UpdateEntityData
		if not isfunction(UpdateFn) then return false, "This entity does not support updating." end

		Data = istable(Data) and Data or {}
		local Result, Message = UpdateFn(Entity, Data)

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
