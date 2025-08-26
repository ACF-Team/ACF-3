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

-- MARCH/TODO: universal ACF constant for speed of sound (maybe it already exists and I don't know :P)
local SpeedOfSound = 343 * 39.37

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

	local Delay = DistanceToOrigin(Origin) / SpeedOfSound
	if Delay > 0.1 then
		timer.Simple(Delay, function() Call() end)
	else
		Call()
	end
end
DoDelayed = DoDelayed

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
		if not IsValid(Origin) then return end

		local Sound = Origin.Sound
		if not Sound then return end

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
	function Sounds.CreateAdjustableSound(Origin, Path, Pitch, Volume)
		if not IsValid(Origin) then return end
		if Origin.Sound then return end

		local Sound = CreateSound(Origin, Path)
		Origin.Sound = Sound

		-- Ensuring that the sound can't stick around if the server doesn't properly ask for it to be destroyed
		Origin:CallOnRemove("ACF_ForceStopAdjustableSound", function(Entity)
			Sounds.DestroyAdjustableSound(Entity, true)
		end)

		Sounds.UpdateAdjustableSound(Origin, Pitch, Volume)
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