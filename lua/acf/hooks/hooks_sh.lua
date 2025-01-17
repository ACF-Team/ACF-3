-- NOTE: Make sure that all hooks obey the naming convention "ACF_[Pre/On/Post][ACTION][ACTOR]"!
local Hooks = ACF.Utilities.Hooks

Hooks.Add("ACF_Base_Shared", function(Gamemode)
	--- Called when ACF is loaded and every time it's reloaded with the acf_reload console command.
	--- @param Root table The global ACF table.
	function Gamemode:ACF_OnLoadAddon()
	end

	--- Called when a class group object is created, not necessarily for the first time.
	--- @param ID string The ID of the group that was registered.
	--- @param Group table The group object that was registered.
	function Gamemode:ACF_OnCreateGroup()
	end

	--- Called when a grouped item object is created, not necessarily for the first time.  
	--- Important to not the GroupID has to reference an actually existing class group object.
	--- @param ID string The ID of the group item that was registered.
	--- @param Group table The group where the item was registered.
	--- @param Item table The item object that was registered.
	function Gamemode:ACF_OnCreateGroupItem()
	end

	--- Called when a standalone item object is created, not necessarily for the first time.
	--- @param ID string The ID of the standalone item that was registered.
	--- @param Item table The item object that was registered.
	function Gamemode:ACF_OnCreateItem()
	end

	--- Called when a class object is fully created and loaded.  
	--- This will not be instant on startup since the object has to wait for the base objects to load.
	--- @param ID string The ID of the object class that has been loaded.
	--- @param Class table The object class that has been loaded.
	function Gamemode:ACF_OnLoadClass()
	end

	--- Called when a server data variable value gets updated.
	--- @param Player entity The player that triggered the server data variable change.  
	--- On the clientside, if the change was done by the client then this will always be the local player.  
	--- On the serverside, if the change was done by the server then this will always be nil.
	--- @param Key string The name of the affected server data variable.
	--- @param Value any The new value assigned to the server data variable.
	function Gamemode:ACF_OnUpdateServerData()
	end

	--- Called when a client data variable value gets updated.  
	--- On the clientside, this will be called every time the client messes with the data var.  
	--- This means that this hook can be called multiple times on the same tick for the same data variable.  
	--- On the serverside, this will be called once per tick when the value gets networked.
	--- @param Player entity The player that triggered the client data variable change.
	--- @param Key string The name of the affected client data variable.
	--- @param Value any The new value assigned to the client data variable.
	function Gamemode:ACF_OnUpdateClientData()
	end

	--- Called after the Think hook is called.  
	--- The only difference with the Think hook are the convenience arguments provided by this one.
	--- @param CurTime number Returns the uptime of the server.
	--- @param DeltaTime number Returns the delay between this hook's call and the previous.  
	--- This value will usually be similar if not the same as the server tickrate.
	function Gamemode:ACF_OnTick()
	end

	--- Called when an ammo type has to provide its display information.  
	--- The information is only used by the spawn menu and hint bubble on entities.
	--- @param AmmoType table The ammo type object requesting its display information.
	--- @param Bullet table The bullet object being used to get display information.
	--- @param GUIData table The display information table itself.
	function Gamemode:ACF_OnRequestDisplayData()
	end

	--- Called when a bullet object is created or updated.
	--- @param AmmoType table The ammo type object used by the bullet.
	--- @param Data table The table of entity information that was used on the bullet.
	--- @param Bullet table The bullet object itself.
	--- @param GUIData table The table of information that's only required for the clientside, such as the menu.  
	--- On the serverside, this will be the same as the Bullet object.
	function Gamemode:ACF_OnUpdateRound()
	end

	--- Called every time a scalable entity is resized.
	--- @param Entity entity The entity that got resized.
	--- @param PhysObj physobj The physics object from the entity that got resized.
	--- @param Size vector The new size of the entity.
	--- @param Scale vector The new scale of the entity.  
	--- This is based off the size of the model the entity it's using and the scale that was given.
	function Gamemode:ACF_OnResizeEntity()
	end

	--- Called when a player attempts to use the scanner.
	--- @param Player entity The player attempting to use the scanner.
	--- @return boolean # False to prevent the player from scanning, otherwise true.
	--- @return string # A short reason why the player is not allowed to scan. Not required if the player will be allowed to scan.
	function Gamemode:ACF_PreBeginScanning()
		return true
	end

	--- Called just before something attempts to create an effect through ACF.  
	--- You can either modify the fields of the EffectTable or return an entirely new one.
	--- @param EffectName string The name of the effect to be created.
	--- @param EffectTable table A table containing all of the attributes of the effect.
	--- @return string? # A new name for the effect to be created with.
	--- @return table? # A new table of effect attributes for the effect to be created with.
	function Gamemode:ACF_PreCreateEffect()
	end

	--- Called after all persisted data variables have been loaded.
	function Gamemode:ACF_OnLoadPersistedData()
	end
end)
