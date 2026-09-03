-- Standalone unit tests for the pure flight model. No GMod required.
-- Run from the ACF-3 addon root:  luajit tests/flight_model_test.lua
-- Exits non-zero if any assertion fails.

local FM = dofile("lua/acf/aircraft/flight_model_sh.lua")
local P  = FM.Defaults

local pass, fail = 0, 0

local function ok(cond, msg)
	if cond then
		pass = pass + 1
	else
		fail = fail + 1
		io.write("  FAIL: " .. msg .. "\n")
	end
end

local function approx(a, b, tol)
	tol = tol or 1e-6
	return math.abs(a - b) <= tol
end

-- === Lift curve ===
ok(approx(FM.LiftCoefficient(0), 0), "lift is zero at 0 AoA")
ok(FM.LiftCoefficient(5) > 0, "lift positive at +5 AoA")
ok(approx(FM.LiftCoefficient(-5), -FM.LiftCoefficient(5)), "lift is symmetric about 0 AoA")
ok(FM.LiftCoefficient(5) < FM.LiftCoefficient(10), "lift rises with AoA before stall")

local peakCL = FM.LiftCoefficient(P.AoAStall)
ok(FM.LiftCoefficient(P.AoAStall + 5) < peakCL, "lift falls past the stall angle")
ok(approx(FM.LiftCoefficient(45), 0), "deep stall produces (near) zero lift")

-- === Turn-rate cap falls with speed (the 'no instant turn' property) ===
local slow = FM.MaxTurnRate(60)
local fast = FM.MaxTurnRate(300)
ok(fast < slow, "max turn rate is lower at high speed")

-- At high speed, one tick's heading change is small (this is what was broken: instant turns).
local dt = 1 / 66
ok(fast * dt < 1.0, "at 300 m/s the per-tick heading change is under 1 degree")

-- Turning exactly at the cap yields exactly the G limit (internal consistency of the two formulas).
ok(approx(FM.LoadFactor(200, FM.MaxTurnRate(200)), P.GLimit, 1e-6), "turning at the cap pulls exactly GLimit")

-- Rate command respects the cap.
ok(approx(FM.RateCommand(1000, P.KpRate, fast), fast), "rate command is clamped to the max turn rate")
ok(approx(FM.RateCommand(-1000, P.KpRate, fast), -fast), "rate command clamps symmetrically")
ok(approx(FM.RateCommand(2, P.KpRate, fast), P.KpRate * 2), "rate command is proportional below the cap")

-- === Coordinated bank ===
ok(approx(FM.CoordinatedBankDeg(100, 0), 0), "no bank when not turning")
ok(FM.CoordinatedBankDeg(100, 20) > 0, "positive turn rate banks positively")
ok(FM.CoordinatedBankDeg(200, 20) > FM.CoordinatedBankDeg(100, 20), "faster coordinated turn needs more bank")

-- === Deflection from rate ===
ok(approx(FM.DeflectionFromRate(1e6, P.KRate), 1), "deflection saturates at +1")
ok(approx(FM.DeflectionFromRate(-1e6, P.KRate), -1), "deflection saturates at -1")
ok(approx(FM.DeflectionFromRate(0, P.KRate), 0), "zero rate error means zero deflection")

-- === Airspeed-independent deflection (the stutter fix) ===
-- The applied torque is deflection * authority. For the SAME rate error, that torque must be (nearly) the
-- same at low and high speed -- otherwise the loop gain explodes with dynamic pressure and it bang-bangs.
local err       = 10 -- deg/s of rate error
local authLow   = 2 * (0.5 * 1.225 * 60 * 60) * 40   -- authority at 60 m/s
local authHigh  = 2 * (0.5 * 1.225 * 300 * 300) * 40 -- authority at 300 m/s
local torqueLow  = FM.RateDeflection(err, authLow, P.TorquePerRate) * authLow
local torqueHigh = FM.RateDeflection(err, authHigh, P.TorquePerRate) * authHigh
ok(approx(torqueLow, torqueHigh, 1), "applied torque per rate error is airspeed-independent")
ok(approx(torqueLow, P.TorquePerRate * err, 1), "applied torque equals TorquePerRate * rate error (unsaturated)")

-- At high speed the deflection needed for that error is tiny (cannot saturate -> no stutter).
ok(FM.RateDeflection(err, authHigh, P.TorquePerRate) < 0.05, "high-speed deflection stays far from saturation")
-- With no authority (no surfaces / zero airspeed) there is no deflection.
ok(approx(FM.RateDeflection(err, 0, P.TorquePerRate), 0), "zero authority yields zero deflection")

