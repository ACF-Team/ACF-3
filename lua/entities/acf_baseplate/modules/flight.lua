-- Airframe aerodynamics (the wing). Control is handled separately: each acf_control_surface is its own
-- Fin-3-style aero body, and an acf_control_surface_controller aims the airframe by driving those surfaces.
--
-- Each tick, for a baseplate whose type is flagged IsAircraft, this applies the shape-derived wing lift +
-- drag. A sampler (jittered timer) also computes the contraption's Centre of Mass / Centre of Lift / wing
-- area, networked for the build-time visualiser. Pure math + tuning constants live in ACF.FlightModel
-- (lua/acf/aircraft/flight_model_sh.lua), unit-tested under luajit. The wing lift carries the MassRatio
-- correction (parented mass is invisible to the solver).

local ACF     = ACF
local ENTITY  = FindMetaTable("Entity")
local PHYSOBJ = FindMetaTable("PhysObj")
local Clamp   = math.Clamp
local deg     = math.deg
local atan2   = math.atan2
local abs     = math.abs
local huge    = math.huge
local max     = math.max

local INCH_TO_M   = ACF.InchToMeter or 0.0254
local INCH_TO_M2  = INCH_TO_M * INCH_TO_M
local AIR_DENSITY = 1.225

-- === Aerodynamic tuning (airframe wing only; control surfaces are their own entities now) ===
local CD0          = 0.025   -- airframe parasitic drag coefficient (on wing area)
local OSWALD       = 0.8     -- Oswald efficiency for induced drag
local AR_MIN       = 4       -- clamp geometry-derived aspect ratio
local AR_MAX       = 10
local BROADSIDE_CD = 1.1     -- drag for the non-forward (belly/side-on) cross-section
local LIFT_FILL    = 0.4     -- fraction of the bounding planform acting as wing
local MIN_FLOW     = 2       -- m/s below which the airframe makes negligible force

