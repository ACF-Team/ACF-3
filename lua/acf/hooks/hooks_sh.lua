local Hooks = ACF.Utilities.Hooks


Hooks.Add("ACF_Base_Shared", function(Gamemode)
	--- Called when ACF is loaded and every time it's reloaded with the acf_reload console command.
	-- @param Root The global ACF table.
	function Gamemode:ACF_OnLoadAddon()
	end

	--- Called when a class group object is created, not necessarily for the first time.
	-- @param ID The ID of the group that was registered.
	-- @param Group The group object that was registered.
	function Gamemode:ACF_OnNewGroup()
	end

	--- Called when a grouped item object is created, not necessarily for the first time.
	-- Important to not the GroupID has to reference an actually existing class group object.
	-- @param ID The ID of the group item that was registered.
	-- @param GroupID The ID of the group where the item was registered.
	-- @param Item The item object that was registered.
	function Gamemode:ACF_OnNewGroupItem()
	end

	--- Called when a standalone item object is created, not necessarily for the first time.
	-- @param ID The ID of the standalone item that was registered.
	-- @param Group The item object that was registered.
	function Gamemode:ACF_OnNewItem()
	end

	--- Called when a class object is fully created and loaded.
	-- This will not be instant on startup since the object has to wait for the base objects to load.
	-- @param ID The ID of the object class that has been loaded.
	-- @param Class The object class that has been loaded.
	function Gamemode:ACF_OnClassLoaded()
	end

	--- Called when a server data variable value gets updated.
	-- @param Player The player that triggered the server data variable change.
	-- On the clientside, if the change was done by the client then this will always be the local player.
	-- On the serverside, if the change was done by the server then this will always be nil.
	-- @param Key The name of the affected server data variable.
	-- @param Value The new value assigned to the server data variable.
	function Gamemode:ACF_OnServerDataUpdate()
	end

	--- Called when a client data variable value gets updated.
	-- On the clientside, this will be called every time the client messes with the data var.
	-- This means that this hook can be called multiple times on the same tick for the same data variable.
	-- On the serverside, this will be called once per tick when the value gets networked.
	-- @param Player The player that triggered the client data variable change.
	-- @param Key The name of the affected client data variable.
	-- @param Value The new value assigned to the client data variable.
	function Gamemode:ACF_OnClientDataUpdate()
	end

	--- Called after the Think hook is called.
	-- The only difference with the Think hook are the convenience arguments provided by this one.
	-- @param CurTime Returns the uptime of the server.
	-- @param DeltaTime Returns the delay between this hook's call and the previous.
	-- This value will usually be similar if not the same as the server tickrate.
	function Gamemode:ACF_OnClock()
	end

	--- Called when an ammo type has to provide its display information.
	-- The information is only used by the spawn menu and hint bubble on entities.
	-- @param AmmoType The ammo type object requesting its display information.
	-- @param Bullet The bullet object being used to get display information.
	-- @param GUIData The display information table itself.
	function Gamemode:ACF_GetDisplayData()
	end

	--- Called when a bullet object is created or updated.
	-- @param AmmoType The ammo type object used by the bullet.
	-- @param Data The table of entity information that was used on the bullet.
	-- @param Bullet The bullet object itself.
	-- @param GUIData The table of information that's only required for the clientside, such as the menu.
	-- On the serverside, this will be the same as the Bullet object.
	function Gamemode:ACF_UpdateRoundData()
	end

	--- Called every time a scalable entity is resized.
	-- @param Entity The entity that got resized.
	-- @param PhysObj The physics object from the entity that got resized.
	-- @param Size The new size of the entity.
	-- @param Scale The new scale of the entity.
	-- This is based off the size of the model the entity it's using and the scale that was given.
	function Gamemode:ACF_OnEntityResized()
	end
end)