-- === Wing rigging incidence (so the craft makes lift level and can take off) ===
ok(FM.WingAoA(0) > 0, "level flight (0 geometric AoA) still gives a positive wing AoA")
ok(approx(FM.WingAoA(0), P.WingIncidence), "wing AoA at level equals the rigging incidence")
ok(FM.LiftCoefficient(FM.WingAoA(0)) > 0, "the craft makes lift in level flight (take-off is possible)")
ok(approx(FM.WingAoA(5) - FM.WingAoA(0), 5), "wing AoA tracks geometric AoA one-for-one")
ok(P.WingIncidence < P.AoAStall, "rigging incidence stays below the stall angle")

-- === Aerodynamic rate damping (the jitter fix: always opposes rotation) ===
ok(approx(FM.RateDamping(0), 0), "no damping when not rotating")
ok(FM.RateDamping(50) < 0, "positive body rate is damped negatively (opposes rotation)")
ok(FM.RateDamping(-50) > 0, "negative body rate is damped positively (opposes rotation)")
ok(math.abs(FM.RateDamping(100)) > math.abs(FM.RateDamping(50)), "faster rotation is damped harder")
ok(math.abs(FM.RateDamping(50)) < 50, "damping bleeds only a fraction of the rate per tick (stable)")

-- === Drag polar / glide ratio (so the craft glides with power off instead of dropping like a brick) ===
local cd0, e, AR = 0.025, 0.8, 7
ok(approx(FM.DragCoefficient(0, AR, cd0, e), cd0), "zero lift means only parasitic drag")
ok(FM.DragCoefficient(1.0, AR, cd0, e) > FM.DragCoefficient(0.5, AR, cd0, e), "induced drag rises with lift")

-- A representative cruise point should give a usable lift-to-drag ratio (glide ratio), not a brick.
local clCruise = 0.5
local ldRatio  = clCruise / FM.DragCoefficient(clCruise, AR, cd0, e)
ok(ldRatio > 8, "cruise lift-to-drag ratio is realistic (glides)")

-- === Auto-lift assist ===
ok(approx(FM.LiftAssistDeg(0), 0), "no lift assist when not sinking")
ok(approx(FM.LiftAssistDeg(-5), 0), "no lift assist while climbing")
ok(FM.LiftAssistDeg(3) > 0, "sinking adds nose-up aim bias")
ok(FM.LiftAssistDeg(1000) <= P.LiftAssistMax, "lift assist is capped below the stall angle")
ok(P.LiftAssistMax < P.AoAStall, "lift-assist cap stays under the stall angle")

