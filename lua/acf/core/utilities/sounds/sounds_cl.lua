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

do -- Playing regular sounds
	--- Plays a single, non-looping sound at the given origin.
	--- @param Origin table | vector The source to play the sound from
	--- @param Path string The path to the sound to be played local to the game's sound folder
	--- @param Level? integer The sound's level/attenuation from 0-127
	--- @param Pitch? integer The sound's pitch from 0-255
	--- @param Volume number A float representing the sound's volume; this is multiplied by the client's volume setting
	--- @param UseBASS? boolean Whether the sound should be played through BASS instead; use this for things like volumes greater than 1
	--- @param Callback? function Called with the resulting IGModAudioChannel after it's been created
	function Sounds.PlaySound(Origin, Path, Level, Pitch, Volume, UseBASS, Callback)
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

					if Callback then Callback(Channel) end
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
	--- @return Sound CSoundPatch The sound object
	function Sounds.CreateAdjustableSound(Origin, Path, Pitch, Volume)
		if not IsValid(Origin) then return end
		if not Sounds.IsValidSound(Path) then return end

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

local cos = math.cos
local _PI = math.pi
-- Fade function taken from:
-- https://dsp.stackexchange.com/questions/37477/understanding-equal-power-crossfades
-- https://dsp.stackexchange.com/questions/14754/equal-power-crossfade
function Sounds.Fade(N, Min, Mid, Max)
	if N < Min or N > Max then return 0 end

	if N > Mid then
		Min = Mid - (Max - Mid)
	end

	return cos((1 - ((N - Min) / (Mid - Min))) * (_PI / 2))
end

local Remap = math.Remap
local Clamp = math.Clamp
-- This is where the magic to interpolate sounds happen.
-- In order to make yourself a better idea of what this does you can consult the image below:
-- https://i.imgur.com/KaFmaMf.png
local function DoPitchVolumeAtRPM(Origin, Throttle, RPM)
	local Fade = Sounds.Fade -- idk if this is faster to do, but given this is a hot path, might as well be...
	local SoundObjects = Origin.SoundObjects
	if not SoundObjects or table.IsEmpty(SoundObjects) then return end

	-- TODO(TMF): Potentially add some mechanism here to check for any differences and only update those
	for _, SoundBank in ipairs(SoundObjects) do
		local Entity = SoundBank.Entity
		if not IsValid(Entity) then Entity = Origin end

		local OffVolume = SoundBank.OffThrottle
		local OnVolume = SoundBank.OnThrottle

		for Idx, SoundTable in ipairs(SoundBank.Sounds) do
			if not SoundTable.RPM then continue end
			Entity.Sound = SoundTable.Sound

			local AddCurveWidth = SoundTable.Width or 0
			local EnginePitch = SoundTable.Pitch or 1
			local Min    = Idx == 1 and -1000000 or SoundBank.Sounds[Clamp(Idx - 1 - AddCurveWidth, 1, ACF.MaxSounds)].RPM
			local Mid    = SoundTable.RPM
			local Max    = Idx == #SoundBank.Sounds and 1000000 or SoundBank.Sounds[Clamp(Idx + 1 + AddCurveWidth, 1, ACF.MaxSounds)].RPM
			local Curve  = Fade(RPM, Min, Mid, Max)
			local Volume = Curve * Remap(Throttle, 0, 100, OffVolume, OnVolume) * (SoundTable.Volume or 1)
			local Pitch  = (RPM / SoundTable.RPM) * EnginePitch

			Sounds.UpdateAdjustableSound(Entity, Pitch, Volume)
		end
	end
end

