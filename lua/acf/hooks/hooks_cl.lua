local Hooks = ACF.Utilities.Hooks


Hooks.Add("ACF_Base_Client", function(Gamemode)
	--- Called when a new request for model information is made to the server
	-- @param Model The model whose information has been requested.
	function Gamemode:ACF_OnRequestedModelData()
	end

	--- Called when the model data has been received from the server.
	-- @param Model The model whose data has been received.
	-- @param Data The model information sent by the server.
	function Gamemode:ACF_OnReceivedModelData()
	end

	--- Called when the information about a repository is received and updated.
	-- @param Name The name of the repository that was updated.
	-- @param Repository The information about the repository.
	function Gamemode:ACF_UpdatedRepository()
	end

	--- Called when a new option is about to be added to the menu.
	-- This hook won't be called if the option object has
	-- an IsEnabled method defined and said method returns false.
	-- @param Index REMOVE
	-- @param Name The name of the option object.
	-- @return True if the option should be added to the menu, false otherwise.
	function Gamemode:ACF_AllowMenuOption()
		return true
	end

	--- Called when a new option item is about to be added to the menu.
	-- @param Index REMOVE
	-- @param Option The name of the option this item will be added to.
	-- @param Name The name of the new option item object.
	function Gamemode:ACF_AllowMenuItem()
		return true
	end

	-- @param Name
	-- @param Panel
	function Gamemode:ACF_OnClientSettingsLoaded()
	end

	-- @param Name
	-- @param Panel
	function Gamemode:ACF_OnServerSettingsLoaded()
	end

	-- @param Settings
	-- @param ToolData
	-- @param AmmoType
	-- @param BulletData
	function Gamemode:ACF_SetupAmmoMenuSettings()
	end

	-- @param Panel
	-- @param SetupData
	-- @param ToolData
	-- @param AmmoType
	-- @param BulletData
	function Gamemode:ACF_AddAmmoPreview()
	end

	-- @param Panel
	-- @param ToolData
	-- @param AmmoType
	-- @param BulletData
	function Gamemode:ACF_AddAmmoControls()
	end

	-- @param Trackers
	-- @param ToolData
	-- @param AmmoType
	-- @param BulletData
	function Gamemode:ACF_AddCrateDataTrackers()
	end

	-- @param Panel
	-- @param ToolData
	-- @param AmmoType
	-- @param BulletData
	function Gamemode:ACF_AddAmmoInformation()
	end

	-- @param AmmoType
	function Gamemode:ACF_BulletEffect()
	end

	-- @param Entity
	-- @param Trace
	function Gamemode:ACF_DrawBoxes()
	end
end)
