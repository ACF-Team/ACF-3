local Sounds = ACF.Utilities.Sounds

util.AddNetworkString("ACF_Sounds")
util.AddNetworkString("ACF_Sounds_Adjustable")
util.AddNetworkString("ACF_Sounds_AdjustableCreate")
util.AddNetworkString("ACF_Sounds_Adjustable_Multi")
util.AddNetworkString("ACF_Sounds_AdjustableCreate_Multi")
util.AddNetworkString("ACF_Sounds_AdjustableRequest_Multi")
util.AddNetworkString("ACF_Sounds_InvalidateEngineSoundInfo")

	--- Sends a single, non-looping sound to all clients in the PAS.
	--- @param Origin table | vector The source to play the sound from
	--- @param Path string The path to the sound to be played local to the game's sound folder
	--- @param Level? integer The sound's level/attenuation from 0-127
	--- @param Pitch? integer The sound's pitch from 0-255
	--- @param Volume number A float representing the sound's volume. This is internally converted into an integer from 0-255 for network optimization
function Sounds.SendSound(Origin, Path, Level, Pitch, Volume)
	if not IsValid(Origin) then return end

	local IsEnt = isentity(Origin)
	local Pos

	-- Set default Gmod level/pitch values if not present
	Level = Level or 75
	Pitch = Pitch or 100

	net.Start("ACF_Sounds")
		net.WriteBool(IsEnt)
	if IsEnt then
		net.WriteEntity(Origin)
		Pos = Origin:GetPos()
	else
		net.WriteVector(Origin)
		Pos = Origin
	end
		net.WriteString(Path)
		net.WriteUInt(Level, 7)
		net.WriteUInt(Pitch, 8)
		net.WriteUInt(Volume * 100, 8)
	net.SendPAS(Pos)
end

do -- Single, adjustable sounds
		--- Creates a sound patch on all clients in the PAS.  
		--- This is intended to be used for self-looping sounds played on an entity that can be adjusted easily later.  
		--- This allows us to modify the pitch/volume of a looping sound (ex. engines) with minimal network usage.
		--- @param Origin table The entity to play the sound from
		--- @param Path string The path to the sound to be played local to the game's sound folder
		--- @param Pitch integer The sound's pitch from 0-255
		--- @param Volume number A float representing the sound's volume
	function Sounds.CreateAdjustableSound(Origin, Path, Pitch, Volume)
		if not IsValid(Origin) then return end

		net.Start("ACF_Sounds_AdjustableCreate")
			net.WriteEntity(Origin)
			net.WriteString(Path)
			net.WriteUInt(Pitch, 8)
			net.WriteFloat(Volume)
		net.SendPAS(Origin:GetPos())
	end

		--- Sends an update to an adjustable sound to all clients in the PAS.  
		--- If the adjustable sound was stopped on the client, it will begin playing again on the origin with the given parameters.  
		--- This function is ratelimited to reduce network consumption, and subsequent updates will be smoothed on the client with an equivalent delta time.
		--- @param Origin table The entity to update the sound on
		--- @param ShouldStop? boolean Whether the sound should be destroyed; defaults to false
		--- @param Pitch integer The sound's pitch from 0-255
		--- @param Volume number A float representing the sound's volume. This is internally converted into an integer from 0-255 for network optimization
	function Sounds.SendAdjustableSound(Origin, ShouldStop, Pitch, Volume)
		ShouldStop = ShouldStop or false

		local Time = CurTime()
		local OriginTbl = Origin.ACF

		if not OriginTbl then
			OriginTbl = {}
			Origin.ACF = OriginTbl
		end
		OriginTbl.SoundTimer = OriginTbl.SoundTimer or Time

		-- Slowing down the rate of sending a bit
		if OriginTbl.SoundTimer <= Time or ShouldStop then
			net.Start("ACF_Sounds_Adjustable", true)
				net.WriteEntity(Origin)
				net.WriteBool(ShouldStop)
			if not ShouldStop then
				net.WriteUInt(Pitch, 8)

				Volume = Volume * 100 -- Sending the approximate volume as an int to reduce message size
				net.WriteUInt(Volume, 8)
			end
			net.SendPAS(Origin:GetPos())
			OriginTbl.SoundTimer = Time + 0.05
		end
	end
end

