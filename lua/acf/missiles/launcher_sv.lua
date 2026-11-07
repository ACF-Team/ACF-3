local ACF      = ACF
local Missiles = ACF.Missiles

-- A launcher is any table passed as Options.Launcher to Missiles.Create. Every method is optional:
--   GetEntity(Missile)                     -> Entity         What the missile is fired from; guidance uses its linked computer/radar
--   GetMissileFilter(Missile)              -> { Entity... }  Entities the missile won't hit once launched
--   GetLaunchOrigin(Missile)               -> Pos, Ang       Where command guidance steers from
--   GetLaunchSound(Missile)                -> string         Overrides the class' motor sound
--   CanDelayMotor(Missile)                 -> bool           Whether Options.MotorDelay is honored
--   OnMissileRemoved(Missile, WasLaunched)                   Called when the missile entity is removed

local RackLauncher = {}
RackLauncher.__index = RackLauncher

function RackLauncher:GetEntity()
	return self.Rack
end

function RackLauncher:GetMissileFilter()
	local Rack   = self.Rack
	local Filter = { Rack }

	if not IsValid(Rack) then return Filter end

	for _, Missile in pairs(Rack.Missiles) do
		Filter[#Filter + 1] = Missile
	end

	for Missile in pairs(Rack.InAirMissiles) do
		Filter[#Filter + 1] = Missile
	end

	return Filter
end

function RackLauncher:GetLaunchOrigin()
	local Rack  = self.Rack
	local Point = self.MountPoint

	if not IsValid(Rack) then return end

	return Rack:LocalToWorld(Point.Position), Rack:LocalToWorldAngles(Point.Angle)
end

function RackLauncher:GetLaunchSound()
	local Rack  = self.Rack
	local Sound = IsValid(Rack) and Rack.SoundPath

	if Sound and Sound ~= "" then return Sound end
end

function RackLauncher:CanDelayMotor()
	local Rack = self.Rack

	return IsValid(Rack) and Rack.CanDropMissile or false
end

function RackLauncher:OnMissileRemoved(_, WasLaunched)
	local Rack = self.Rack

	if WasLaunched or not IsValid(Rack) then return end

	Rack:UpdateLoad(self.MountPoint)
end

--- Wraps a rack and one of its mount points as a launcher.
function Missiles.RackLauncher(Rack, MountPoint)
	return setmetatable({ Rack = Rack, MountPoint = MountPoint }, RackLauncher)
end
