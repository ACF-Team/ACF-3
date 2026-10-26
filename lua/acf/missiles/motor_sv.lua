local ACF      = ACF
local Missiles = ACF.Missiles
local Sounds   = ACF.Utilities.Sounds

--- Sets up the motor's burn time and starting boost from the missile's round and propellant.
function Missiles.InitMotor(Missile)
	local Round = Missile.RoundDef

	if Missile.NoThrust then
		Missile.MotorLength = 0
		Missile.SpeedBoost  = 0
	else
		local TotalLength = Missile.PropMass / (Missile.FuelConsumption * Missile.MaxThrust)

		Missile.MaxMotorLength = TotalLength
		Missile.MotorLength    = (1 - Missile.StarterPercent) * TotalLength
		Missile.SpeedBoost     = Missile.StarterPercent * TotalLength * Missile.MaxThrust / (Missile.ProjMass + Missile.PropMass * 0.5)
	end

	Missile.BulletData.MuzzleVel = ACF.MissileMuzzleVel(Missile.NoThrust, Round, Missile.ProjMass, Missile.PropMass)
end

function Missiles.SetMotorState(Missile, Enabled)
	if Missile.MotorEnabled == Enabled then return end

	if Enabled then
		if Missile.NoThrust then return end
		if Missile.Detonated then return end

		Missile.Thrust = Missile.MaxThrust
		Missile:SetNW2Float("LightSize", Missile.BulletData.Caliber)

		Sounds.SendSound(Missile, Missile.Sound, 180, math.random(99, 101), 1)

		if Missile.Effect then
			timer.Simple(0, function()
				if not IsValid(Missile) then return end
				if not Missile.MotorEnabled then return end

				ParticleEffectAttach(Missile.Effect, PATTACH_POINT_FOLLOW, Missile, Missile:LookupAttachment("exhaust") or 0)
			end)
		end
	else
		Missile.Thrust = 0
		Missile:StopParticles()
		Missile:SetNW2Float("LightSize", 0)
	end

	Missile.MotorEnabled = Enabled
end

--- Burns fuel for DeltaTime, updating mass and inertia. Returns the fraction of DeltaTime the motor was burning.
function Missiles.UpdateMotor(Missile, DeltaTime)
	local FuelMod = math.Clamp(Missile.MotorLength / DeltaTime, 0, 1)

	if Missile.MotorEnabled then
		if Missile.MotorLength <= 0 then
			Missiles.SetMotorState(Missile, false)
		else
			Missile.MotorLength = math.max(Missile.MotorLength - DeltaTime, 0)

			-- Update the missile's mass and inertia according to the remaining fuel
			Missile.Mass    = Missile.ProjMass + Missile.PropMass * Missile.MotorLength / Missile.MaxMotorLength
			Missile.Inertia = Missile.AreaOfInertia * Missile.Mass
		end
	end

	return FuelMod
end
