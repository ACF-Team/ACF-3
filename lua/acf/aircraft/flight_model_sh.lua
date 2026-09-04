-- Pure flight-model math (no GMod dependencies) so it can be unit-tested under standalone luajit.
-- The GMod flight controller (entities/acf_baseplate/modules/flight.lua) consumes these; the vector
-- bookkeeping stays in the controller, the physical relationships live here.
--
-- Run the tests with:  luajit tests/flight_model_test.lua   (from the ACF-3 addon root)

local FlightModel = {}

FlightModel.Defaults = {
	Gravity     = 9.81,   -- m/s^2
	GLimit      = 8,      -- structural/physiological load-factor ceiling (caps how tight a turn can be)
	VMinTurn    = 20,     -- m/s floor so the turn-rate cap stays finite at low speed
	ClAlpha     = 0.09,   -- lift-coefficient slope per degree of angle of attack
	AoAStall    = 15,     -- deg; lift peaks here
	StallFall   = 1.4,    -- how fast lift collapses past the stall angle
	KpRate      = 3.0,    -- desired pitch/yaw rate (deg/s) per degree of pointing error
	KpRoll      = 4.0,    -- desired roll rate (deg/s) per degree of bank error
	RollRateMax = 120,    -- deg/s cap on roll rate (roll doesn't pull G, so it's its own cap)
	KRate       = 0.05,   -- (legacy) control-surface deflection per (deg/s) of rate error
	TorquePerRate = 1500, -- target control torque (Nm-ish) per deg/s of rate error; airspeed-independent
	LiftAssist    = 1.5,  -- degrees of extra nose-up aim per m/s of sink rate (auto-trim for lift)
	LiftAssistMax = 12,   -- cap on the auto-lift aim bias (kept below the stall angle)
	BankPerHeading = 2.5, -- degrees of commanded bank per degree of heading error (bank-to-turn)
	MaxBank       = 55,   -- maximum commanded bank angle (caps turn G: ~1/cos(55) = 1.7g)
	YawCoord      = 0.4,  -- rudder coordination gain: yaw rate per degree of sideslip
	TurnPullGain  = 1.2,  -- extra nose-up pitch demand (deg) per degree of heading error, while turning
	WingIncidence = 3.0,  -- deg of built-in rigging incidence: the wing makes lift at zero body pitch,
	                      -- so the craft can sustain level flight (and rotate off the ground) without
	                      -- having to hold a nose-up attitude first.
	AeroDamp      = 0.06, -- fraction of body angular rate bled off per tick as aerodynamic rate damping.
	                      -- Always opposes rotation, so it stabilises (kills the tick-rate jitter) without
	                      -- the self-oscillation the old per-surface omega x r feedback caused.

	-- Mouse-aim controller (the acf_control_surface_controller brain). No user-facing gains: the outer loop
	-- turns a pointing error into a target body rate; the inner loop's authority is normalised by airspeed
	-- (dynamic pressure), which is deterministic and can't diverge, so gains stay fixed and hands-off.
	AimRateGain = 2.0,    -- target body rate (deg/s) per degree of pointing error (outer P loop)
	AimRateMax  = 30,     -- cap on the commanded body rate (deg/s); kept feasible so it doesn't saturate
	TrackGain   = 6.0,    -- desired angular acceleration (deg/s^2) per deg/s of rate error (inner loop)
	SurfBankGain = 2.2,   -- commanded bank angle (deg) per degree of heading error: turn mainly by BANKING
	                      -- (the strong roll+pitch axes) rather than leaning on the usually-weak rudder
	SurfMaxBank  = 50,    -- cap on commanded bank angle (deg); AoA guard now prevents the over-bank spiral
	RollKp       = 2.0,   -- roll rate (deg/s) commanded per degree of bank-angle error (holds a bank)
	RollRateMaxCtl = 45,  -- cap on commanded roll rate (deg/s); gentle rolls stay coordinated so a reversal
	                      -- doesn't generate adverse yaw / coupling a weak rudder can't arrest (flat spin)
	RollUnloadRate = 50,  -- deg/s of commanded roll at which the nose-up pull is fully eased off, so the
	                      -- craft unloads through a roll/reversal instead of coupling into a departure
	StallGuardAoA  = 13,  -- deg; the controller will not pull the nose above this angle of attack (envelope
	                      -- protection) so the wing can't be stalled into a spin at the end of a hard turn
	AoAGuardGain   = 3.0, -- how hard the guard bleeds the allowed nose-up rate as AoA approaches the limit
	TurnVRef       = 55,  -- m/s at/above which the craft may use full bank + pull (energy protection)
	TurnVMin       = 22,  -- m/s toward which bank + nose-up pull are eased right off, so a sustained hard
	                      -- turn can't bleed all its airspeed and mush into a low-speed departure
	CmdSlew      = 10,    -- max change in a normalised axis command per second (anti-slam output limiter)
	-- Airspeed-normalised authority: B = effectiveness (angular accel per unit deflection). It scales with
	-- dynamic pressure (speed^2), so fast craft need little deflection and slow craft are sluggish -- correct,
	-- and smooth. Deterministic (no learning), so it cannot collapse and bang-bang the surfaces.
	EffRef     = 120,     -- effectiveness at the reference speed
	RefSpeed   = 60,      -- m/s at which effectiveness equals EffRef
	EffMin     = 70,      -- clamp floor: a low floor lets the loop gain (1/B) spike into overshoot on a
	                      -- weak/slow axis, so keep it high enough that the controller stays gentle there
	EffMax     = 3000,    -- clamp ceiling
	-- Legacy online-estimator knobs (kept for the pure EstimateEffectiveness helper + its tests; the live
	-- controller uses the deterministic airspeed law above).
	EffInit    = 120,
	EffAlpha   = 0.03,
	EffMinDefl = 0.05,
}