-- === Turn pull (bank alone doesn't turn; you must pull) ===
ok(approx(FM.PitchPullDemand(0, 0, 0.6), 0), "no pull when on target")
ok(FM.PitchPullDemand(0, 30, 0.6) > 0, "heading error adds nose-up pull")
ok(approx(FM.PitchPullDemand(0, 30, 0.6), FM.PitchPullDemand(0, -30, 0.6)), "pull is symmetric in turn direction")
ok(FM.PitchPullDemand(0, 40, 0.6) > FM.PitchPullDemand(0, 20, 0.6), "more heading error means more pull")

-- === Surface lift coefficient (passive fin + deflection) ===
ok(approx(FM.SurfaceLiftCoef(0, 0, 25), 0), "undeflected surface aligned with flow makes no lift")
ok(FM.SurfaceLiftCoef(5, 0, 25) > 0, "undeflected surface at positive flow angle makes lift (fin/stabilizer)")
ok(FM.SurfaceLiftCoef(0, 0.5, 25) > 0, "deflection alone makes lift")
ok(FM.SurfaceLiftCoef(0, 1, 10) > FM.SurfaceLiftCoef(0, 0.5, 10), "more deflection makes more lift (pre-stall)")
ok(FM.SurfaceLiftCoef(0, 1, 25) < FM.SurfaceLiftCoef(0, 0.5, 25), "over-deflecting past the stall angle loses lift")
ok(approx(FM.SurfaceLiftCoef(0, -0.5, 10), -FM.SurfaceLiftCoef(0, 0.5, 10)), "deflection lift is symmetric")

-- === Deflection allocation (geometric sign correction) ===
ok(approx(FM.AllocateDeflection(1, 0), 0), "no effectiveness -> no deflection")
ok(approx(FM.AllocateDeflection(0.7, 3.0), 0.7), "positive effectiveness passes command through")
ok(approx(FM.AllocateDeflection(0.7, -3.0), -0.7), "negative effectiveness flips the deflection (auto-corrected)")
-- Two surfaces on opposite sides of centreline (opposite-sign roll effectiveness) deflect oppositely:
ok(FM.AllocateDeflection(0.5, 2.0) == -FM.AllocateDeflection(0.5, -2.0), "opposite sides -> aileron differential")

-- === Mouse-aim pointing error (roll-agnostic body-frame decomposition) ===
ok(approx(FM.PointingError(1, 0), 0), "aim straight ahead is zero pointing error")
ok(FM.PointingError(1, 0.5) > 0, "aim to the +side gives positive error")
ok(approx(FM.PointingError(1, 0.5), -FM.PointingError(1, -0.5)), "pointing error is symmetric in side")
ok(approx(FM.PointingError(0, 1), 90), "aim 90 deg to the side reads 90 deg error")
ok(FM.PointingError(-1, 0.1) > 90, "aim behind reads as a large (turn-around) error")

-- === Bank-to-turn desired bank ===
ok(approx(FM.DesiredBank(0), 0), "no heading error means wings level")
ok(FM.DesiredBank(10) > 0, "positive heading error banks positively")
ok(FM.DesiredBank(1000) <= P.SurfMaxBank, "commanded bank is capped")
ok(approx(FM.DesiredBank(5), -FM.DesiredBank(-5)), "bank command is symmetric")

-- === Online effectiveness estimator ===
ok(approx(FM.EstimateEffectiveness(100, 50, 0.01), 100), "tiny deflection carries no signal (estimate held)")
ok(FM.EstimateEffectiveness(100, 200, 0.5) > 100, "a sample above the estimate pulls it up")
ok(FM.EstimateEffectiveness(300, 50, 0.5) < 300, "a sample below the estimate pulls it down")
ok(approx(FM.EstimateEffectiveness(100, -80, 0.5), 100), "wrong-sign (accel opposes command) sample is rejected")
do
	-- Converges toward the true effectiveness of a plant that gives 300 deg/s^2 at full deflection.
	local B = P.EffInit
	for _ = 1, 500 do B = FM.EstimateEffectiveness(B, 300 * 0.8, 0.8) end
	ok(approx(B, 300, 5), "estimate converges to the plant's true effectiveness")
end
ok(FM.EstimateEffectiveness(100, 1e9, 1) <= P.EffMax, "runaway samples are clamped to EffMax")

-- === Airspeed-normalised authority (deterministic, non-divergent) ===
ok(approx(FM.AirspeedEffectiveness(P.RefSpeed), P.EffRef), "effectiveness equals EffRef at the reference speed")
ok(FM.AirspeedEffectiveness(P.RefSpeed * 2) > FM.AirspeedEffectiveness(P.RefSpeed), "authority grows with airspeed")
ok(FM.AirspeedEffectiveness(1e9) <= P.EffMax, "authority is clamped at high speed")
ok(FM.AirspeedEffectiveness(0) >= P.EffMin, "authority never falls below the floor (bounded deflection at rest)")
ok(FM.AirspeedEffectiveness(P.RefSpeed * 2) <= 4 * P.EffRef + 1, "authority scales with speed squared (quadrupling at 2x)")

-- === Auto-tuned inner deflection (plant inverse) ===
ok(approx(FM.AutoTuneDeflection(0, 200), 0), "no rate error means no deflection")
ok(FM.AutoTuneDeflection(10, 200) > 0, "positive rate error deflects positively")
ok(approx(FM.AutoTuneDeflection(10, 200), -FM.AutoTuneDeflection(-10, 200)), "deflection is symmetric")
ok(FM.AutoTuneDeflection(10, 1000) < FM.AutoTuneDeflection(10, 200), "a more effective airframe needs less deflection")
ok(approx(FM.AutoTuneDeflection(1e6, 200), 1), "large rate error saturates at +1")
ok(approx(FM.AutoTuneDeflection(-1e6, 200), -1), "large negative rate error saturates at -1")
-- Same rate error, same commanded angular accel regardless of how the deflection is split (plant inverse):
ok(approx(FM.AutoTuneDeflection(10, 200) * 200, P.TrackGain * 10, 1e-6), "commanded accel = TrackGain * rateError")

io.write(string.format("\nflight_model: %d passed, %d failed\n", pass, fail))
os.exit(fail == 0 and 0 or 1)
