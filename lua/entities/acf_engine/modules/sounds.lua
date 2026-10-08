local ACF = ACF
local Utilities = ACF.Utilities
local Sounds    = Utilities.Sounds

local Clamp = math.Clamp
local abs   = math.abs

--===============================================================================================--
-- Main Sound logic
--===============================================================================================--

local function GetPitchVolume(Engine)
	local RPM = Engine.FlyRPM
	local Pitch = Clamp(20 + (RPM * Engine.SoundPitch) * 0.02, 1, 255)
	-- Rev limiter code disabled because it has issues with the volume delta time, but it's still here if we need it
	local Throttle = Engine.Throttle -- Engine.RevLimited and 0 or Engine.Throttle
	local Volume = 0.25 + (0.1 + 0.9 * ((RPM / Engine.LimitRPM) ^ 1.5)) * Throttle * 0.666

	return Pitch, Volume * Engine.SoundVolume
end

function ENT:UpdateSound(SelfTbl)
	SelfTbl = SelfTbl or self:GetTable()

	local Path      = SelfTbl.SoundPath
	local LastSound = SelfTbl.LastSound

	if Path ~= LastSound and LastSound ~= nil then
		self:DestroySound()

		SelfTbl.LastSound = Path
	end

	if Path == "" then return end
	if not SelfTbl.Active then return end

	local Pitch, Volume = GetPitchVolume(SelfTbl)

	if abs(Pitch - SelfTbl.LastPitch) < 1 then return end -- Don't bother updating if the pitch difference is too small to notice

	SelfTbl.LastPitch = Pitch

	if SelfTbl.Sound then
		Sounds.SendAdjustableSound(self, false, Pitch, Volume)
	else
		Sounds.CreateAdjustableSound(self, Path, Pitch, Volume)
		SelfTbl.Sound = true
	end
end

function ENT:DestroySound()
	Sounds.SendAdjustableSound(self, true)

	self.LastSound  = nil
	self.LastPitch  = 0
	self.Sound      = nil
end
