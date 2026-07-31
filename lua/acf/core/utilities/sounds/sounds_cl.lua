local Sounds = ACF.Utilities.Sounds
local Clock  = ACF.Utilities.Clock

local Clamp = math.Clamp
local max   = math.max

do -- Doppler effect
	local LocalPlayer = LocalPlayer
	local IsValid = IsValid

	local SpeedOfSound = ACF.SpeedOfSound
	local MinimumDenominator = SpeedOfSound * 0.1 -- Floor for the denominator below, so an extreme closing speed can't blow the ratio up towards infinity or flip its sign

	-- Lets store our last entity positions in this weak table so whenever the entity that had its data stored gets removed, does so from this table too.
	local LastPosition = setmetatable({}, {__mode = "k"})

	-- Given the fact that Ent:GetPos() is a method of ENTITY but Ent:GetVelocity() is a method of PHYSOBJ, simply calling the previous function wont work
	-- for parented entities(they don't have any physobj's) so instead we have to manually calculate the velocity of our sound source. 
	local function GetVelocity(Ent, Pos)
		local Time = Clock.CurTime
		local Last = LastPosition[Ent]

		if Last and Last.Time == Time then return Last.Velocity end

		local Velocity = vector_origin

		if Last then
			local DeltaTime = Time - Last.Time
			if DeltaTime > 0 then
				Velocity = (Pos - Last.Pos) / DeltaTime

				-- In the case that a teleport (spawning, respawning, prop repositioning) happens, 
				-- it'd cause a naughty one tick velocity spike, so lets prevent that. 
				if Velocity:Length() > SpeedOfSound * 2 then
					Velocity = vector_origin
				end
			end
		end

		LastPosition[Ent] = {Pos = Pos, Time = Time, Velocity = Velocity}

		return Velocity
	end

	--- Computes a pitch multiplier representing the Doppler shift caused by Origin's motion relative to the local player.
	--- @param Origin table The entity the sound is actually playing from
	--- @return number A multiplier to apply to the sound's base pitch
	function Sounds.GetDopplerPitchMultiplier(Origin)
		local Ply = LocalPlayer()
		if not IsValid(Ply) or not IsValid(Origin) then return 1 end

		local PlayerPos = Ply:EyePos()
		local SourcePos = Origin:GetPos()

		local Dir = SourcePos - PlayerPos
		local Dist = Dir:Length()
		if Dist < 1 then return 1 end  -- Right on top of the source

		Dir = Dir / Dist

		local RelativeVelocity = GetVelocity(Origin, SourcePos) - GetVelocity(Ply, PlayerPos)
		local VelocityTowardsPlayer = -RelativeVelocity:Dot(Dir)

		local Denominator = max(SpeedOfSound - VelocityTowardsPlayer, MinimumDenominator)
		-- Sanity clamp so a sudden teleport/velocity spike, can't send the pitch to an absurd extreme for a tick
		local Factor = Clamp(SpeedOfSound / Denominator, 0.5, 2)

		return Factor
	end
end

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
		Pitch  = Clamp(Pitch * Sounds.GetDopplerPitchMultiplier(Origin), 1, 255) -- Doppler effect

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

-- Fade function taken from:
-- https://dsp.stackexchange.com/questions/37477/understanding-equal-power-crossfades
-- https://dsp.stackexchange.com/questions/14754/equal-power-crossfade
function Sounds.Fade(N, Min, Mid, Max)
	local cos = math.cos
	local _PI = math.pi

	if N < Min or N > Max then return 0 end

	if N > Mid then
		Min = Mid - (Max - Mid)
	end

	return cos((1 - ((N - Min) / (Mid - Min))) * (_PI / 2))
end

-- This is where the magic to interpolate sounds happen.
-- In order to make yourself a better idea of what this does you can consult the image below:
-- https://i.imgur.com/KaFmaMf.png
local function DoPitchVolumeAtRPM(Origin, Throttle, RPM)
	local Fade  = Sounds.Fade -- idk if this is faster to do, but given this is a hot path, might as well be...
	local Remap = math.Remap
	local abs   = math.abs

	local SoundObjects = Origin.SoundObjects
	if not SoundObjects or table.IsEmpty(SoundObjects) then return end

	for _, SoundBank in ipairs(SoundObjects) do
		local Entity = SoundBank.PlayAtEntity
		if not IsValid(Entity) then Entity = Origin end

		local OffVolume = SoundBank.OffThrottle
		local OnVolume = SoundBank.OnThrottle
		local SoundCount = #SoundBank.Sounds

		for Idx, SoundTable in ipairs(SoundBank.Sounds) do
			if not SoundTable.RPM then continue end

			local AddCurveWidth = SoundTable.Width or 0
			local EnginePitch = SoundTable.Pitch or 1
			local Min    = Idx == 1 and -1000000 or SoundBank.Sounds[Clamp(Idx - 1 - AddCurveWidth, 1, SoundCount)].RPM
			local Mid    = SoundTable.RPM
			local Max    = Idx == SoundCount and 1000000 or SoundBank.Sounds[Clamp(Idx + 1 + AddCurveWidth, 1, SoundCount)].RPM
			local Curve  = Fade(RPM, Min, Mid, Max)
			local Volume = Curve * Remap(Throttle, 0, 100, OffVolume, OnVolume) * (SoundTable.Volume or 1)
			local Pitch  = (RPM / SoundTable.RPM) * EnginePitch
			local LastPitch  = SoundTable.LastPitch
			local LastVolume = SoundTable.LastVolume

			-- Don't even bother updating if neither value has changed meaningfully since the last update
			if LastPitch and LastVolume and abs(Pitch - LastPitch) < 0.5 and abs(Volume - LastVolume) < 0.01 then
				continue -- Yeah...
			end

			SoundTable.LastPitch = Pitch
			SoundTable.LastVolume = Volume

			Entity.Sound = SoundTable.Sound

			Sounds.UpdateAdjustableSound(Entity, Pitch, Volume)
		end
	end
