--[[
Most of the crew model specific properties and logic is specified here.
]]--

local ACF         = ACF
local AutoloaderTypes = ACF.Classes.AutoloaderTypes

-- IMoveable class
local IMoveable = ACF.SimpleClass()

function IMoveable:CalcWeight() return 0 end

-- Actuator subclass
local Actuator = ACF.InheritedClass(IMoveable)

Actuator.Length  = 0
Actuator.MaxMass = 0
Actuator.X       = 0
Actuator.Y       = 0

function Actuator:__new(Length, MaxMass, X, Y)
    self.Length  = Length
    self.MaxMass = MaxMass
    self.X       = X
    self.Y       = Y
end

function Actuator:CalcWeight()
    return self.Mass
end

-- Rotator subclass
local Rotator = ACF.InheritedClass(IMoveable)

Rotator.Length  = 0
Rotator.MaxMass = 0
Rotator.X       = 0
Rotator.Y       = 0

function Rotator:__new(Length, MaxMass, X, Y)
    self.Length  = Length
    self.MaxMass = MaxMass
    self.X       = X
    self.Y       = Y
end

function Rotator:CalcWeight()
    return self.Mass
end

-- testshittt
local instance = Actuator(5, 10, 20)
print(Actuator.Length) -- will be 5

print(instance.Y) -- will be 0; you didn't specify it
-- tl;dr if the instance doesn't have a value, it refers to its static class

AutoloaderTypes.Register("0J", {
    Name = "0 Joint",
    Description = "Involves no rotation joints, (e.g. T72/Leclerc)",
    CalcPath = function(X, Y, MaxMass)
        local components = {}
        table.insert(components, Actuator(Y, MaxMass, X, Y))
        table.insert(components, Actuator(X, MaxMass, X, Y))
        calcWeight(components)
        enforceTraces(components)
        return components
    end
})

AutoloaderTypes.Register("1J", {
    Name = "1 Joint",
    Description = "Involves one rotation joint, (e.g. TTB)",
})

AutoloaderTypes.Register("2J", {
    Name = "2 Joint",
    Description = "Involves two rotation joints, (e.g. Stryker)",
})