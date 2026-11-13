local ACF           = ACF
local Missiles      = ACF.Missiles
local Ballistics    = ACF.Ballistics
local Clock         = ACF.Utilities.Clock
local Debug         = ACF.Debug
local TraceData     = { start = true, endpos = true, filter = true }
local GravityCvar   = GetConVar("sv_gravity")
local GravityVector = Vector(0, 0, -GravityCvar:GetFloat())

cvars.AddChangeCallback("sv_gravity", function(_, _, Value)
	GravityVector.z = -Value
end, "ACF Missile Gravity")

-- TODO: Missiles must base their movement off an ACF bullet
--- Advances a launched missile by one think: guidance, navigation, motor, aerodynamics and hit detection.
function Missiles.CalcFlight(Missile)
	if not Missile.Launched then return end
	if Missile.Detonated then return end

	local Time = Clock.CurTime
	local DeltaTime = Time - Missile.LastThink
	Missile.LastThink = Time

	if DeltaTime <= 0 then return end

	local Pos            = Missile.ACF_Position
	local Dir            = Missile.CurDir
	local LastVel        = Missile.LastVel
	local LastSpeed      = LastVel:Length()
	local LastSpeedSqr   = LastVel:LengthSqr()
	local VelNorm        = LastVel:GetNormalized()
	local LiftMultiplier = LastSpeedSqr * Missile.FinMultiplier / Missile.Mass -- Lift per sin(AoA)

	-- Torque from the back fins
	local Inertia = Missile.Inertia
	local Torque  = Dir:Cross(LastVel) * LastSpeed * Missile.TorqueMul

	--Guidance calculations
	local Guidance    = Missile.UseGuidance and Missile.GuidanceData:GetGuidance(Missile)
	local TargetPos   = Guidance and Guidance.TargetPos

	if TargetPos then
		-- Getting the relative position, velocity and acceleration
		local RelPos = TargetPos - Pos
		local RelVel = (RelPos - (Missile.LastRelPos or RelPos)) / DeltaTime
		local RelAcc = (RelVel - (Missile.LastRelVel or RelVel)) / DeltaTime
		-- Filtering the acceleration
		Missile.FilteredAcc = (Missile.FilteredAcc or RelAcc) * 0.8 + RelAcc * 0.2
		local Dist          = RelPos:Length()
		local RelSpd        = RelVel:Length()
		local TimeToHit     = math.min(Dist / RelSpd, 60)
		local PredSpeed     = RelSpd + Missile.Thrust / Missile.Mass * math.min(Missile.MotorLength, TimeToHit) * 0.5
		TimeToHit           = math.min(Dist / PredSpeed, 60)
		-- Navigation
		local Nav = Missile.NavigationData:GetAcceleration(Missile, TimeToHit, RelPos, RelVel, Missile.FilteredAcc) - GravityVector
		-- Making the acceleration perpendicular to the velocity and limiting it
		Nav = Nav - Nav:Dot(VelNorm) * VelNorm
		if Nav:Length() > Missile.GLimit then
			Nav = Nav:GetNormalized() * Missile.GLimit
		end
		-- Calculating the AoA (and subsequent direction) that produces the desired acceleration
		local TargetAoA = math.deg(math.asin(math.min(Nav:Length() / LiftMultiplier, 1)))
		local AoAAxis   = VelNorm:Cross(Nav):GetNormalized()
		local TargetAng = VelNorm:Angle()
		TargetAng:RotateAroundAxis(AoAAxis, TargetAoA)
		local TargetDir = TargetAng:Forward()
		-- Turning the missile to the target direction
		local Agility   = Missile.Agility * math.min(1, Missile.ControlSurfMul * LastSpeedSqr) / Inertia
		local Axis      = Dir:Cross(TargetDir):GetNormalized()
		local AngDiff   = math.deg(math.acos(math.Clamp(TargetDir:Dot(Dir), -1, 1)))
		Missile.RotAxis = Axis * math.min(Agility, AngDiff / DeltaTime)

		Missile.LastRelPos = RelPos
		Missile.LastRelVel = RelVel
	end

	Missile.RotAxis = Missile.RotAxis + Torque / Inertia * DeltaTime
	local DirAng  = Dir:Angle()
	DirAng:RotateAroundAxis(Missile.RotAxis:GetNormalized(), Missile.RotAxis:Length() * DeltaTime)
	Dir = DirAng:Forward()
	Missile.RotAxis = Missile.RotAxis * (1 - 0.7 * DeltaTime)

	local FuelMod = Missiles.UpdateMotor(Missile, DeltaTime)

	local Thrust    = Dir * FuelMod * Missile.Thrust / Missile.Mass
	local Up        = Dir:Cross(LastVel):Cross(Dir):GetNormalized()
	local DotSimple = Up.x * VelNorm.x + Up.y * VelNorm.y + Up.z * VelNorm.z
	local Lift      = -Up * DotSimple * LiftMultiplier

	local Drag      = LastVel * (Missile.DragCoef * LastSpeed) / ACF.DragDiv * ACF.Scale / Missile.Mass
	local Vel       = LastVel + (GravityVector + Thrust + Lift - Drag) * DeltaTime
	local EndPos    = Pos + Vel * DeltaTime

	Missile.ACF_Velocity = Vel

	--Hit detection
	TraceData.start = Pos
	TraceData.endpos = EndPos
	TraceData.filter = Missile.Filter

	local Result = ACF.trace(TraceData)

	-- Skip entities ballistics ignores, so ghosted props do not stop missiles
	while Result.Hit and not Result.HitWorld and not Ballistics.TestFilter(Result.Entity, Missile) do
		Missile.Filter[#Missile.Filter + 1] = Result.Entity
		Result = ACF.trace(TraceData)
	end

	local Ghosted = Time < Missile.GhostPeriod
	local GhostHit = Ghosted and Result.HitWorld
	local HitSky   = Result.HitSky

	-- If hitting the sky, continue so they can leave the map.
	if Missile.InSky and not Result.HitWorld and Pos[3] < Missile.InSky then
		Missile.InSky = nil
	end

	if not Missile.InSky and Result.Hit and (GhostHit or not Ghosted) then
		if HitSky then
			Missile.InSky = Result.HitPos[3]
			-- ^^ This is the Z component. We will not exit the sky until we go lower than this.
			-- The reason this matters is in case we hit the sky but then there's a skybox right above the sky, etc.
			-- So only exit sky-ignoring when we cross the same boundary we crossed entering it
		else
			Missile.HitNormal = Result.HitNormal
			Missile.Disabled = GhostHit

			Missile:DoFlight(Result.HitPos)
			Missile:Detonate()
			return
		end
	end

	if Missile.FuzeData:GetDetonate(Missile, Missile.GuidanceData) then
		Missile:Detonate()

		return
	end

	Missile.LastVel = Vel
	Missile.LastPos = Pos
	Missile.ACF_Position = EndPos
	Missile.CurDir = Dir

	--Missile trajectory debugging
	if Debug.SetDeveloperLevel(3) then
		Debug.SetTarget(Missile:CPPIGetOwner())
		Debug.Line(Pos, EndPos, 10, Color(0, 255, 0))
	end

	Missile:DoFlight()
end
