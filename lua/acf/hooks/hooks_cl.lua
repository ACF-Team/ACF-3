-- NOTE: Make sure that all hooks obey the naming convention "ACF_[Pre/On/Post][ACTION][ACTOR]"!
local Hooks = ACF.Utilities.Hooks

Hooks.Add("ACF_Base_Client", function(Gamemode)
	--- Called when the information about a repository is received and updated.
	--- @param Name string The name of the repository that was updated.
	--- @param Repository table The information about the repository.
	function Gamemode:ACF_OnFetchRepository()
	end

	--- Called when a new option is about to be added to the menu.  
	--- This hook won't be called if the option object has  
	--- an IsEnabled method defined and said method returns false.
	--- @param Name string The name of the option object.
	--- @return boolean # True if the option should be added to the menu, false otherwise.
	function Gamemode:ACF_OnEnableMenuOption()
		return true
	end

	--- Called when a new option item is about to be added to the menu.
	--- @param Option string The name of the option this item will be added to.
	--- @param Name string The name of the new option item object.
	function Gamemode:ACF_OnEnableMenuItem()
		return true
	end

	--- Called before a client settings collapsible section is created.
	--- @param Name string The name of the client settings section.
	--- @return boolean # True if the collapsible section can be created, false otherwise.
	function Gamemode:ACF_PreLoadClientSettings()
		return true
	end

	--- Called when a client settings section is about to be populated.
	--- @param Name string The name of the client settings section.
	--- @param Panel panel The base panel where all the settings are going to be placed.
	--- @return boolean # True to override the panels created by the section itself, false otherwise.
	function Gamemode:ACF_OnLoadClientSettings()
		return false
	end

	--- Called after a client settings section has been populated.
	--- @param Name string The name of the client settings section.
	--- @param Panel panel The base panel where all the settings were placed.
	function Gamemode:ACF_PostLoadClientSettings()
	end

	--- Called before a server settings collapsible section is created.
	--- @param Name string The name of the server settings section.
	--- @return boolean # True if the collapsible section can be created, false otherwise.
	function Gamemode:ACF_PreLoadServerSettings()
		return true
	end

	--- Called when a server settings section is about to be populated.
	--- @param Name string The name of the server settings section.
	--- @param Panel panel The base panel where all the settings are going to be placed.
	--- @return boolean # True to override the panels created by the section itself, false otherwise.
	function Gamemode:ACF_OnLoadServerSettings()
		return false
	end

	--- Called after a server settings section has been populated.
	--- @param Name string The name of the server settings section.
	--- @param Panel panel The base panel where all the settings were placed.
	function Gamemode:ACF_PostLoadServerSettings()
	end

	--- Called before the ammo menu is created.
	--- @param ToolData table A table containing the copy of the local player's data variables.
	--- @param AmmoType table The ammo type object to be used on the menu.
	--- @param BulletData table A bullet object used to display the stats of the chosen ammunition type.
	--- @return boolean # True to create the ammo menu, false otherwise
	function Gamemode:ACF_PreCreateAmmoMenu()
		return true
	end

	--- Called when the ammo menu is about to be populated.
	--- @param Panel panel The base ACF_Menu panel where everything will be created.
	--- @param ToolData table A table containing the copy of the local player's data variables.
	--- @param AmmoType table The ammo type object to be used on the menu.
	--- @param BulletData table A bullet object used to display the stats of the chosen ammunition type.
	function Gamemode:ACF_OnCreateAmmoMenu()
	end

	--- Called before the ammo preview panel gets created.
	--- @param Panel panel The base panel where all the controls are being placed.
	--- @param ToolData table A table containing the copy of the local player's data variables.
	--- @param AmmoType table The ammo type object to be used on the menu.
	--- @param BulletData table A bullet object used to display the stats of the chosen ammunition type.
	--- @return boolean # False to prevent the ammo preview panel from being created, true otherwise.
	function Gamemode:ACF_PreCreateAmmoPreview()
		return true
	end

	--- Called after the ammo preview panel has been created but before it has been setup.
	--- @param Panel panel The model preview panel used to display the ammo type model.
	--- @param SetupData table The information table used for the model preview panel.  
	--- The Model field will define the path of the model that will get displayed.  
	--- The Height field will define the height of the panel.  
	--- The FOV field will define the amount of zoom applied to the display.
	--- @param ToolData table A table containing the copy of the local player's data variables.
	--- @param AmmoType table The ammo type object to be used on the menu.
	--- @param BulletData table A bullet object used to display the stats of the chosen ammunition type.
	function Gamemode:ACF_OnCreateAmmoPreview()
	end

	--- Called before the projectile and propellant length panels are created.
	--- @param Panel panel The base panel where all the controls are being placed.
	--- @param ToolData table A table containing the copy of the local player's data variables.
	--- @param AmmoType table The ammo type object to be used on the menu.
	--- @param BulletData table A bullet object used to display the stats of the chosen ammunition type.
	--- @return boolean # False to prevent the panels from being created, true otherwise.
	function Gamemode:ACF_PreCreateAmmoControls()
		return true
	end

	--- Called after the projectile and propellant length panels have been created.
	--- @param Panel panel The base panel where all the controls are being placed.
	--- @param ToolData table A table containing the copy of the local player's data variables.
	--- @param AmmoType table The ammo type object to be used on the menu.
	--- @param BulletData table A bullet object used to display the stats of the chosen ammunition type.
	function Gamemode:ACF_OnCreateAmmoControls()
	end

	--- Called before the tracer checkbox panel gets created.
	--- @param Panel panel The base panel where all the controls are being placed.
	--- @param ToolData table A table containing the copy of the local player's data variables.
	--- @param AmmoType table The ammo type object to be used on the menu.
	--- @param BulletData table A bullet object used to display the stats of the chosen ammunition type.
	--- @return boolean # False to prevent the checkbox from being created, true otherwise.
	function Gamemode:ACF_PreCreateTracerControls()
		return true
	end

	--- Called after the tracer checkbox panel has been created.
	--- @param Panel panel The base panel where all the controls are being placed.
	--- @param ToolData table A table containing the copy of the local player's data variables.
	--- @param AmmoType table The ammo type object to be used on the menu.
	--- @param BulletData table A bullet object used to display the stats of the chosen ammunition type.
	function Gamemode:ACF_OnCreateTracerControls()
	end

	--- Called before the ammo information panels get created.
	--- @param Panel panel The base panel where all the controls are being placed.
	--- @param ToolData table A table containing the copy of the local player's data variables.
	--- @param AmmoType table The ammo type object to be used on the menu.
	--- @param BulletData table A bullet object used to display the stats of the chosen ammunition type.
	--- @return boolean # False to prevent the ammo information panels from being created, true otherwise.
	function Gamemode:ACF_PreCreateAmmoInformation()
		return true
	end

	--- Called before the ammo crate information panel gets created.
	--- @param Panel panel The base panel where all the controls are being placed.
	--- @param ToolData table A table containing the copy of the local player's data variables.
	--- @param AmmoType table The ammo type object to be used on the menu.
	--- @param BulletData table A bullet object used to display the stats of the chosen ammunition type.
	--- @return boolean # False to prevent the ammo crate information panel from being created, true otherwise.
	function Gamemode:ACF_PreCreateCrateInformation()
		return true
	end

	--- Called after the ammo crate information panel has been created.
	--- @param Panel panel The base panel where all the controls are being placed.
	--- @param Label panel The label panel where all the ammo crate information is being displayed.
	--- @param ToolData table A table containing the copy of the local player's data variables.
	--- @param AmmoType table The ammo type object to be used on the menu.
	--- @param BulletData table A bullet object used to display the stats of the chosen ammunition type.
	function Gamemode:ACF_OnCreateCrateInformation()
	end

	--- Called after all the ammunition information panels have been created.
	--- @param Panel panel The base panel where all the controls are being placed.
	--- @param ToolData table A table containing the copy of the local player's data variables.
	--- @param AmmoType table The ammo type object to be used on the menu.
	--- @param BulletData table A bullet object used to display the stats of the chosen ammunition type.
	function Gamemode:ACF_OnCreateAmmoInformation()
	end

	--- Called after a clientside bullet effect has been created.  
	--- Used to override the default bullet effect.
	--- @param Effect entity The effect entity that was created for a bullet.
	--- @param BulletData table An object with the networked information from the bullet's ammo crate of origin.  
	--- Note that the information on this object will be much more limited than the one serverside bullet data would carry.
	function Gamemode:ACF_OnCreateBulletEffect()
	end

	--- Called when the ACF Menu tool is being pointed towards an entity.  
	--- The entity has to be, at most, 256 inches away from the player's eyes.  
	--- This hook will only be called if the acf_drawboxes convar is set to a non zero value.  
	--- For the developer's convenience, cam.Start3D and render.SetColorMaterial are called before this hook is ran.
	--- @param Entity entity The entity being pointed at.
	--- @param Trace table The TraceResult from the player's eye trace.
	function Gamemode:ACF_OnDrawBoxes()
	end

	--- Called after requesting a newly spawned model's data from the server.  
	--- Model data will always be invalid at this point.
	--- @param Model string The model that has had its data requested.
	function Gamemode:ACF_OnRequestModelData()
	end

	--- Called after receiving a newly spawned model's data from the server.
	--- @param Model string The model that has received new data.
	--- @param Data table The data about the model that was received from the server.
	function Gamemode:ACF_OnReceiveModelData()
	end
end)
