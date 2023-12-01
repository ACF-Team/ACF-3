local Sounds = ACF.Utilities.Sounds

util.AddNetworkString("ACF_Sounds")
util.AddNetworkString("ACF_Sounds_Adjustable")
util.AddNetworkString("ACF_Sounds_AdjustableCreate")

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
		net.WriteFloat(Volume)
	net.SendPAS(Pos)
end

function Sounds.CreateAdjustableSound(Origin, Path, Pitch, Volume)
	if not IsValid(Origin) then return end

	net.Start("ACF_Sounds_AdjustableCreate")
		net.WriteEntity(Origin)
		net.WriteString(Path)
		net.WriteUInt(Pitch, 8)
		net.WriteFloat(Volume)
	net.SendPAS(Origin:GetPos())
end

function Sounds.SendAdjustableSound(Origin, ShouldStop, Pitch, Volume)
	if not IsValid(Origin) then return end

	ShouldStop = ShouldStop or false

	net.Start("ACF_Sounds_Adjustable")
		net.WriteEntity(Origin)
		net.WriteBool(ShouldStop)
	if not ShouldStop then
		net.WriteUInt(Pitch, 8)
		net.WriteFloat(Volume)
	end
	net.SendPAS(Origin:GetPos())
end