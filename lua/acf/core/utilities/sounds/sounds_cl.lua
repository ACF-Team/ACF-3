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

			ValidSounds[Path] = Valid
		end

		return Valid
	end
end

do -- Playing regular sounds
	--- Plays a single, non-looping sound at the given origin.
	--- @param Origin table | vector The source to play the sound from
	--- @param Path string The path to the sound to be played local to the game's sound folder
	--- @param Level? integer The sound's level/attenuation from 0-127
	--- @param Pitch? integer The sound's pitch from 0-255
	--- @param Volume number A float representing the sound's volume; this is multiplied by the client's volume setting
	function Sounds.PlaySound(Origin, Path, Level, Pitch, Volume)
		Volume = ACF.Volume * Volume

		if isentity(Origin) and IsValid(Origin) then
			Origin:EmitSound(Path, Level, Pitch, Volume)
		elseif isvector(Origin) then
			sound.Play(Path, Origin, Level, Pitch, Volume)
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
			Sounds.DestroyAdjustableSound(Entity)
		end)

		Sounds.UpdateAdjustableSound(Origin, Pitch, Volume)
	end

	--- Stops an existing adjustable sound on the origin.
	--- @param Origin table The entity to stop the sound on
	function Sounds.DestroyAdjustableSound(Origin)
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

function Sounds.HitSoundBank(Data, Trace, Type)
	local MatType   = Trace.MatType
	local Caliber = Data:GetRadius()

	local SoundData = {
		SoundPath   = "^acf_base/fx/hit/",
		SoundVolume = 100,
		SoundPitch  = 100
	}

	local SoundPath = SoundData.SoundPath
	local Directory = ""
	local Size = ""

	if Trace.HitWorld then --hit world
		local Materials = {
			[67] = "rock",
			[77] = "metal/penetration",
			[87] = "wood"
		}

		if Materials[MatType] ~= nil then
			Directory = Materials[MatType].."/"
		else
			Directory = "ground/"
		end

		if Caliber <= 3.0 then
			Size = "small_arms/"
		else
			Size = "small/"
		end

	elseif MatType == 70 then --hit flesh
		Directory = "body/"

	else --assume metal
		local AmmoType = Data:GetDamageType()

		Directory = "metal/"..Type.."/"

		if Caliber <= 1.5 then
			Size = "small_arms/"
		elseif Caliber > 1.5 and Caliber <= 6.6 then
			Size = "small/"
		elseif Caliber > 6.6 and Caliber < 11.8 then
			Size = "medium/"
		else 
			Size = "large/"
		end

		if Type == "impact" then
			if AmmoType == 2 or AmmoType == 3 or AmmoType == 4 then
				Size = Size.."dart/"
			else
				Size = Size.."ap/"
			end
		end

	end

	SoundData.SoundPath = SoundPath..Directory..Size.."%s.mp3"

	print(SoundData.SoundPath)

	return SoundData
end

function Sounds.ExplosionSoundBank(Radius)
	local SoundData = {
		SoundPath	= "^acf_base/fx/explosion",
		SoundVolume = 100,
		SoundPitch  = 100
	}

	local SoundPath = SoundData.SoundPath

	if Radius <= 2 then
		SoundData.SoundPath = SoundPath.."/small/%s.mp3"
		SoundData.SoundVolume = 90
	elseif Radius > 2 and Radius <= 6 then
		SoundData.SoundPath = SoundPath.."/medium-small/%s.mp3"
		SoundData.SoundVolume = 105
	elseif Radius > 6 and Radius <= 12 then
		SoundData.SoundPath = SoundPath.."/medium/%s.mp3"
		SoundData.SoundVolume = 116
	elseif Radius > 12 and Radius <= 20 then
		SoundData.SoundPath = SoundPath.."/medium-large/%s.mp3"
		SoundData.SoundVolume = 120
	elseif Radius > 20 and Radius < 30 then
		SoundData.SoundPath = SoundPath.."/large/%s.mp3"
		SoundData.SoundVolume = 124
	else
		SoundData.SoundPath = SoundPath.."/extra-large/%s.mp3"
		SoundData.SoundVolume = 127
	end

	return SoundData
end