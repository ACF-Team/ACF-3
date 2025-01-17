-- NOTE: Make sure that all hooks obey the naming convention "ACF_[Pre/On/Post][ACTION][ACTOR]"!
local Hooks = ACF.Utilities.Hooks

Hooks.Add("ACF_Base_Server", function(Gamemode)
	--- Called when the player has properly loaded onto the server.  
	--- It's possible to use network messages in this hook, unlike PlayerInitialSpawn.
	--- @param Player entity The player entity that just finished loading.
	function Gamemode:ACF_OnLoadPlayer()
	end

	--- Called when the bullet will attempt to use the default flight behavior.  
	--- All the values on the bullet are still updated towards the next position, even if this hook returns false.  
	--- To prevent this, set Bullet.HandlesOwnIteration to true.
	--- @param Bullet table The bullet object that will attempt to fly in the current tick.
	--- @return boolean # False if the bullet shouldn't run the default flight behavior in the currect tick.
	function Gamemode:ACF_PreBulletFlight()
		return true
	end

	--- Called when attempting to determine if a bullet should ignore a particular entity.
	--- @param Entity entity The entity hit by the bullet.
	--- @param Bullet table The bullet being tested.
	--- @return boolean # Return false if the bullet should filter out the entity.
	function Gamemode:ACF_OnFilterBullet()
		return true
	end

	--- Called after the default legality checks have failed to mark the entity as illegal.  
	--- It is advised to not return true to prevent conflict between everything that uses this function.
	--- @param Entity entity The entity that is currectly being checked for legality.
	--- @return boolean # True if the entity is legal, false otherwise.
	--- @return string # The reason why the entity is illegal. Not required if legal.
	--- @return string # A short explanation on why the entity is illegal. Not required if legal.
	--- @return number # Optionally, the amount of time in seconds the entity will remain illegal for. Not required if legal.
	function Gamemode:ACF_OnCheckLegal()
		return true
	end

	--- Called when an ACF entity creates or updates its Wire inputs.  
	--- It's recommended to just push entries into the List parameter.
	--- @param Entity entity The entity to create or update Wire inputs on.
	--- @param List table A numerically indexed list of inputs.
	--- @param Data table A key-value table with entity information, either ToolData or dupe data.
	--- @param ... any A list of entries that could further add inputs without having to use the hook, usually definition groups or items.
	function Gamemode:ACF_OnSetupInputs()
	end

	--- Called when an ACF entity creates or updates its Wire outputs.  
	--- It's recommended to just push entries into the List parameter.
	--- @param Entity entity The entity to create or update Wire outputs on.
	--- @param List table A numerically indexed list of outputs.
	--- @param Data table A key-value table with entity information, either ToolData or dupe data.
	--- @param ... any A list of entries that could further add outputs without having to use the hook, usually definition groups or items.
	function Gamemode:ACF_OnSetupOutputs()
	end

	--- Called when an entity is attempted to be pushed by ACF.KEShove.  
	--- This won't be called if the entity is not valid.
	--- @param Entity entity The entity that's trying to be pushed.
	--- @param Position vector The world position at which the entity is attempted to be pushed.
	--- @param Direction vector The direction in which the entity is attempting to be pushed.
	--- @param Energy number The kinetic energy that's attempting to be applied to the entity.
	--- @return boolean # True if the entity should be pushed by kinetic energy, false otherwise.
	function Gamemode:ACF_OnPushEntity()
		return true
	end

	--- Called before a given entity receives ACF damage.
	--- @param Entity entity The entity to be damaged.
	--- @param DmgResult DamageResult A DamageResult object.
	--- @param DmgInfo DamageInfo A DamageInfo object.
	--- @return boolean # True if the given entity can be damaged, false otherwise.
	function Gamemode:ACF_PreDamageEntity()
		return true
	end

	--- Called when a given entity is about to receive ACF damage.
	--- @param Entity entity The entity to be damaged.
	--- @param DmgResult DamageResult A DamageResult object.
	--- @param DmgInfo DamageInfo A DamageInfo object.
	function Gamemode:ACF_OnDamageEntity()
	end

	--- Called after a given entity receives ACF damage.
	--- @param Entity entity The entity to be damaged.
	--- @param DmgResult DamageResult A DamageResult object.
	--- @param DmgInfo DamageInfo A DamageInfo object.
	function Gamemode:ACF_PostDamageEntity()
	end

	--- Called whenever the data table needs to be verified prior attempting to spawn an entity.
	--- @param Class string The entity class that's being verified.
	--- @param Data table The table of entity information that's being verified.
	--- @param ... any One or many tables or objects that are related to the entity, these will vary on every class.
	function Gamemode:ACF_OnVerifyData()
	end

	--- Called before an entity is attempted to be spawned.  
	--- This will happen after the Data table is verified.
	--- @param Class string The class of the entity that's about to be spawned.
	--- @param Player entity The player attempting to spawn the entity.
	--- @param Data table The table of entity information that will be used on the entity.
	--- @param ... any One or many tables or objects that are related to the entity, these will vary on every class.
	--- @return boolean # True if the entity can be spawned, false otherwise.
	function Gamemode:ACF_PreSpawnEntity()
		return true
	end

	--- Called after the entity is successfully spawned and almost fully initialized.
	--- @param Class string The class of the entity that was spawned.
	--- @param Entity entity The entity that was spawned.
	--- @param Data table The table of entity information that was used on the entity.
	--- @param ... any One or many tables or objects that are related to the entity, these will vary on every class.
	function Gamemode:ACF_OnSpawnEntity()
	end

	--- Called before an entity is attempted to be updated.  
	--- This will happen after the Data table is verified.
	--- @param Class string The class of the entity that's about to be updated.
	--- @param Entity entity The entity that's about to be updated.
	--- @param Data table The table of entity information that will be used on the entity.
	--- @param ... any One or many tables or objects that are related to the entity, these will vary on every class.
	--- @return boolean # True if the entity can be updated, false otherwise.
	--- @return string # The reason why the entity couldn't be updated. Not required if the entity can be updated.
	function Gamemode:ACF_PreUpdateEntity()
		return true
	end

	--- Called after an entity is successfully updated.
	--- @param Class string The class of the entity that was updated.
	--- @param Entity entity The entity that was updated.
	--- @param Data table The table of entity information that was used on the entity.
	--- @param ... any One or many tables or objects that are related to the entity, these will vary on every class.
	function Gamemode:ACF_OnUpdateEntity()
	end

	--- Called when an entity is about to be updated or removed.
	--- @param Class string The class of the entity that's about to be updated or removed.
	--- @param Entity entity The entity that's about to be updated or removed.
	--- @param ... any One or many tables or objects that are related to the entity, these will vary on every class.
	function Gamemode:ACF_OnEntityLast()
	end

	--- Called when an entity is set to store or use ammo type information.
	--- @param AmmoType table The ammo type class that's about to be used.
	--- @param Entity entity The entity that will be using the ammo type.
	--- @param Data table The table of entity information that was used on the entity.
	--- @param ... any One or many tables or objects that are related to the entity, these will vary on every class.
	function Gamemode:ACF_OnAmmoFirst()
	end

	--- Called when an ammo type object is about to be replaced by another one or just removed.
	--- @param AmmoType table The ammo type object that will be replaced or removed.
	--- @param Entity entity The entity containing the ammo type object.
	function Gamemode:ACF_OnAmmoLast()
	end

	--- Called when an ammo crate attempts to replenish another one.
	--- @param Refill entity The ammo crate that will be providing ammunition.
	--- @param Crate entity The ammo crate that will get replenished.
	--- @param Amount number The quantity of ammunition that will get replenished.
	--- @return boolean # True if the crate can be replenished by the refill with the given amount, false otherwise.
	function Gamemode:ACF_PreRefillAmmo()
		return true
	end

	--- Called any time an ammo crate gets damaged and is about to start burning its ammunition.
	--- @param Entity entity The affected ammo crate.
	--- @return boolean # True if the ammo crate can start burning, false otherwise.
	function Gamemode:ACF_PreBurnAmmo()
		return true
	end

	--- Called when an ammo crate attempts to create an explosion, usually due to damage.
	--- @param Entity entity The affected ammo crate.
	--- @return boolean # True if the ammo crate can explode, false otherwise.
	function Gamemode:ACF_PreExplodeAmmo()
		return true
	end

	--- Called when a fuel tank attempts to replenish another one.
	--- @param Refill entity The tank that will be providing fuel.
	--- @param FuelTank entity The tank that will be replenished.
	--- @param Amount number The quantity of fuel that will get replenished.
	--- @return boolean # True if the FuelTank can be replenished by the Refill with the given amount, false otherwise.
	function Gamemode:ACF_PreRefillFuel()
		return true
	end

	--- Called when a fuel tank attempts to create an explosion, usually due to damage.
	--- @param Entity entity The affected fuel tank.
	--- @return boolean # True if the fuel tank can explode, false otherwise.
	function Gamemode:ACF_PreExplodeFuel()
		return true
	end

	--- Called when a weapon attempts to fire a projectile.
	--- @param Entity entity The weapon attempting to fire.
	--- @return boolean # True if the weapon can be fired, false otherwise.
	function Gamemode:ACF_PreFireWeapon()
		return true
	end

	--- Called when a player switches between safezones.
	--- @param Player entity The affected player.
	--- @param Zone? string | nil The zone which the player moved into, could be nil.
	--- @param OldZone? string | nil The zone which the player moved from, could be nil.
	function Gamemode:ACF_OnPlayerChangeZone()
	end

	--- Called when the active protection mode is changed on the server.
	--- @param Mode string The currently active protection mode.
	--- @param OldMode? string | nil The protection mode that was being used before, will be nil on startup.
	function Gamemode:ACF_OnChangeProtectionMode()
	end
end)
