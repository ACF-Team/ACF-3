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

	-- Data.Reason says why the links were removed, when they were removed for the player
	Register("crew_unlinked", {
		Title  = "Not Linked",
		Detail = function(Data)
			if Data.Reason then return "Links removed: " .. Data.Reason .. "." end

			return "This crew must be linked to something it can operate."
		end,
		Help   = "Link the crew to something it can operate, such as a weapon or a turret. Crew lose their links when "
			.. "reparented, when their occupation changes, or when a link ends up out of range or on another contraption.",
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

	Register("weapon_ammo_stage", {
		Title  = "No First Stage Ammo",
		Detail = function(Data)
			return "No linked crate is at ammo stage " .. (Data.Stage or "?") .. "."
		end,
		Help   = "Weapons only load from first stage crates, higher stages only restock the stages below them. "
			.. "Link a first stage crate, or lower the stage of one of the linked crates.",
	})
end

do -- MARK: Fuel hints
	Register("fueltank_leaking", {
		Title  = "Leaking",
		Detail = "This tank is leaking fuel.",
		Help   = "Damage punctured this tank. The leak seals itself over time, and faster the less fuel is left.",
	})
end

do -- MARK: Mobility hints
	Register("engine_no_gearbox", {
		Title  = "No Gearbox",
		Detail = "This engine is not linked to a gearbox.",
		Help   = "Link the engine to a gearbox, then link the gearbox to the wheels or to more gearboxes.",
	})

	Register("gearbox_no_input", {
		Title  = "No Input",
		Detail = "Nothing drives this gearbox.",
		Help   = "Link an engine to this gearbox, or link another gearbox to it so it receives that gearbox's output.",
	})

	Register("gearbox_no_output", {
		Title  = "No Output",
		Detail = "This gearbox is not linked to any wheels or gearboxes.",
		Help   = "Link this gearbox to the wheels it should drive, or to other gearboxes that drive them.",
	})

	Register("gearbox_overloaded", {
		Title  = "Overloaded",
		Detail = function(Data)
			return "At its " .. (Data.Rating or "?") .. " Nm torque rating " .. (Data.Percent or "?") .. "% of the time while driven."
		end,
		Help   = "The wheels ask for more torque than this gearbox can pass, so the rest is lost and the vehicle accelerates "
			.. "slower. Raise the gearbox's scale, use fewer gears, or split the load over more gearboxes.",
	})

	Register("controller_no_baseplate", {
		Title  = "No Baseplate",
		Detail = "This controller is not linked to a baseplate.",
		Help   = "Link the controller to the vehicle's baseplate, it drives, steers and seats the driver through it.",
	})

	Register("controller_no_gearbox", {
		Title  = "No Gearbox",
		Detail = "This vehicle has engines but the controller is not linked to a gearbox.",
		Help   = "Link the controller to the main gearbox, the one the engines are linked to, so it can drive the vehicle.",
	})

	Register("controller_shift_rpm", {
		Title  = "No Shift RPM",
		Detail = function(Data)
			return "Both shift RPMs are " .. (Data.RPM or 0) .. ", so the controller never changes gears."
		end,
		Help   = "Set the shift RPMs in the controller's Shifting Settings, from its context menu's Edit Properties, usually "
			.. "around the engine's powerband. Or turn on Disable Auto Shifter if gears are shifted some other way.",
	})

	Register("controller_no_reverse", {
		Title  = "No Reverse",
		Detail = "The main gearbox has no reverse gear, so the vehicle cannot back up.",
		Help   = "Give the main gearbox a gear with a negative ratio, or add transfer gearboxes that reverse for it.",
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

	Register("turret_gyro_no_drive", {
		Title  = "No Turret Drive",
		Detail = "This gyro is not linked to a turret drive.",
		Help   = "Link the gyro to a turret drive. A dual axis gyro can stabilize one horizontal and one vertical drive.",
	})

	Register("turret_controller_no_turret", {
		Title  = "No Turret",
		Detail = "This controller is not linked to a turret.",
		Help   = "Link the controller to a nearby turret drive in the same contraption.",
	})

	Register("turret_controller_no_crew", {
		Title  = "No Crew",
		Detail = "This remote controller is not linked to a crew member.",
		Help   = "Link the controller to a gunner, commander or pilot. It must share their parent, sit in front of them "
			.. "and be in their line of sight.",
	})
end

-- Problems that stop an entity from working, shown in red by the entity's own overlay rather than raised through ACF.Legality
do -- MARK: Status errors
	local function RegisterError(Id, Data)
		return ACF.Diagnostics.Register("Error", Id, Data)
	end

	RegisterError("rack_jammed", {
		Title  = "Jammed",
		Detail = "This rack is jammed.",
		Help   = "Damage jammed this rack. Repair it to full health to clear the jam.",
	})

	RegisterError("actuator_overloaded", {
		Title  = "Overloaded",
		Detail = "Overloaded, can only retract.",
		Help   = "This actuator carries more than it can lift. Reduce the load, or use a wider bore or a shorter stroke, "
			.. "which both raise the load limit.",
	})
end
