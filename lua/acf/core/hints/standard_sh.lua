-- Build hints for mistakes that stay wrong until the builder fixes them
local ACF = ACF

local function Register(Id, Data)
	return ACF.Diagnostics.Register("Warning", Id, Data)
end

local function Name(Entity, Fallback)
	return IsValid(Entity) and tostring(Entity) or Fallback
end

do -- MARK: Crew hints
	-- The sight line itself is drawn at acf_developer 2 by the gun and rack
	Register("crew_breech_los", {
		Title  = "Cannot See Breech",
		Detail = function(Data)
			return "This crew cannot see the breech of " .. Name(Data.Gun, "its weapon") .. ", blocked by "
				.. Name(Data.Blocker, "another entity") .. "."
		end,
		Help   = "Move the crew or the blocking entity so the crew has a clear line of sight to the breech.",
	})

	Register("crew_unlinked", {
		Title  = "Not Linked",
		Detail = "This crew must be linked to something it can operate.",
		Help   = "Link the crew to something it can operate, such as a weapon or a turret.",
	})

	Register("driver_yaw", {
		Title  = "Driver Misaligned",
		Detail = function(Data)
			return "The driver must face the baseplate's forward. Yaw deviation: " .. (Data.Deviation or "?")
				.. ", acceptable: " .. (Data.Limit or "?") .. "."
		end,
		Help   = "Rotate the driver so it faces the baseplate's forward direction, within the shown limit.",
	})
end

do -- MARK: Autoloader hints
	Register("autoloader_mount_points", {
		Title  = "Unsupported Rack",
		Detail = "The autoloader is linked to a rack with multiple mount points, which is unsupported.",
		Help   = "Link the autoloader to a rack with a single mount point.",
	})

	Register("autoloader_no_weapon", {
		Title  = "No Weapon",
		Detail = "The autoloader is not linked to a weapon.",
		Help   = "Link the autoloader to a gun or rack.",
	})

	Register("autoloader_no_ammo", {
		Title  = "No Ammo Crate",
		Detail = "The autoloader is not linked to an ammo crate.",
		Help   = "Link the autoloader to an ammo crate the weapon can use.",
	})

	Register("autoloader_misaligned", {
		Title  = "Misaligned",
		Detail = "Autoloader or ammo are probably backwards or greatly misaligned.",
		Help   = "Turn the autoloader to face the right way and move it closer to the breech and the ammo.",
	})
end

do -- MARK: Ammo hints
	Register("weapon_no_ammo", {
		Title  = "No Ammo Crate",
		Detail = "This weapon is not linked to an ammo crate.",
		Help   = "Link the weapon to an ammo crate of a compatible type that is within range.",
	})

	Register("ammo_no_weapon", {
		Title  = "No Weapon",
		Detail = "This crate is not linked to a weapon.",
		Help   = "Link this crate to a weapon that can use its ammo.",
	})

	Register("weapon_not_loading", {
		Title  = "Not Loading",
		Detail = "Ammo is available but the weapon is not loading. Fire it or use the Reload input to try again.",
		Help   = "Fire the weapon or use the Reload input to start a reload.",
	})
end

do -- MARK: Mobility hints
	Register("engine_no_fuel", {
		Title  = "No Fuel Tank",
		Detail = "No compatible fuel tanks share this engine's parent.",
		Help   = "Parent a fuel tank the engine can use to the same parent as the engine.",
	})

	Register("controller_parent", {
		Title  = "Bad Parent",
		Detail = "This controller must be parented to the baseplate or its contraption.",
		Help   = "Parent the controller to the baseplate or to something in its contraption.",
	})
end

do -- MARK: Sensor hints
	Register("sensorsync_no_sensors", {
		Title  = "No Sensors",
		Detail = "This synchronizer is not linked to any sensors.",
		Help   = "Link the synchronizer to one or more sensors.",
	})
end

do -- MARK: Turret hints
	Register("turret_computer_no_gun", {
		Title  = "No Gun",
		Detail = "This computer is not linked to a gun.",
		Help   = "Link the computer to a gun.",
	})

	Register("turret_motor_no_drive", {
		Title  = "No Turret Drive",
		Detail = "This motor is not linked to a turret drive.",
		Help   = "Link the motor to a turret drive.",
	})
end
