local Network    = ACF.Networking

-- "Grainy" datatypes
-- These are basically less-accurate vectors and angles for non-critical things like debris positions.

local round     = math.Round
local pow       = math.pow
local maxSUEdge = pow(2, 14)

local function UnitsToGrain(Value, Base, Grain)
    Value = ((Value / Base) + 1) / 2
    Value = Value * (pow(2, Grain) - 1)
    return round(Value)
end

local function GrainToUnits(Value, Base, Grain)
    Value = Value / (pow(2, Grain) - 1)
    Value = (Value - 0.5) * Base * 2
    return round(Value)
end

function Network.ReadGrainyVector(Grain, Base)
    assert(isnumber(Grain), "expected vector in argument #1")

    local X = GrainToUnits(net.ReadUInt(Grain), Base or maxSUEdge, Grain)
    local Y = GrainToUnits(net.ReadUInt(Grain), Base or maxSUEdge, Grain)
    local Z = GrainToUnits(net.ReadUInt(Grain), Base or maxSUEdge, Grain)

    return Vector(X, Y, Z)
end

function Network.ReadGrainyAngle(Grain, Base)
    assert(isnumber(Grain), "expected number in argument #1")

    local X = GrainToUnits(net.ReadUInt(Grain), Base or maxSUEdge, Grain)
    local Y = GrainToUnits(net.ReadUInt(Grain), Base or maxSUEdge, Grain)
    local Z = GrainToUnits(net.ReadUInt(Grain), Base or maxSUEdge, Grain)

    return Angle(X, Y, Z)
end

function Network.WriteGrainyVector(Vector, Grain, Base)
    assert(isvector(Vector), "expected vector in argument #1")
    assert(isnumber(Grain), "expected number in argument #2")

    local X = UnitsToGrain(Vector[1], Base or maxSUEdge, Grain)
    local Y = UnitsToGrain(Vector[2], Base or maxSUEdge, Grain)
    local Z = UnitsToGrain(Vector[3], Base or maxSUEdge, Grain)

    net.WriteUInt(X, Grain)
    net.WriteUInt(Y, Grain)
    net.WriteUInt(Z, Grain)
end

function Network.WriteGrainyAngle(Angle, Grain, Base)
    assert(isangle(Angle), "expected angle in argument #1")
    assert(isnumber(Grain), "expected number in argument #2")

    local X = UnitsToGrain(Angle[1], Base or maxSUEdge, Grain)
    local Y = UnitsToGrain(Angle[2], Base or maxSUEdge, Grain)
    local Z = UnitsToGrain(Angle[3], Base or maxSUEdge, Grain)

    net.WriteUInt(X, Grain)
    net.WriteUInt(Y, Grain)
    net.WriteUInt(Z, Grain)
end