--==============================================================================================--
-- Sampler: contraption shape (areas), Centre of Mass and Centre of Lift, on a jittered timer.
--==============================================================================================--
local function ComputeAeroData(BP)
	if not IsValid(BP) then return end

	local Con = ENTITY.CFW_GetContraption(BP)
	if not Con or not Con.ents then return end

	local minX, minY, minZ = huge, huge, huge
	local maxX, maxY, maxZ = -huge, -huge, -huge
	local Found = false

	local sumM, comX, comY, comZ = 0, 0, 0, 0          -- mass-weighted (CoM)
	local sumA, colX, colY, colZ = 0, 0, 0, 0          -- planform-area-weighted (CoL)
	local mxx, myy, mzz          = 0, 0, 0             -- second mass moments (for the inertia tensor)

	for Ent in pairs(Con.ents) do
		if not IsValid(Ent) then continue end

		local mins, maxs = Ent:OBBMins(), Ent:OBBMaxs()
		if mins == maxs then continue end

		for i = 0, 7 do
			local Corner = Vector(
				bit.band(i, 1) == 0 and mins.x or maxs.x,
				bit.band(i, 2) == 0 and mins.y or maxs.y,
				bit.band(i, 4) == 0 and mins.z or maxs.z)

			local L = BP:WorldToLocal(Ent:LocalToWorld(Corner))
			if L.x < minX then minX = L.x end
			if L.y < minY then minY = L.y end
			if L.z < minZ then minZ = L.z end
			if L.x > maxX then maxX = L.x end
			if L.y > maxY then maxY = L.y end
			if L.z > maxZ then maxZ = L.z end
			Found = true
		end

		-- Centre of lift: weight each member's centre by its top-down (planform) footprint.
		local Center = BP:WorldToLocal(Ent:LocalToWorld((mins + maxs) * 0.5))
		local Foot    = abs(maxs.x - mins.x) * abs(maxs.y - mins.y)
		sumA = sumA + Foot
		colX = colX + Center.x * Foot
		colY = colY + Center.y * Foot
		colZ = colZ + Center.z * Foot

		-- Centre of mass, physical members only. Use the ENTITY transform, not Phys:GetPos(): a parented
		-- member's physics object does not follow its parent, so Phys:GetPos() is stale (pinned in world) and
		-- makes the CoM sit at a fixed world point. GetMassCenter() is entity-LOCAL, so LocalToWorld it via
		-- the entity (which tracks parenting) to get the true world mass centre, then to baseplate-local.
		local Phys = Ent:GetPhysicsObject()
		if IsValid(Phys) then
			local m = Phys:GetMass()
			local c = BP:WorldToLocal(Ent:LocalToWorld(Phys:GetMassCenter()))
			sumM = sumM + m
			comX = comX + c.x * m
			comY = comY + c.y * m
			comZ = comZ + c.z * m
			mxx  = mxx + c.x * c.x * m
			myy  = myy + c.y * c.y * m
			mzz  = mzz + c.z * c.z * m
		end
	end

	if not Found then return end

	local dx, dy, dz = maxX - minX, maxY - minY, maxZ - minZ
	BP.AeroAreas = {
		Planform = dx * dy * INCH_TO_M2,
		Side     = dx * dz * INCH_TO_M2,
		Span     = dy * INCH_TO_M,
		Chord    = dx * INCH_TO_M,
	}

	BP.CoL = sumA > 0 and Vector(colX / sumA, colY / sumA, colZ / sumA) or vector_origin
	BP.CoM = sumM > 0 and Vector(comX / sumM, comY / sumM, comZ / sumM) or vector_origin

	-- Static margin as a fraction of chord: (CoL behind CoM) is positive = stable. Networked for the HUD.
	local Chord = dx ~= 0 and dx or 1
	BP:SetNW2Vector("ACF_CoM", BP.CoM)
	BP:SetNW2Vector("ACF_CoL", BP.CoL)
	BP:SetNW2Float("ACF_StaticMargin", (BP.CoM.x - BP.CoL.x) / Chord)
	BP:SetNW2Bool("ACF_HasAero", true)

	-- Rotational inertia fix. Parented mass is invisible to the solver, so a parented aircraft rotates with
	-- only the baseplate's (thin-plate) inertia -> any control moment spins it. MassRatio corrects LINEAR
	-- accel but nothing corrects rotation. Rebuild the true contraption inertia (about the baseplate physics
	-- centre, from Sum m*r^2) and set it on the physobj. Since every applied moment is force*MassRatio,
	-- setting I = I_real*MassRatio makes angular accel = torque/I_real (correct) -- the rotational analogue of
	-- the linear MassRatio trick. Only for heavily-parented craft (welded builds already have real inertia).
	local BPPhys = ENTITY.GetPhysicsObject(BP)
	if IsValid(BPPhys) and sumM > 0 then
		local Total     = Con.totalMass or sumM
		local MassRatio = Clamp(BPPhys:GetMass() / Total, 0, 1)

		if MassRatio < 0.9 then
			-- Second moments about the physobj centre (parallel-axis shift from the origin the sums used).
			-- The sums are in kg*in^2 (positions are source units); SetInertia wants kg*m^2, so convert by
			-- INCH_TO_M2 (in^2 -> m^2 = /39.37^2). Missing this made the inertia ~1550x too large -> it could
			-- barely rotate at all.
			local P = BPPhys:GetMassCenter()
			local Ixx = ((myy + mzz) - 2 * (P.y * comY + P.z * comZ) + (P.y * P.y + P.z * P.z) * sumM)
			local Iyy = ((mxx + mzz) - 2 * (P.x * comX + P.z * comZ) + (P.x * P.x + P.z * P.z) * sumM)
			local Izz = ((mxx + myy) - 2 * (P.x * comX + P.y * comY) + (P.x * P.x + P.y * P.y) * sumM)

			-- I = I_real * MassRatio: every applied moment already carries MassRatio, so this yields angular
			-- acceleration = torque/I_real (the rotational analogue of the linear MassRatio trick).
			BPPhys:SetInertia(Vector(
				max(Ixx * MassRatio, 0.5) / Total,
				max(Iyy * MassRatio, 0.5) / Total,
				max(Izz * MassRatio, 0.5) / Total))
		end
	end
end

