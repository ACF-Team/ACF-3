--[[

	This file is loaded when ACF starts, just after all of the settings are set to their default values.
	Rename this file to acf_userconfig.lua to enable this file, and customize those settings.
	
	Move this file outside of the ACF folder to stop it being overwritten.
	Put it in another addon folder (acf2, acfconfig), or put it in garrysmod/lua/acf/shared/

]]--

-- IMPORTANT: AddCSLuaFile is required!  Do not remove it.
AddCSLuaFile() 



-- Some example settings are below.  They enable damage protection, double gun accuracy, and make shots more likely to be accurate.
-- There are more settings like this.  Find them all in lua/autorun/shared/acf_globals.lua


ACF.EnableDefaultDP = true 	-- Enable the inbuilt damage protection system.
ACF.GunInaccuracyScale = 0.5  -- Make guns 2x more accurate by halving the spread scale.
ACF.GunInaccuracyBias = 1.2  -- Shots are more likely to be accurate with bias < 2