local function clamp(x, lo, hi)
	if x < lo then return lo end
	if x > hi then return hi end
	return x
end
FlightModel.Clamp = clamp

-- Lift coefficient vs angle of attack, with a post-stall collapse to zero.
function FlightModel.LiftCoefficient(aoaDeg, p)
	p = p or FlightModel.Defaults
	local mag = aoaDeg >= 0 and aoaDeg or -aoaDeg

	if mag <= p.AoAStall then
		return p.ClAlpha * aoaDeg
	end

	local sign = aoaDeg >= 0 and 1 or -1
	local peak = p.ClAlpha * p.AoAStall
	local fall = (mag - p.AoAStall) * p.ClAlpha * p.StallFall
	local v = peak - fall
	if v < 0 then v = 0 end
	return sign * v
end

-- Total nose-up pitch demand: track the target elevation, plus a "pull" that scales with how much heading
-- change is still needed. Banking only rolls the craft; the pull is what carries the nose around the turn.
function FlightModel.PitchPullDemand(elevErrDeg, headingErrDeg, turnPullGain)
	local h = headingErrDeg >= 0 and headingErrDeg or -headingErrDeg
	return elevErrDeg + turnPullGain * h
end

-- Auto-lift trim: how many degrees to nudge the aim upward given the current sink rate. Zero when climbing
-- or level, so it self-cancels in steady flight; capped below the stall angle.
function FlightModel.LiftAssistDeg(sinkRateMS, p)
	p = p or FlightModel.Defaults
	if sinkRateMS <= 0 then return 0 end
	return clamp(sinkRateMS * p.LiftAssist, 0, p.LiftAssistMax)
end

-- Effective wing angle of attack: the geometric AoA (airflow vs. the body) plus the built-in rigging
-- incidence, so the wing makes lift in level flight and the craft can actually take off.
function FlightModel.WingAoA(geometricAoADeg, p)
	p = p or FlightModel.Defaults
	return geometricAoADeg + p.WingIncidence
