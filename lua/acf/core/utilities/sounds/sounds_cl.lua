local Sounds = ACF.Utilities.Sounds

do -- Valid sound check
	local file     = file
	local isstring = isstring
	local Folder   = "sound/%s"
	local ValidSounds   = {}

	--- Searches for the given sound path in the game folder to determine if it is usable.
	--- @param Name string The path to the sound to be played local to the game's sound folder
	--- @return boolean # Whether the sound exists clientside or not
	function Sounds.IsValidSound(Name)
		if not isstring(Name) then return false end

		local Path  = Folder:format(Name:Trim())
		local Valid = ValidSounds[Path]

		if Valid == nil then
			Valid = file.Exists(Path, "GAME")
			if not Valid then
				Valid = sound.GetProperties(Name) ~= nil
			end
			ValidSounds[Path] = Valid
		end

		return Valid
	end
end

local function DistanceToOrigin(Origin)
	if isentity(Origin) and IsValid(Origin) then
		return LocalPlayer():EyePos():Distance(Origin:GetPos())
	elseif isvector(Origin) then
		return LocalPlayer():EyePos():Distance(Origin)
	else
		return 0
	end
end

-- TODO: Consider if we're actually going to do this or not.
-- It's not hard to add back in the future (we just wrap the calls around this)
-- The bottom self-assignment is so the linter shuts up in the meantime
local function DoDelayed(Origin, Call, Instant)
	if Instant then return Call() end

	local Delay = DistanceToOrigin(Origin) / ACF.SpeedOfSound
	if Delay > 0.1 then
		timer.Simple(Delay, function() Call() end)
	else
		Call()
	end
end
DoDelayed = DoDelayed

-- Maps a value, X, from a range A-B, to a new range C-D
local function map(x, a, b, c, d)
	return (x - a) / (b - a) * (d - c) + c
end

-- Fade function taken from:
-- https://dsp.stackexchange.com/questions/37477/understanding-equal-power-crossfades
-- https://dsp.stackexchange.com/questions/14754/equal-power-crossfade
-- https://i.imgur.com/KaFmaMf.png
local function fade(n, min, mid, max)
	local _PI = math.pi

	if n < min or n > max then return 0 end

	if n > mid then
		min = mid - (max - mid)
	end

	return math.cos((1 - ((n - min) / (mid - min))) * (_PI / 2))
end

-- This is where we store our sound objects
local SoundObjects = {}
-- Consider if we actually want to do this too! (commented out for now)
--local SmoothRPM = 0
--local SmoothThrottle = 0

local function DoPitchVolumeAtRPM(Origin, Throttle, RPM)
	local AdditionalCurveWidth = Origin.AddCurveWidth or 0
	--SmoothRPM = SmoothRPM * (1 - 0.1) + RPM * 0.1
	--SmoothThrottle = SmoothThrottle * (1 - 0.1) + Throttle * 10

	-- Sound volumes when throttle is 0 and 100 respectively
	local _OFFVOLUME = 0.25
	local _ONVOLUME = 1

	-- TODO(TMF): Potentially some mechanism here to check for any differences and only update those
	for idx, soundTable in ipairs(SoundObjects) do
		if not SoundObjects[idx].rpm then continue end
		local min    = idx == 1 and 0 or SoundObjects[idx - 1].rpm
		local mid    = RPM
		local max    = idx == #SoundObjects and 16383 or SoundObjects[idx + 1].rpm
		local curve  = fade(RPM, min - AdditionalCurveWidth, mid, max + AdditionalCurveWidth)
		local volume = curve * map(Throttle, 0, 1, _OFFVOLUME, _ONVOLUME)
		local pitch  = (RPM / soundTable.rpm) * 100
		Sounds.UpdateAdjustableSound(soundTable.sound, pitch, volume)
	end
end

do -- Playing regular sounds
	--- Plays a single, non-looping sound at the given origin.
	--- @param Origin table | vector The source to play the sound from
	--- @param Path string The path to the sound to be played local to the game's sound folder
	--- @param Level? integer The sound's level/attenuation from 0-127
	--- @param Pitch? integer The sound's pitch from 0-255
	--- @param Volume number A float representing the sound's volume; this is multiplied by the client's volume setting
	--- @param UseBASS? boolean Whether the sound should be played through BASS instead; use this for things like volumes greater than 1
	function Sounds.PlaySound(Origin, Path, Level, Pitch, Volume, UseBASS)
		Volume = ACF.Volume * Volume

		if isentity(Origin) and IsValid(Origin) then
			Origin:EmitSound(Path, Level, Pitch, Volume)
		elseif isvector(Origin) then
			if UseBASS then
				-- TODO: Find a way to apply level to this sound
				sound.PlayFile("sound/" .. Path, "3d", function(Channel)
					if IsValid(Channel) then
						Channel:SetPos(Origin)
						Channel:SetPlaybackRate(Pitch / 100)
						Channel:SetVolume(Volume)
						Channel:Play()
					end
				end)
			else
				sound.Play(Path, Origin, Level, Pitch, Volume)
			end
		end
	end

	net.Receive("ACF_Sounds", function()
		local IsEnt = net.ReadBool()
		local Origin = IsEnt and net.ReadEntity() or net.ReadVector()
		local Path = net.ReadString()
		local Level = net.ReadUInt(7)
		local Pitch = net.ReadUInt(8)
		local Volume = net.ReadUInt(8) / 100

		if not Sounds.IsValidSound(Path) then return end

		Sounds.PlaySound(Origin, Path, Level, Pitch, Volume)
	end)