do -- Multiple, Interpolated sounds
	local function WriteSoundTableAsPayload(Origin, SoundTable)
		local _BIT_NUM_SOUNDBANKS = ACF.GetHighestPowerOfTwo(ACF.MaxSoundBanks)
		local _BIT_NUM_SOUNDS = ACF.GetHighestPowerOfTwo(ACF.MaxSounds)

		net.WriteEntity(Origin)
		net.WriteEntity(Origin.Exhaust)

		local SoundBankCount = #Origin.SoundBanks
		net.WriteUInt(SoundBankCount, _BIT_NUM_SOUNDBANKS)

		-- Separate our table in chunks to be sent instead of all at once
		-- This saves about 40% in data size vs. sending the whole table
		for _, Bank in ipairs(SoundTable) do
			net.WriteBool(Bank.PlaysAtExhaust or false)

			local OffThrottle = (Bank.OffThrottle or 0.25) * 100 -- Sending the approximate value as an int to reduce message size
			local OnThrottle = (Bank.OnThrottle or 1) * 100
			local SoundCount = #Bank.Sounds

			net.WriteUInt(OffThrottle, 8)
			net.WriteUInt(OnThrottle, 8)
			net.WriteUInt(SoundCount, _BIT_NUM_SOUNDS)

			for _, V in ipairs(Bank.Sounds) do
				local RPM = V.RPM
				local StringPath = V.Path
				local Pitch = V.Pitch
				local Volume = V.Volume
				local Width = V.Width

				net.WriteUInt(RPM, ACF.NetSoundRPMBitLimit)
				net.WriteString(StringPath)
				net.WriteUInt(Pitch, 8)

				Volume = Volume * 100 -- Sending the approximate volume as an int to reduce message size
				net.WriteUInt(Volume, 8)
				net.WriteUInt(Width or 0, 4)
			end
		end
	end

		--- Creates multiple, interpolated sounds to be broadcasted to all players within PAS.
		--- This allows us to then create multiple sounds attached to a single entity(the engine) or its extension(the exhaust), and be played fully clientside.
		--- An entity can have multiple soundbanks but only one soundbank can be played at an entity.
		--- This should only be called once upon soundtable creation OR when a soundtable has changed, and has to be broadcasted to any clients within PAS.
		--- A client that does not have the soundtable (e.g: late PAS joiners), will instead request such table on demand. (See below)
		--- @param Origin table The entity to play the sound from
		--- @param SoundTable table The table whose keys are arbitrary RPM's and values containing a table with a sound path, pitch and volume, to be played at a defined RPM(Its keys).
	function Sounds.CreateMultipleAdjustableSounds(Origin, SoundTable)
		if not IsValid(Origin) then return end
		if not istable(SoundTable) then return end

		net.Start("ACF_Sounds_AdjustableCreate_Multi")
			WriteSoundTableAsPayload(Origin, SoundTable)
		net.SendPAS(Origin:GetPos())
	end

		--- Just like the above function except it sends the full soundbank creation payload to a single client, 
		--- as response to any clients that don't have entity's soundbank cached yet and are requesting it.
		--- @param Ply Player The player requesting the data
		--- @param Origin table The entity whose soundbank is being requested
	function Sounds.SendMultipleAdjustableSoundsTo(Ply, Origin)
		if not IsValid(Ply) then return end
		if not IsValid(Origin) then return end
		if not istable(Origin.SoundBanks) then return end

		net.Start("ACF_Sounds_AdjustableCreate_Multi")
			WriteSoundTableAsPayload(Origin, Origin.SoundBanks)
		net.Send(Ply)
	end

	net.Receive("ACF_Sounds_AdjustableRequest_Multi", function(_, Ply)
		local Origin = net.ReadEntity()

		Sounds.SendMultipleAdjustableSoundsTo(Ply, Origin)
	end)

		--- Sends an update to any clients within PAS regarding Throttle, RPM and if it should stop the sound, from an engine.
		--- This also allows us to modify the pitch/volume of multiple looping sounds (for an engine) with minimal network usage.
		--- The sound calculations are performed entirely clientside and require net unreliable for better sound composition.
		--- This function is also rate limited to reduce network consumption, and subsequent updates will be smoothed on the client with an equivalent delta time. 
		--- @param Origin table The entity to update the sound from
		--- @param ShouldStop? boolean Whether the sound should be destroyed; defaults to false
		--- @param Throttle int The entity's throttle
		--- @param RPM int The entity's RPM
	function Sounds.SendMultipleAdjustableSounds(Origin, ShouldStop, Throttle, RPM)
		if not IsValid(Origin) then return end
		ShouldStop = ShouldStop or false

		local Time = CurTime()
		local OriginTbl = Origin.ACF

		if not OriginTbl then
			OriginTbl = {}
			Origin.ACF = OriginTbl
		end
		OriginTbl.SoundTimer = OriginTbl.SoundTimer or Time

		-- Slowing down the rate of sending a bit
		if OriginTbl.SoundTimer <= Time or ShouldStop then
			net.Start("ACF_Sounds_Adjustable_Multi", true)
				net.WriteEntity(Origin)
				net.WriteBool(ShouldStop)
			if not ShouldStop then
				net.WriteUInt(Throttle or 0, 7)
				net.WriteUInt(RPM or 0, ACF.NetSoundRPMBitLimit) -- Theorically there are engines capable of reaching more than 16K RPM. If you do so, you can go off yourself...
			end
			net.SendPAS(Origin:GetPos())
			OriginTbl.SoundTimer = Time + 0.05
		end
	end

	-- Sends an update to the client, invalidating current sound entity playback and force a sound removal, in case the exhaust has exceeded its distance limit. 
	function Sounds.InvalidateSoundInfo(Origin)
		if not IsValid(Origin) then return end

		net.Start("ACF_Sounds_InvalidateEngineSoundInfo")
			net.WriteEntity(Origin)
		net.Broadcast()
	end
end