end

-- Aerodynamic rate damping: the fraction of a body angular rate to bleed off this tick. Applied as a
-- torque/angular-velocity reduction that OPPOSES the rotation, it is unconditionally stabilising (it can
-- only remove angular energy), so it damps the control loop's tick-rate jitter instead of feeding it.
function FlightModel.RateDamping(bodyRateDegS, p)
	p = p or FlightModel.Defaults
	return -p.AeroDamp * bodyRateDegS
end

-- Drag coefficient from the drag polar: parasitic (cd0) + induced (cl^2 / (pi*AR*e)).
function FlightModel.DragCoefficient(cl, aspectRatio, cd0, oswald)
	return cd0 + cl * cl / (math.pi * aspectRatio * oswald)
end

-- Maximum sustainable pitch/yaw (turn) rate in deg/s at a given airspeed, from the G limit.
-- omega = g * G / V (rad/s): it FALLS with speed, so a fast aircraft physically cannot snap its heading.
function FlightModel.MaxTurnRate(speedMS, p)
	p = p or FlightModel.Defaults
	local v = speedMS < p.VMinTurn and p.VMinTurn or speedMS
	return math.deg(p.Gravity * p.GLimit / v)
end

-- Bank angle (deg) for a coordinated turn at the given yaw rate: tan(phi) = V*omega/g.
function FlightModel.CoordinatedBankDeg(speedMS, turnRateDegS, p)
	p = p or FlightModel.Defaults
	return math.deg(math.atan(speedMS * math.rad(turnRateDegS) / p.Gravity))
end

-- Load factor (G) implied by turning at a given rate and speed (level-turn approximation): n = V*omega/g.
function FlightModel.LoadFactor(speedMS, turnRateDegS, p)
	p = p or FlightModel.Defaults
	return speedMS * math.rad(turnRateDegS) / p.Gravity
end

-- Desired body rate (deg/s) from an angle error, clamped to what's physically achievable.
function FlightModel.RateCommand(errorDeg, kp, maxRate)
	return clamp(kp * errorDeg, -maxRate, maxRate)
end

-- Control-surface deflection (-1..1) from the error between commanded and actual body rate.
function FlightModel.DeflectionFromRate(rateErrorDegS, kRate)
	return clamp(kRate * rateErrorDegS, -1, 1)
end

-- A control surface's lift coefficient given the airflow's angle to its chord (alphaFlow) plus the
-- commanded deflection. alphaFlow alone (deflection 0) makes an undeflected surface a stabilizing fin;
-- deflection adds effective camber. Runs through the stall curve so surfaces stall too.
function FlightModel.SurfaceLiftCoef(alphaFlowDeg, deflection, maxDeflectDeg, p)
	return FlightModel.LiftCoefficient(alphaFlowDeg + deflection * maxDeflectDeg, p)
end

-- Allocate a per-axis channel command (-1..1) onto one surface using its geometric effectiveness about
-- that axis (eff = (r x nLift) . axis). The surface takes the command's magnitude but the SIGN of its own
-- effectiveness -- so a surface mounted on the "wrong" side of the CoM is auto-corrected (still helps,
-- just with whatever moment arm it has), and aileron left/right differential falls out for free. A surface
-- with ~no effectiveness on its channel does nothing.
function FlightModel.AllocateDeflection(channelCmd, eff, deadzone)
	deadzone = deadzone or 1e-4
	if eff >= -deadzone and eff <= deadzone then return 0 end
	local s = eff > 0 and 1 or -1
	return clamp(channelCmd, -1, 1) * s
end

