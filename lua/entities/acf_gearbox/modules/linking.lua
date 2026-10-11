local ACF            = ACF
local Mobility    	 = ACF.Mobility
local MobilityObj 	 = Mobility.Objects
local MaxDistance 	 = ACF.MobilityLinkDistance * ACF.MobilityLinkDistance
local IsEntityValid  = ACF.Optimizations.IsEntityValid

do -- Linking ------------------------------------------
	local function CheckLoopedGearbox(This, Target)
		local Queued = { [Target] = true }
		local Checked = {}
		local Entity

		while next(Queued) do
			Entity = next(Queued)

			if Entity == This then
				return true
			end

			Checked[Entity] = true
			Queued[Entity]  = nil

			for Gearbox in pairs(Entity.GearboxOut) do
				if not Checked[Gearbox] then
					Queued[Gearbox] = true
				end
			end
		end

		return false
	end

	local function GenerateLinkTable(Entity, Target)
		local InPos = Target.In and Target.In.Pos or Vector()
		local InPosWorld = Target:LocalToWorld(InPos)
		local OutPos, Side

		local Plane
		if Entity:WorldToLocal(InPosWorld).y < 0 then
			Plane = Entity.OutL
			OutPos = Entity.OutL.Pos
			Side = 0
		else
			Plane = Entity.OutR
			OutPos = Entity.OutR.Pos
			Side = 1
		end

		local OutPosWorld = Entity:LocalToWorld(OutPos)
		local Excessive, Angle = ACF.IsDriveshaftAngleExcessive(Target, Target.In, Entity, Plane)
		if Excessive then return nil, Angle end

		local Link	= MobilityObj.Link(Entity, Target)

		Link:SetOrigin(OutPos)
		Link:SetTargetPos(InPos)
		Link:SetAxis(Target.In and Plane.Dir or Target:GetPhysicsObject():WorldToLocalVector(Entity:GetRight()))
		Link.OutDirection = Plane.Dir
		Link.Side = Side
		Link.RopeLen = (OutPosWorld - InPosWorld):Length()

		return Link, Angle
	end

	local function LinkWheel(Gearbox, Wheel)
		if Gearbox.Wheels[Wheel] then return false, "This wheel is already linked to this gearbox!" end
		if Gearbox:GetPos():DistToSqr(Wheel:GetPos()) > MaxDistance then return false, "This wheel is too far away from this gearbox!" end

		local Link, DriveshaftAngle = GenerateLinkTable(Gearbox, Wheel)

		if not Link then return false, "Cannot link due to excessive driveshaft angle! (" .. math.Round(DriveshaftAngle) .. " deg)" end

		Link.LastVel   = 0
		Link.AntiSpazz = 0
		Link.IsBraking = false

		Gearbox.Wheels[Wheel] = Link
		if not Wheel.ACF_Gearboxes then Wheel.ACF_Gearboxes = {} end
		Wheel.ACF_Gearboxes[Gearbox] = Link

		Wheel:CallOnRemove("ACF_GearboxUnlink" .. Gearbox:EntIndex(), function()
			if IsEntityValid(Gearbox) then
				Gearbox:Unlink(Wheel)
			end
		end)

		Gearbox:InvalidateClientInfo()

		return true, "Wheel linked successfully!"
	end

	local function LinkGearbox(Gearbox, Target)
		if Gearbox.GearboxOut[Target] then return false, "These gearboxes are already linked to each other!" end
		if Target.GearboxIn[Gearbox] then return false, "These gearboxes are already linked to each other!" end
		if Gearbox:GetPos():DistToSqr(Target:GetPos()) > MaxDistance then return false, "These gearboxes are too far away from each other!" end
		if CheckLoopedGearbox(Gearbox, Target) then return false, "You cannot link gearboxes in a loop!" end

		local Link, DriveshaftAngle = GenerateLinkTable(Gearbox, Target)

		if not Link then return false, "Cannot link due to excessive driveshaft angle! (" .. math.Round(DriveshaftAngle) .. " deg)" end

		Gearbox.GearboxOut[Target] = Link
		Target.GearboxIn[Gearbox]  = true

		Gearbox:InvalidateClientInfo()

		return true, "Gearbox linked successfully!"
	end

	ACF.RegisterClassLink("acf_gearbox", "prop_physics", LinkWheel)
	ACF.RegisterClassLink("acf_gearbox", "acf_gearbox", LinkGearbox)
	ACF.RegisterClassLink("acf_gearbox", "tire", LinkWheel)
end ----------------------------------------------------

do -- Unlinking ----------------------------------------
	local function UnlinkWheel(Gearbox, Wheel)
		if Gearbox.Wheels[Wheel] then
			local Link = Gearbox.Wheels[Wheel]

			if IsValid(Link.Rope) then
				Link.Rope:Remove()
			end

			Gearbox.Wheels[Wheel] = nil

			Wheel:RemoveCallOnRemove("ACF_GearboxUnlink" .. Gearbox:EntIndex())

			Gearbox:InvalidateClientInfo()

			return true, "Wheel unlinked successfully!"
		end

		if Wheel.ACF_Gearboxes and Wheel.ACF_Gearboxes[Gearbox] then
			Wheel.ACF_Gearboxes[Gearbox] = nil
		end

		return false, "This wheel is not linked to this gearbox!"
	end

	local function UnlinkGearbox(Gearbox, Target)
		local GearboxToTarget = Gearbox.GearboxOut[Target] or Target.GearboxIn[Gearbox]
		local TargetToGearbox = Target.GearboxOut[Gearbox] or Gearbox.GearboxIn[Target]

		if GearboxToTarget or TargetToGearbox then
			local Link = Gearbox.GearboxOut[Target] or Target.GearboxOut[Gearbox]

			if IsValid(Link.Rope) then
				Link.Rope:Remove()
			end

			Gearbox.GearboxIn[Target]  = nil
			Gearbox.GearboxOut[Target] = nil
			Target.GearboxIn[Gearbox]  = nil
			Target.GearboxOut[Gearbox] = nil

			Gearbox:InvalidateClientInfo()

			return true, "Gearbox unlinked successfully!"
		end

		return false, "These gearboxes are not linked to each other!"
	end

	ACF.RegisterClassUnlink("acf_gearbox", "prop_physics", UnlinkWheel)
	ACF.RegisterClassUnlink("acf_gearbox", "acf_gearbox", UnlinkGearbox)
	ACF.RegisterClassUnlink("acf_gearbox", "tire", UnlinkWheel)
end ----------------------------------------------------