do -- Multiple Engine Sounds(ex. Interpolated sounds)
	local IsValid = IsValid
	 -- Weak keyed table so it doesn't stay around when its awaiting a request to arrive and the entity gets removed.
	local PendingSoundRequests = setmetatable({}, {__mode = "k"})

	--- Ask the server for the Entity's soundbank data, if we didn't have it yet but we receive a Throttle/RPM update.
	local function RequestMultipleAdjustableSounds(Origin)
		if not IsValid(Origin) then return end
		if PendingSoundRequests[Origin] then return end -- Already asked, waiting on the response

		PendingSoundRequests[Origin] = true

		net.Start("ACF_Sounds_AdjustableRequest_Multi")
			net.WriteEntity(Origin)
		net.SendToServer()
	end

	--- Creates many sounds from a table, and stores their entries in the Origin's entity.
	--- Reuses existing methods to create and update sounds.
	--- @param Origin table The entity to play the sounds from
	--- @param SoundTable table The networked table with nested table containing rpm, sound path, pitch, volume, width and empty sound
	function Sounds.CreateMultipleAdjustableSounds(Origin, SoundTable)
		local SoundTable = SoundTable
		local SoundBankCount = 0
		local SoundCount = 0

		for _, SoundBankTable in ipairs(SoundTable) do
			local Entity = SoundBankTable.PlayAtEntity
			if not IsValid(Entity) then continue end -- Just in case

			for _, SndTable in ipairs(SoundBankTable.Sounds) do
				local Sound = Sounds.CreateAdjustableSound(Entity,
				SndTable.Path,
				SndTable.Pitch or 100, 0) -- Create the sound deafened

				if not Sound then
					print("Failed to create sound for entity " .. tostring(Entity) .. ". Sound path does not exist!")
					continue
				end
				SndTable.Sound = Sound
				SoundCount = SoundCount + 1
			end
			-- Sort the table by the rpm before moving on, so it can be iterated in sequential order
			table.sort(SoundBankTable.Sounds, function(a, b) return a.RPM < b.RPM end)

			SoundBankCount = SoundBankCount + 1
		end

		Origin.SoundBankCount = SoundBankCount
		Origin.SoundObjects = SoundTable
		Origin.SoundCount = SoundCount
		PendingSoundRequests[Origin] = nil -- Our response arrived, clear the request.
		-- Ensuring that the sounds can't stick around if the server doesn't properly ask for them to be destroyed
		Origin:CallOnRemove("ACF_ForceStopMultipleAdjustableSounds", function(Entity)
			Sounds.DeleteMultipleAdjustableSounds(Entity, true)
		end)
	end

	--- Stops all the existing sounds from the entity
	--- @param Origin table The entity to stop all the sounds from
	function Sounds.DeleteMultipleAdjustableSounds(Origin, _)
		if not IsValid(Origin) then return end
		if not Origin.SoundObjects then return end

		for Idx, Bank in ipairs(Origin.SoundObjects) do
			for _, Snd in ipairs(Bank.Sounds) do
				Snd.Sound:Stop()
			end
			Origin.SoundObjects[Idx] = nil
		end
		Origin.Sound      	  = nil -- Just in case
		Origin.SoundCount 	  = 0
		Origin.SoundBankCount = 0
	end

	local _BIT_NUM_SOUNDBANKS = ACF.GetNearestPowerOfTwo(ACF.MaxSoundBanks)
	-- For multiple sounds creation
	net.Receive("ACF_Sounds_AdjustableCreate_Multi", function(len)
		print("Received " .. len .. " bits from \"ACF_Sounds_AdjustableCreate_Multi\" for sound creation!") -- Debug print
		local Origin = net.ReadEntity()
		local Exhaust = net.ReadEntity()
		local SoundBankCount = net.ReadUInt(_BIT_NUM_SOUNDBANKS)

		local SoundTable = {}

		for Bank = 1, SoundBankCount do
			local PlaysAtExhaust = net.ReadBool()
			local OffThrottle = net.ReadUInt(8)
			local OnThrottle = net.ReadUInt(8)
			local SoundCount = net.ReadUInt(4)

			if not IsValid(Exhaust) then Exhaust = Origin end
			local PlayAtEntity = PlaysAtExhaust and Exhaust or Origin

			OffThrottle = OffThrottle * 0.01 -- Reduce the received values down to a float
			OnThrottle = OnThrottle * 0.01

			table.insert(SoundTable, {PlayAtEntity = PlayAtEntity,
									  OffThrottle = OffThrottle,
									  OnThrottle = OnThrottle,
									  Sounds = {}
									 })

			for _ = 1, SoundCount do
				local RPM 		 = net.ReadUInt(ACF.NetSoundRPMBitLimit)
				local StringPath = net.ReadString()
				local Pitch 	 = net.ReadUInt(8)
				local Volume 	 = net.ReadUInt(8)
				local Width 	 = net.ReadUInt(4)

				Volume = Volume * 0.01 -- Reduce the received value down to a float
				table.insert(SoundTable[Bank].Sounds, { RPM    = RPM,
													    Path   = StringPath,
														Pitch  = Pitch or 100,
														Volume = Volume or 1,
														Width  = Width or 0,
														Sound  = nil }) -- Fuck it we ball
			end
		end
		if not IsValid(Origin) then return end
		Sounds.CreateMultipleAdjustableSounds(Origin, SoundTable)
	end)

	-- For updates on multiple sounds
	net.Receive("ACF_Sounds_Adjustable_Multi", function(len)
		print("Received " .. len .. " bits from \"ACF_Sounds_Adjustable_Multi\" for sound creation!") -- Debug print
		local Origin = net.ReadEntity()
		local ShouldStop = net.ReadBool()

		if not IsValid(Origin) then return end

		-- Do we really need to remove every existing sound when the engine just turns off?
		if ShouldStop then
			Sounds.DeleteMultipleAdjustableSounds(Origin)
		else
			local Throttle = net.ReadUInt(7)
			local RPM = net.ReadUInt(ACF.NetSoundRPMBitLimit)

			-- In case we don't just have the soundbank table yet, we do a request for it instead.
			if not Origin.SoundObjects or table.IsEmpty(Origin.SoundObjects) then
				RequestMultipleAdjustableSounds(Origin)
				return
			end

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