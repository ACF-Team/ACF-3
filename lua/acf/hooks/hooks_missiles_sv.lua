local Hooks = ACF.Utilities.Hooks


Hooks.Add("ACF_Missiles_Server", function(Gamemode)
	--- Called after a missile is fired.
	--- @param Entity entity The missile entity that was launched.
	function Gamemode:ACF_OnLaunchMissile()
	end

	--- Called when a missile attempts to create an explosion.
	--- @param Entity entity The affected missile.
	--- @param Data table The bullet data of the affected missile.
	--- @return boolean # True if the missile can explode, false otherwise.
	function Gamemode:ACF_PreExplodeMissile()
		return true
	end
end)
