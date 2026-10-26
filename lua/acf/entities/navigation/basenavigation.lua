local Classes = ACF.Classes

-- Navigation laws turn the target's relative state into the acceleration the missile wants.
-- Subtypes implement GetAcceleration(Missile, TimeToHit, RelPos, RelVel, RelAcc); gravity compensation is added by the flight code.
Classes.DefineClass("ACF.Missiles.Navigation", function()

end)