end

do -- Processing adjustable sounds (for example, engine noises)
	local IsValid = IsValid

	--- Updates an adjustable sound on the origin with the given parameters.  
	--- If the sound is not currently playing, it will be forced to do so.  
	--- Updates are smoothed with a slight delta time due to ratelimiting of the server equivalent of this function.
	--- @param Origin table The entity to update the sound on
	--- @param Pitch integer The sound's pitch from 0-255
	--- @param Volume number A float representing the sound's volume
	function Sounds.UpdateAdjustableSound(Origin, Pitch, Volume)
		local Sound = Origin
		if type(Sound) ~= "CSoundPatch" then return end

		Volume = Volume * ACF.Volume

		if Sound:IsPlaying() then
			Sound:ChangePitch(Pitch, 0.05)
			Sound:ChangeVolume(Volume, 0.05)
		else
			Sound:PlayEx(Volume, Pitch)
		end
	end

	--- Creates a sound patch with the given parameters on the origin entity.  
	--- This is intended to be used for self-looping sounds played on an entity that can be adjusted easily later.
	--- @param Origin table The entity to play the sound from
	--- @param Path string The path to the sound to be played local to the game's sound folder
	--- @param Pitch integer The sound's pitch from 0-255
	--- @param Volume number A float representing the sound's volume
	--- @return Sound CSoundPatch The sound object
	function Sounds.CreateAdjustableSound(Origin, Path, Pitch, Volume)
		if not IsValid(Origin) then return end

		local Sound = CreateSound(Origin, Path)
		Origin.Sound = Sound

		-- Ensuring that the sound can't stick around if the server doesn't properly ask for it to be destroyed
		Origin:CallOnRemove("ACF_ForceStopAdjustableSound", function(Entity)
			Sounds.DestroyAdjustableSound(Entity, true)
		end)

		Sounds.UpdateAdjustableSound(Sound, Pitch, Volume)
		return Sound
	end

	--- Stops an existing adjustable sound on the origin.
	--- @param Origin table The entity to stop the sound on
	function Sounds.DestroyAdjustableSound(Origin, _)
		local Current = Origin.Sound
		if not Current then return end

		Current:Stop()
		Origin.Sound = nil
	end

	net.Receive("ACF_Sounds_Adjustable", function()
		local Origin = net.ReadEntity()
		local ShouldStop = net.ReadBool()

		if ShouldStop then
			Sounds.DestroyAdjustableSound(Origin)
		else
			local Pitch = net.ReadUInt(8)
			local Volume = net.ReadUInt(8) / 100

			Sounds.UpdateAdjustableSound(Origin, Pitch, Volume)
		end
	end)

	net.Receive("ACF_Sounds_AdjustableCreate", function()
		local Origin = net.ReadEntity()
		local Path = net.ReadString()
		local Pitch = net.ReadUInt(8)
		local Volume = net.ReadFloat()

		if not Sounds.IsValidSound(Path) then return end

		Sounds.CreateAdjustableSound(Origin, Path, Pitch, Volume)
	end)
end

