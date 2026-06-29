
local ACF       = ACF
local Lasers    = ACF.ActiveLasers
local Sources   = ACF.LaserSources
local TraceData = { start = true, endpos = true, filter = true }

local function GetVector(Entity, Data, Key, Default)
	local Value = Data[Key]

	if isvector(Value) then return Value end
	if not isstring(Value) then return Default end

	local EntValue = Entity[Value]

	return isvector(EntValue) and EntValue or Entity:GetNW2Vector(Value, Default)
end

local function GetLaserData(Entity, Data)
	local Offset = GetVector(Entity, Data, "Offset", Vector())
	local Direction = GetVector(Entity, Data, "Direction", Vector(1))
	local Origin = Entity:LocalToWorld(Offset)

	TraceData.start = Origin
	TraceData.endpos = Entity:LocalToWorld(Offset + Direction * 50000)
	TraceData.filter = Data.Filter

	local Result = ACF.trace(TraceData)
	Result.Distance = Result.Fraction * 50000

	return Origin, Result.HitPos, Result
end

local function UpdateLaserData(Entity, Laser)
	local Origin, HitPos, Result = GetLaserData(Entity, Sources[Entity])

	Laser.Distance = Result.Distance
	Laser.Origin = Origin
	Laser.HitPos = HitPos
	Laser.Trace = Result

	return Laser
end

local function LaserTick()
	for Entity, Laser in pairs(Lasers) do
		UpdateLaserData(Entity, Laser)
	end
end

local function RemoveLaserSource(Entity)
	if not IsValid(Entity) then return end

	Entity.IsLaserSource = nil

	Sources[Entity] = nil
	Lasers[Entity] = nil

	if not next(Sources) then
		hook.Remove("Tick", "ACF Active Lasers")
	end
end

ACF.RemoveLaserSource = RemoveLaserSource

function ACF.AddLaserSource(Entity, Data)
	if not IsValid(Entity) then return end
	if not istable(Data) then return end

	if not next(Sources) then
		hook.Add("Tick", "ACF Active Lasers", LaserTick)
	end

	local LaserData = {
		NetVar = Data.NetVar or "Lasing",
		Offset = Data.Offset or Vector(),
		Direction = Data.Direction or Vector(1),
		Filter = Data.Filter or { Entity },
	}

	Sources[Entity] = LaserData

	if Entity[LaserData.NetVar] or Entity:GetNW2Bool(LaserData.NetVar) then
		Lasers[Entity] = UpdateLaserData(Entity, {})
	end

	Entity.IsLaserSource = true

	Entity:CallOnRemove("ACF Active Laser", function()
		RemoveLaserSource(Entity)
	end)

	return LaserData
end

function ACF.GetLaserData(Entity)
	if not IsValid(Entity) then return end

	return Lasers[Entity]
end

hook.Add("EntityNetworkedVarChanged", "ACF Laser Toggle", function(Entity, Name, _, Value)
	local Data = Sources[Entity]

	if Data and Data.NetVar == Name then
		Lasers[Entity] = Value and UpdateLaserData(Entity, {}) or nil
	end
end)