-- Airspeed-independent deflection: the deflection whose resulting torque (deflection * authority) is
-- proportional to the rate error with a FIXED gain, where authority = surfaceArea * dynamicPressure *
-- Q_SCALE. Dividing by the authority is the whole trick: at high speed the authority is huge, so the
-- deflection needed is small -> the loop can't saturate and slam full torque every tick (the stutter).
-- At low speed the authority is small, so it saturates and the aircraft is sluggish -- which is correct.
function FlightModel.RateDeflection(rateErrorDegS, authority, torquePerRate)
	if authority <= 0 then return 0 end
	return clamp(torquePerRate * rateErrorDegS / authority, -1, 1)
end

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local deg   = math.deg

-- Pointing error (deg) of an aim direction expressed by its component ALONG an axis and its component
-- to one SIDE: atan2(side, along). With the baseplate body frame, feeding (aim.fwd, aim.right) yields the
-- heading error and (aim.fwd, aim.up) yields the elevation error -- both directly in the body frame, so a
-- body-rate loop (pitch about right, yaw about up) drives them to zero at any roll angle. This is the pure,
-- roll-agnostic core of the War-Thunder aim decomposition.
function FlightModel.PointingError(alongComp, sideComp)
	return deg(atan2(sideComp, alongComp))
end

-- Bank-to-turn: the bank angle (deg) to command for a given heading error, so the craft rolls toward the
-- target and the pitch pull carries the nose around. Returns 0 at zero heading error (wings level).
function FlightModel.DesiredBank(headingErrDeg, p)
	p = p or FlightModel.Defaults
	return clamp(p.SurfBankGain * headingErrDeg, -p.SurfMaxBank, p.SurfMaxBank)
end

-- Online control-effectiveness estimate for one axis. B = |angular accel| produced per unit (-1..1)
-- deflection command. Learned live so the controller inverts the real airframe/airspeed with no user
-- gains: samples only when the deflection is meaningful, rejects wrong-sign noise, clamps out spikes, and
-- low-passes slowly so adaptation is stable. Returns the updated estimate.
function FlightModel.EstimateEffectiveness(prevB, angAccelDegS2, deflection, p)
	p = p or FlightModel.Defaults
	local mag = deflection >= 0 and deflection or -deflection
	-- No clean signal below EffMinDefl; and when SATURATED (near full deflection) we can't tell how much more
	-- authority there is, so learning there wrongly collapses the estimate to the floor and the loop gain
	-- spikes into bang-bang oscillation. Hold the estimate in both cases.
	if mag < p.EffMinDefl or mag > 0.95 then return prevB end

	local sample = angAccelDegS2 / deflection -- accel per unit deflection; sign should be positive
	if sample <= 0 then return prevB end       -- transient / wrong-sign: ignore rather than corrupt B
	sample = clamp(sample, p.EffMin, p.EffMax)

	return prevB + p.EffAlpha * (sample - prevB)
end

-- Deterministic control effectiveness from airspeed: authority scales with dynamic pressure (speed^2),
-- clamped to a sane band. This is what the live controller feeds AutoTuneDeflection as B -- smooth and
-- non-divergent, unlike the online estimator (which stays available for later, guarded refinement).
function FlightModel.AirspeedEffectiveness(speedMS, p)
	p = p or FlightModel.Defaults
	local ratio = speedMS / p.RefSpeed
	return clamp(p.EffRef * ratio * ratio, p.EffMin, p.EffMax)
end

-- The inner loop: the normalised (-1..1) deflection command whose expected angular acceleration
-- (TrackGain * rateError) matches the plant inverse 1/B. High B (fast/strong airframe) -> small deflection;
-- low B (sluggish) -> large deflection. Saturates cleanly at the surface limit so it can never wind up.
function FlightModel.AutoTuneDeflection(rateErrorDegS, B, p)
	p = p or FlightModel.Defaults
	if B < p.EffMin then B = p.EffMin end
	return clamp(p.TrackGain * rateErrorDegS / B, -1, 1)
end

if _G.ACF then _G.ACF.FlightModel = FlightModel end
return FlightModel