do -- Multiple Engine Sounds(ex. Interpolated sounds)
	local IsValid = IsValid -- Should this stay as local to each scope?

	function Sounds.CreateMultipleAdjustableSounds(Origin, PathTable)
		local count = 1
		for rpm, soundTable in pairs(PathTable) do
			local Sound = Sounds.CreateAdjustableSound(Origin,
				soundTable.Path,
				soundTable.Pitch,
				soundTable.Volume
			)
			table.insert(SoundObjects, count, {["rpm"] = rpm, ["sound"] = Sound})
			count = count + 1

			Sounds.UpdateAdjustableSound(Origin, soundTable.Pitch, 0)
		end
		table.sort(SoundObjects, function(a, b) return a.rpm < b.rpm end)
		-- Ensuring that the sounds can't stick around if the server doesn't properly ask for them to be destroyed
		Origin:CallOnRemove("ACF_ForceStopMultipleAdjustableSounds", function(Entity)
			Sounds.DeleteMultipleAdjustableSounds(Entity, true)
		end)
	end

	function Sounds.DeleteMultipleAdjustableSounds(Origin, _)
		local count = 0
		print("Deleting sounds!")
		-- I suppose this actually gets garbage collected?
		for idx, snd in ipairs(SoundObjects) do
			snd.sound:Stop()
			SoundObjects[idx] = nil
			count = idx
		end
		Origin.Sound = nil
		print("Successfully deleted " .. count .. " sounds!")
	end

	net.Receive("ACF_Sounds_AdjustableCreate_Multi", function(len)
		print("Received " .. len .. " bits from server for \"ACF_Sounds_AdjustableCreate_Multi\"")
		local Origin = net.ReadEntity()
		local SoundTable = net.ReadTable()

		if not IsValid(Origin) then return end
		if not istable(SoundTable) then return end

		-- If only one sound was found, we assume it's at -1 index
		print(#SoundTable)
		--if #SoundTable < 1 then
			--PrintTable(SoundTable)
		--	local SoundTable = SoundTable[-1]
		--	Sounds.CreateAdjustableSound(Origin, SoundTable.Path, SoundTable.Pitch, SoundTable.Volume)
		--else
			Sounds.CreateMultipleAdjustableSounds(Origin, SoundTable)
		--end
	end)

	net.Receive("ACF_Sounds_Adjustable_Multi", function(len)
		print("Received " .. len .. " bits from server for \"ACF_Sounds_Adjustable_Multi\"")
		local Origin = net.ReadEntity()
		local ShouldStop = net.ReadBool()
		local Throttle = net.ReadUInt(7)
		local RPM = net.ReadUInt(14)

		-- Do we really need to remove every existing sound when the engine just turns off?
		if ShouldStop then
			Sounds.DeleteMultipleAdjustableSounds(Origin)
		else
			DoPitchVolumeAtRPM(Origin, Throttle, RPM)
		end
	end)
end
	--- Returns a table of sound infomation depending on what the trace hit.
	--- @param Data table The effect data relating to the projectile
	--- @param Trace table The trace data relating to the projectile
	--- @param EffectType string The type of effect being used (e.g. Impact, Ricochet)
function Sounds.GetHitSoundPath(Data, Trace, EffectType)
	local MatType   = Trace.MatType
	local Caliber   = Data:GetRadius()
	local HitWater  = bit.band(util.PointContents(Trace.HitPos), CONTENTS_WATER) == CONTENTS_WATER
	local SoundPath = {"^acf_base/fx/hit", "", "%s.mp3"}
	local SoundData = {
		SoundPath   = "",
		SoundPitch  = math.random(75, 125)
	}

	---hit world
	if Trace.HitWorld or HitWater then
		---more materials sounds can be added if the folders exist.
		local WorldSoundPath = {"world", "", ""}
		local Materials = {
			[67] = "rock",
			[77] = "metal",
			[87] = "wood"
		}

		---check the material type
		if Materials[MatType] ~= nil then
			WorldSoundPath[2] = Materials[MatType]
		elseif HitWater then
			WorldSoundPath[2] = "water"
		else
			---there wasn't a specified material sound type, use a generic sound
			WorldSoundPath[2] = "ground"
		end

		---check the caliber of the weapon
		if Caliber <= 3.0 then
			WorldSoundPath[3] = "small_arms"
		else
			WorldSoundPath[3] = "cannon"
		end

		SoundPath[2] = table.concat(WorldSoundPath, "/")

	---hit flesh material (players, crew ents, npcs)
	elseif MatType == 70 then
		SoundPath[2] = "flesh"

	---assume anything else is metal (props)
	else
		local AmmoType = Data:GetDamageType()
		local PropSoundPath = {"prop", EffectType, ""}

		---theres probably a better way to do this...
		if Caliber <= 1.5 then
			PropSoundPath[3] = "small_arms"
		elseif Caliber > 1.5 and Caliber <= 6.6 then
			PropSoundPath[3] = "small"
		elseif Caliber > 6.6 and Caliber < 11.8 then
			PropSoundPath[3] = "medium"
		else
			PropSoundPath[3] = "large"
		end

		---shot at with a dart round (apfsds, apds, apcr)
		if EffectType == "impact" and (AmmoType == 2 or AmmoType == 3 or AmmoType == 4) then
			PropSoundPath[4] = "dart"
		end

		SoundPath[2] = table.concat(PropSoundPath, "/")
	end

	SoundData.SoundPath = table.concat(SoundPath, "/")

	return SoundData
end

	--- Returns a table of sound infomation depending on the radius of the explosion.  
	--- @param Radius number Radius of the explosion
function Sounds.GetExplosionSoundPath(Radius)
	local SoundPath = {"^acf_base/fx/explosion", "", "%s.mp3"}
	local SoundData = {
		SoundPath	= "",
		SoundVolume = 100,
		SoundPitch  = math.random(75, 125)
	}

	---again probably a better way to do this...
	if Radius <= 2 then
		SoundPath[2] = "small"
		SoundData.SoundVolume = 92
	elseif Radius > 2 and Radius <= 6 then
		SoundPath[2] = "medium-small"
		SoundData.SoundVolume = 105
	elseif Radius > 6 and Radius <= 12 then
		SoundPath[2] = "medium"
		SoundData.SoundVolume = 116
	elseif Radius > 12 and Radius <= 20 then
		SoundPath[2] = "medium-large"
		SoundData.SoundVolume = 120
	elseif Radius > 20 and Radius < 30 then
		SoundPath[2] = "large"
		SoundData.SoundVolume = 124
	else
		SoundPath[2] = "extra-large"
		SoundData.SoundVolume = 127
	end

	SoundData.SoundPath = table.concat(SoundPath, "/")

	return SoundData
end