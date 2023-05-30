local Hooks = ACF.Utilities.Hooks


Hooks.Add("ACF_Base_Client", function(Gamemode)
	--- Called when the information about a repository is received and updated.
	-- @param Name The name of the repository that was updated.
	-- @param Repository The information about the repository.
	function Gamemode:ACF_OnFetchRepository()
	end

	--- Called when a new option is about to be added to the menu.
	-- This hook won't be called if the option object has
	-- an IsEnabled method defined and said method returns false.
	-- @param Name The name of the option object.
	-- @return True if the option should be added to the menu, false otherwise.
	function Gamemode:ACF_OnEnableMenuOption()
		return true
	end

	--- Called when a new option item is about to be added to the menu.
	-- @param Option The name of the option this item will be added to.
	-- @param Name The name of the new option item object.
	function Gamemode:ACF_OnEnableMenuItem()
		return true
	end

	--- Called before a client settings collapsible section is created.
	-- @param Name The name of the client settings section.
	-- @return True if the collapsible section can be created, false otherwise.
	function Gamemode:ACF_PreLoadClientSettings()
		return true
	end

	--- Called when a client settings section is about to be populated.
	-- @param Name The name of the client settings section.
	-- @param Panel The base panel where all the settings are going to be placed.
	-- @return True to override the panels created by the section itself, false otherwise.
	function Gamemode:ACF_OnLoadClientSettings()
		return false
	end

	--- Called after a client settings section has been populated.
	-- @param Name The name of the client settings section.
	-- @param Panel The base panel where all the settings were placed.
	function Gamemode:ACF_PostLoadClientSettings()
	end

	--- Called before a server settings collapsible section is created.
	-- @param Name The name of the server settings section.
	-- @return True if the collapsible section can be created, false otherwise.
	function Gamemode:ACF_PreLoadServerSettings()
		return true
	end

	--- Called when a server settings section is about to be populated.
	-- @param Name The name of the server settings section.
	-- @param Panel The base panel where all the settings are going to be placed.
	-- @return True to override the panels created by the section itself, false otherwise.
	function Gamemode:ACF_OnLoadServerSettings()
		return false
	end

	--- Called after a server settings section has been populated.
	-- @param Name The name of the server settings section.
	-- @param Panel The base panel where all the settings were placed.
	function Gamemode:ACF_PostLoadServerSettings()
	end

	--- Called before the ammo menu is created.
	-- @param Settings A table containing flags, used to define which parts of the default ammo menu won't be created.
	-- Adding the SuppressMenu field to this table will completely omit the default ammo menu creation.
	-- Adding the SupressPreview field to this table will omit the ammo model preview panel creation.
	-- Adding the SupressControls field to this table will omit the ammo settings panels creation.
	-- Adding the SupressTracer field to this table will omit the tracer checkbox panel creation.
	-- Adding the SupressInformation field to this table will omit the ammo stats panels creation.
	-- Adding the SuppressCrateInformation field to this table will omit the ammo crate stats panel creation.
	-- @param ToolData A table containing the copy of the local player's data variables.
	-- @param AmmoType The ammo type object to be used on the menu.
	-- @param BulletData A bullet object used to display the stats of the chosen ammunition type.
	function Gamemode:ACF_SetupAmmoMenuSettings()
	end

	-- Called after the ammo preview panel has been created but before it has been setup.
	-- This hook will only be called if Settings.SuppressPreview is not set.
	-- @param Panel The model preview panel used to display the ammo type model.
	-- @param SetupData The information table used for the model preview panel.
	-- The Model field will define the path of the model that will get displayed.
	-- The Height field will define the height of the panel.
	-- The FOV field will define the amount of zoom applied to the display.
	-- @param ToolData A table containing the copy of the local player's data variables.
	-- @param AmmoType The ammo type object to be used on the menu.
	-- @param BulletData A bullet object used to display the stats of the chosen ammunition type.
	function Gamemode:ACF_AddAmmoPreview()
	end

	-- Called after the projectile and propellant length panels have been created.
	-- This hook will only be called if Settings.SuppressControls is not set.
	-- @param Panel The base panel where all the controls are being placed.
	-- @param ToolData A table containing the copy of the local player's data variables.
	-- @param AmmoType The ammo type object to be used on the menu.
	-- @param BulletData A bullet object used to display the stats of the chosen ammunition type.
	function Gamemode:ACF_AddAmmoControls()
	end

	-- Called after the ammunition stats text panel has been created.
	-- This hook will only be called if Settings.SuppressInformation and Settings.SuppressCrateInformation are not set.
	-- @param Trackers A lookup table with the name of all the client data variables
	-- that could affect the size of the ammunition stored inside the crate.
	-- @param ToolData A table containing the copy of the local player's data variables.
	-- @param AmmoType The ammo type object to be used on the menu.
	-- @param BulletData A bullet object used to display the stats of the chosen ammunition type.
	function Gamemode:ACF_AddCrateDataTrackers()
	end

	-- Called after all the ammunition information panels have been created.
	-- This hook will only be called if Settings.SuppressInformation is not set.
	-- @param Panel The base panel where all the controls are being placed.
	-- @param ToolData A table containing the copy of the local player's data variables.
	-- @param AmmoType The ammo type object to be used on the menu.
	-- @param BulletData A bullet object used to display the stats of the chosen ammunition type.
	function Gamemode:ACF_AddAmmoInformation()
	end

	-- Called after a clientside bullet effect has been created.
	-- Used to override the default bullet effect.
	-- @param AmmoType The ID of the ammo type assigned to the bullet effect.
	-- @return The function that will override EFFECT:ApplyMovement, nil otherwise.
	function Gamemode:ACF_BulletEffect()
	end

	-- Called when the ACF Menu tool is being pointed towards an entity.
	-- The entity has to be, at most, 256 inches away from the player's eyes.
	-- This hook will only be called if the acf_drawboxes convar is set to a non zero value.
	-- For the developer's convenience, cam.Start3D and render.SetColorMaterial are called before this hook is ran.
	-- @param Entity The entity being pointed at.
	-- @param Trace The TraceResult from the player's eye trace.
	function Gamemode:ACF_DrawBoxes()
	end
end)