end

do -- Multiple Engine Sounds(ex. Interpolated sounds)
	local IsValid = IsValid
	local Messages = ACF.Utilities.Messages

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

	-- Create the sound adjustable by pitch and volume. It is created mute so it remains ready to be manipulated later.
	local function CreateSound(Entity, Path, Pitch)
		local Sound = Sounds.CreateAdjustableSound(Entity, Path, Pitch or 100, 0)

		if not Sound then return end
		return Sound
	end

	--- Creates many sounds from a table, and stores their entries in the Origin's entity.
	--- Reuses existing methods to create and update sounds.
	--- @param Origin table The entity to play the sounds from
	--- @param SoundTable table The networked table with nested table containing rpm, sound path, pitch, volume, width and empty sound
	function Sounds.CreateMultipleAdjustableSounds(Origin, SoundTable)
		local SoundTable       = SoundTable
		local SoundBankErrored = 0
		local SoundBankCount   = 0
		local SoundCount       = 0

		for BankIdx, SoundBankTable in ipairs(SoundTable) do
			local Entity = SoundBankTable.PlayAtEntity
			if not IsValid(Entity) then continue end -- Just in case

			local HasErrored = false

			for _, SndTable in ipairs(SoundBankTable.Sounds) do
				if not HasErrored then
					local Sound = CreateSound(Entity, SndTable.Path, SndTable.Pitch)

					-- Invalidate the entire soundbank at the very first error
					if not Sound then
						SoundBankErrored = SoundBankErrored + 1
						HasErrored = true
						continue
					end

					SoundCount = SoundCount + 1
					SndTable.Sound = Sound
				end
			end

			-- If an error happened, clear this soundtable and instead create a default sound.
			-- TODO: We should be networking the default sound table instead!
			if HasErrored then
				SoundTable[BankIdx].Sounds = {}

				local Sound = CreateSound(Entity, "vehicles/junker/jnk_fourth_cruise_loop2.wav", 100)

				SoundTable[BankIdx].Sounds = {{
					RPM = 5000,
					Path = "vehicles/junker/jnk_fourth_cruise_loop2.wav",
					Pitch = 100,
					Volume = 1,
					Width = 0,
					Sound = Sound
				}}

				SoundCount = SoundCount + 1
			end
			-- Sort the table by the rpm before moving on, so it can be iterated in sequential order
			table.sort(SoundBankTable.Sounds, function(a, b) return a.RPM < b.RPM end)

			SoundBankCount = SoundBankCount + 1
		end

		if #SoundTable == SoundBankCount and SoundBankErrored ~= 0 then
			local Message = SoundBankErrored ~= 1 and tostring(SoundBankErrored .. " sound banks") or tostring(SoundBankErrored .. "sound bank")
			Messages.PrintChat("Error", ("Failed to create sounds for %s, at %s. Resetting to default sound."):format(Message, Origin))
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
				-- Check if it exists first, clients that failed to create the sound wont have the sound object, so nothing occurs. 
				if Snd.Sound then
					Snd.Sound:Stop()
				end
			end
			Origin.SoundObjects[Idx] = nil
		end
		Origin.SoundCount 	  = 0
		Origin.SoundBankCount = 0
	end

	local _BIT_NUM_SOUNDBANKS = ACF.GetHighestPowerOfTwo(ACF.MaxSoundBanks)
	local _BIT_NUM_SOUNDS = ACF.GetHighestPowerOfTwo(ACF.MaxSounds)
	-- For multiple sounds creation
	net.Receive("ACF_Sounds_AdjustableCreate_Multi", function()
		-- print("Received " .. len .. " bits from \"ACF_Sounds_AdjustableCreate_Multi\" for sound creation!") -- Debug print
		local Origin = net.ReadEntity()
		local Exhaust = net.ReadEntity()
		local SoundBankCount = net.ReadUInt(_BIT_NUM_SOUNDBANKS)

		local SoundTable = {}

		for Bank = 1, SoundBankCount do
			local PlaysAtExhaust = net.ReadBool()
			local OffThrottle = net.ReadUInt(8)
			local OnThrottle = net.ReadUInt(8)
			local SoundCount = net.ReadUInt(_BIT_NUM_SOUNDS)

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
	net.Receive("ACF_Sounds_Adjustable_Multi", function()
		-- print("Received " .. len .. " bits from \"ACF_Sounds_Adjustable_Multi\" for sound creation!") -- Debug print
		local Origin = net.ReadEntity()
		local ShouldStop = net.ReadBool()

		if not IsValid(Origin) then return end

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