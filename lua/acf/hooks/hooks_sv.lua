local Hooks = ACF.Utilities.Hooks


Hooks.Add("ACF_Base_Server", function(Gamemode)
	--- Called when the player has properly loaded onto the server.
	-- It's possible to use network messages in this hook, unlike PlayerInitialSpawn.
	-- @param Player The player entity that just finished loading.
	function Gamemode:ACF_OnLoadPlayer()
	end

	--- Called when the bullet will attempt to use the default flight behavior
	-- All the values on the bullet are still updated towards the next position, even if this hook returns false.
	-- To prevent this, set Bullet.HandlesOwnIteration to true.
	-- @param Bullet The bullet object that will attempt to fly in the current tick
	-- @return False if the bullet shouldn't run the default flight behavior in the currect tick.
	function Gamemode:ACF_PreBulletFlight()
		return true
	end

	--- Called after the default legality checks have failed to mark the entity as illegal.
	-- It is advised to not return true to prevent conflict between everything that uses this function.
	-- @param Entity The entity that is currectly being checked for legality.
	-- @return True if the entity is legal, false otherwise.
	-- @return The reason why the entity is illegal. Not required if legal.
	-- @return A short explanation on why the entity is illegal. Not required if legal.
	-- @return Optionally, the amount of time in seconds the entity will remain illegal for. Not required if legal.
	function Gamemode:ACF_OnCheckLegal()
		return true
	end

	--- Called before an ACF entity is attempted to be spawned.
	-- This will only be called if the class has been registered and has a spawn function assigned to it.
	-- @param Class The entity class that is trying to be spawned.
	-- @param Player The player attempting to spawn the entity.
	-- @param Position The position where the entity is attempting to be spawned.
	-- @param Angles The angles at which the entity is attempting to be spawned.
	-- @param Data A table with all the information required for the entity to set itself up.
	-- @return True if the entity can be spawned, false otherwise.
	-- @return A short explanation on why the entity can't be spawned. Not required if the entity is spawned.
	function Gamemode:ACF_CanCreateEntity()
		return true
	end

	--- Called before an ACF entity is attempted to be spawned.
	-- This will only be called if the entity is valid and has an ENT:Update method assigned to it.
	-- @param Entity The entity that is trying to be updated.
	-- @param Data A table with all the information required for the entity to set itself up.
	-- @return True if the entity can be updated, false otherwise.
	-- @return A short explanation on why the entity can't be updated. Not required if the entity is updated.
	function Gamemode:ACF_CanUpdateEntity()
		return true
	end

	--- Called when an ACF entity creates or updates its Wire inputs.
	-- It's recommended to just push entries into the List parameter.
	-- @param Entity The entity to create or update Wire inputs on.
	-- @param List A numerically indexed list of inputs.
	-- @param Data A key-value table with entity information, either ToolData or dupe data.
	-- @param ... A list of entries that could further add inputs without having to use the hook, usually definition groups or items.
	function Gamemode:ACF_OnSetupInputs()
	end

	--- Called when an ACF entity creates or updates its Wire inputs
	-- It's recommended to just push entries into the List parameter.
	-- @param Entity The entity to create or update Wire outputs on.
	-- @param List A numerically indexed list of outputs.
	-- @param Data A key-value table with entity information, either ToolData or dupe data.
	-- @param ... A list of entries that could further add outputs without having to use the hook, usually definition groups or items.
	function Gamemode:ACF_OnSetupOutputs()
	end

	--- Called when an entity is attempted to be pushed by ACF.KEShove
	-- This won't be called if the entity is not valid.
	-- @param Entity The entity that's trying to be pushed.
	-- @param Position The world position at which the entity is attempted to be pushed.
	-- @param Direction The direction in which the entity is attempting to be pushed.
	-- @param Energy The kinetic energy that's attempting to be applied to the entity.
	-- @return True if the entity should be pushed by kinetic energy, false otherwise.
	function Gamemode:ACF_OnPushEntity()
		return true
	end

	--- Called before a given entity receives ACF damage.
	-- @param Entity The entity to be damaged.
	-- @param DmgResult A DamageResult object.
	-- @param DmgInfo A DamageInfo object.
	-- @return True if the given entity can be damaged, false otherwise.
	function Gamemode:ACF_PreDamageEntity()
		return true
	end

	--- Called when a given entity is about to receive ACF damage.
	-- @param Entity The entity to be damaged.
	-- @param DmgResult A DamageResult object.
	-- @param DmgInfo A DamageInfo object.
	function Gamemode:ACF_OnDamageEntity()
	end

	--- Called after a given entity receives ACF damage.
	-- @param Entity The entity to be damaged.
	-- @param DmgResult A DamageResult object.
	-- @param DmgInfo A DamageInfo object.
	function Gamemode:ACF_PostDamageEntity()
	end

	--- Called whenever the data table needs to be verified prior attempting to spawn an entity.
	-- @param Class The entity class that's being verified.
	-- @param Data The table of entity information that's being verified.
	-- @param ... One or many tables or objects that are related to the entity, these will vary on every class.
	function Gamemode:ACF_VerifyData()
	end

	--- Called before an entity is attempted to the spawned.
	-- This will happen after the Data table is verified.
	-- @param Class The class of the entity that's about to be spawned.
	-- @param Player The player attempting to spawn the entity.
	-- @param Data The table of entity information that will be used on the entity.
	-- @param ... One or many tables or objects that are related to the entity, these will vary on every class.
	-- @return True if the entity can be spawned, false otherwise.
	function Gamemode:ACF_PreEntitySpawn()
		return true
	end

	--- Called after the entity is successfully spawned and almost fully initialized.
	-- @param Class The class of the entity that was spawned.
	-- @param Entity The entity that was spawned.
	-- @param Data The table of entity information that was used on the entity.
	-- @param ... One or many tables or objects that are related to the entity, these will vary on every class.
	function Gamemode:ACF_OnEntitySpawn()
	end

	--- Called before an entity is attempted to be updated.
	-- This will happen after the Data table is verified.
	-- @param Class The class of the entity that's about to be updated.
	-- @param Entity The entity that's about to be updated.
	-- @param Data The table of entity information that will be used on the entity.
	-- @param ... One or many tables or objects that are related to the entity, these will vary on every class.
	-- @return True if the entity can be updated, false otherwise.
	-- @return The reason why the entity couldn't be updated. Not required if the entity can be updated.
	function Gamemode:ACF_PreEntityUpdate()
		return true
	end

	--- Called after an entity is successfully updated.
	-- @param Class The class of the entity that was updated.
	-- @param Entity The entity that was updated.
	-- @param Data The table of entity information that was used on the entity.
	-- @param ... One or many tables or objects that are related to the entity, these will vary on every class.
	function Gamemode:ACF_OnEntityUpdate()
	end

	--- Called when an entity is about to be updated or removed.
	-- @param Class The class of the entity that's about to be updated or removed.
	-- @param Entity The entity that's about to be updated or removed.
	-- @param ... One or many tables or objects that are related to the entity, these will vary on every class.
	function Gamemode:ACF_OnEntityLast()
	end

	--- Called when an entity is set to store or use ammo type information.
	-- @param AmmoType The ammo type class that's about to be used.
	-- @param Entity The entity that will be using the ammo type.
	-- @param Data The table of entity information that was used on the entity.
	-- @param ... One or many tables or objects that are related to the entity, these will vary on every class.
	function Gamemode:ACF_OnAmmoFirst()
	end

	--- Called when an ammo type object is about to be replaced by another one or just removed.
	-- @param AmmoType The ammo type object that will be replaced or removed.
	-- @param Entity The entity containing the ammo type object.
	function Gamemode:ACF_OnAmmoLast()
	end

	--- Called when an ammo crate attempts to replenish another one.
	-- @param Refill The ammo crate that will be providing ammunition.
	-- @param Crate The ammo crate that will get replenished.
	-- @param Amount The quantity of ammunition that will get replenished.
	-- @return True if the crate can be replenished by the refill with the given amount, false otherwise.
	function Gamemode:ACF_AmmoCanRefill()
		return true
	end

	--- Called any time an ammo crate gets damaged and is about to start burning it's ammunition.
	-- @param Entity The affected ammo crate.
	-- @return True if the ammo crate can start burning, false otherwise.
	function Gamemode:ACF_AmmoCanBurn()
		return true
	end

	--- Called when an ammo crate attempts to create an explosion, usually due to damage.
	-- @param Entity The affected ammo crate.
	-- @return True if the ammo crate can explode, false otherwise.
	function Gamemode:ACF_AmmoCanExplode()
		return true
	end

	--- Called when a fuel tank attempts to replenish another one.
	-- @param Refill The tank that will be providing fuel.
	-- @param FuelTank The tank that will be replenished.
	-- @param Amount The quantity of fuel that will get replenished.
	-- @return True if the FuelTank can be replenished by the Refill with the given amount, false otherwise.
	function Gamemode:ACF_FuelCanRefill()
		return true
	end

	--- Called when a fuel tank attempts to create an explosion, usually due to damage.
	-- @param Entity The affected fuel tank.
	-- @return True if the fuel tank can explode, false otherwise.
	function Gamemode:ACF_FuelCanExplode()
		return true
	end

	--- Called when a weapon attempts to fire a projectile.
	-- @param Entity The weapon attempting to fire.
	-- @return True if the weapon can be fired, false otherwise.
	function Gamemode:ACF_WeaponCanFire()
		return true
	end

	--- Called when a player switches between safezones.
	-- @param Player The affected player.
	-- @param Zone? The zone which the player moved into, could be nil.
	-- @param OldZone? The zone which the player moved from, could be nil.
	function Gamemode:ACF_PlayerChangedZone()
	end

	--- Called when the active protection mode is changed on the server.
	-- @param Mode The currently active protection mode.
	-- @param OldMode? The protection mode that was being used before, will be nil on startup.
	function Gamemode:ACF_ProtectionModeChanged()
	end
end)