--==============================================================================================--
-- Airframe aerodynamics: shape-derived lift + drag, applied at the Centre of Lift.
--==============================================================================================--
local function ApplyAirframeAero(BP, Phys, Fwd, Right, Up, MassRatio)
	local Areas = BP.AeroAreas
	if not Areas then return end

	local FM    = ACF.FlightModel
	local VelMS = PHYSOBJ.GetVelocity(Phys) * INCH_TO_M
	local Speed = VelMS:Length()
	if Speed < MIN_FLOW then return end

	local Vhat = VelMS / Speed
	local Q    = 0.5 * AIR_DENSITY * Speed * Speed
	local Wing = Areas.Planform

	-- Geometric AoA (airflow vs. body) plus the wing's built-in rigging incidence, so the craft makes
	-- lift in level flight and can rotate off the ground without first holding a nose-up attitude.
	local AoA = FM.WingAoA(deg(atan2(-VelMS:Dot(Up), abs(VelMS:Dot(Fwd)) + 1e-3)))
	local CL  = FM.LiftCoefficient(AoA)

	local LiftDir = Up - Up:Dot(Vhat) * Vhat
	if LiftDir:LengthSqr() > 1e-6 then LiftDir:Normalize() else LiftDir:Zero() end
	local Lift = Q * Wing * LIFT_FILL * CL

	local AR = Clamp((Areas.Span * Areas.Span) / max(Wing, 0.01), AR_MIN, AR_MAX)
	local CD = FM.DragCoefficient(CL, AR, CD0, OSWALD)
	local DragAligned   = Q * Wing * CD
	local DragBroadside = Q * (Wing * abs(Up:Dot(Vhat)) + Areas.Side * abs(Right:Dot(Vhat))) * BROADSIDE_CD

	-- Applied at the mass centre for now (stable/proven). Pitch stability comes from the passive control
	-- surfaces (a tail elevator behind the CoM self-corrects). Re-enable lift-at-CoL once the surface layer
	-- is confirmed stable in-game -- the CoM/CoL visualiser already surfaces the margin either way.
	local Force = LiftDir * Lift - Vhat * (DragAligned + DragBroadside)
	PHYSOBJ.ApplyForceCenter(Phys, Force * MassRatio)
end

--==============================================================================================--
-- Per-tick airframe processing: run the shape sampler (for the visualiser) and apply the wing aero.
--==============================================================================================--
local function ProcessAircraft(BP, BPTbl)
	local Phys = ENTITY.GetPhysicsObject(BP)
	if not IsValid(Phys) then return end

	-- Start the shape/CoM/CoL sampler regardless of freeze or pickup, so the visualiser and airframe data
	-- are ready while you're still building on the ground.
	if not BPTbl.AeroStarted then
		BPTbl.AeroStarted = true
		ComputeAeroData(BP)
		ACF.AugmentedTimer(function() ComputeAeroData(BP) end, function() return IsValid(BP) end, nil, {MinTime = 0.5, MaxTime = 1.5})
	end

	-- No forces while frozen or physgun-held.
	if not PHYSOBJ.IsMotionEnabled(Phys) then return end
	local Contraption = ENTITY.CFW_GetContraption(BP)
	if Contraption and Contraption.IsPickedUp then return end

	local Speed      = PHYSOBJ.GetVelocity(Phys):Length() * INCH_TO_M
	local RoundSpeed = math.Round(Speed, 1)
	if BPTbl.LastAirspeed ~= RoundSpeed then
		BPTbl.LastAirspeed = RoundSpeed
		WireLib.TriggerOutput(BP, "Airspeed", RoundSpeed)
	end

	local Fwd, Right, Up = ENTITY.GetForward(BP), ENTITY.GetRight(BP), ENTITY.GetUp(BP)

	local PhysMass  = PHYSOBJ.GetMass(Phys)
	local TotalMass = Contraption and Contraption.totalMass or PhysMass
	local MassRatio = Clamp(PhysMass / TotalMass, 0, 1)

	-- The wing: shape-derived lift/drag. A wing always makes lift when moving (no "active" flag). Control
	-- surfaces apply their own forces from their own entities; the controller aims the craft via them.
	ApplyAirframeAero(BP, Phys, Fwd, Right, Up, MassRatio)
end

hook.Add("Think", "ACF_Aircraft_FlightControl", function()
	local Array = ACF.ActiveBaseplatesArray
	if not Array then return end

	for i = 1, #Array do
		local BP = Array[i]
		if not IsValid(BP) then continue end

		local BPType = BP:ACF_GetUserVar("BaseplateType")
		if not BPType or not BPType.IsAircraft then continue end

		ProcessAircraft(BP, ENTITY.GetTable(BP))
	end
end)
