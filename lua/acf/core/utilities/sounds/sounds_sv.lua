local Sounds = ACF.Utilities.Sounds

util.AddNetworkString("ACF_Sounds")
util.AddNetworkString("ACF_Sounds_Adjustable")
util.AddNetworkString("ACF_Sounds_AdjustableCreate")

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
	if not IsValid(Origin) then return end

	ShouldStop = ShouldStop or false
	local Time = CurTime()
	if not Origin.ACF then Origin.ACF = {} end
	Origin.ACF.SoundTimer = Origin.ACF.SoundTimer or Time

	-- Slowing down the rate of sending a bit
	if Origin.ACF.SoundTimer <= Time or ShouldStop then
		net.Start("ACF_Sounds_Adjustable", true)
			net.WriteEntity(Origin)
			net.WriteBool(ShouldStop)
		if not ShouldStop then
			net.WriteUInt(Pitch, 8)

			Volume = Volume * 100 -- Sending the approximate volume as an int to reduce message size
			net.WriteUInt(Volume, 8)
		end
		net.SendPAS(Origin:GetPos())
		Origin.ACF.SoundTimer = Time + 0.05
	end
end