-- Client-driven menu framework: installs the tool's click/ghost/holster behavior. There is no
-- server-side stage/operation machine anymore -- spawns and links go over the ACF_MenuCommit net layer.
if ACF.Menu and ACF.Menu.SetupTool then
	ACF.Menu.SetupTool(TOOL)
end

TOOL.Name = "#tool.acf_menu.menu_name"

TOOL.Information = {}

if CLIENT then
	-- "Hitbox" colors
	local Sensitive      = Color(255, 0, 0, 50)
	local NotSoSensitive = Color(255, 255, 0, 50)

	local AxisDefined = Color(0, 255, 0)
	local AxisAuto    = Color(80, 200, 255)
	local AxisOther   = Color(255, 255, 255, 60)
	local ArrowCount  = 3
	local ArrowArc    = math.rad(70)
	local ArrowSpeed  = math.rad(150)

	-- The axis a link would give this wheel, as the gearbox would apply it: the one in the player's facing
	-- when holding ALT, else the wheel's defined one, else the one snapped from the selected gearboxes
	local function GetLinkAxis(Wheel, Aim, Alt)
		local Sum, Right = Vector()

		for _, Box in ipairs(ACF.Menu.LinkGearboxes) do
			if IsValid(Box) then
				Sum   = Sum + Box:GetRight()
				Right = Right or Box:GetRight()
			end
		end

		if not Right then return end

		local Index, Stored, Defined = Wheel:GetNWInt("ACF_TorqueAxis", 0), Wheel:GetNWInt("ACF_TorqueSign", 1), true

		if Alt then
			Index, Stored = ACF.GetWheelAxis(Wheel, Aim)
		elseif Index == 0 then
			Index, Defined = ACF.GetWheelAxis(Wheel, Sum:IsZero() and Right or Sum), false
		end

		local Dir = Wheel:LocalToWorld(ACF.WheelAxes[Index]) - Wheel:GetPos()

		return Index, Dir * ACF.GetAxisSign(Dir, Right, Defined and Stored), Defined
	end

	-- Arrows circle Axis (right-handed), so it's passed as the negative of the link axis: the way the wheel turns driving forward
	local function DrawSpinArrows(Center, Radius, Axis, Tint)
		local Up = Axis:GetNormalized()
		local U  = Up:Cross(math.abs(Up.z) < 0.9 and vector_up or Vector(1, 0, 0)):GetNormalized()
		local V  = Up:Cross(U)
		local T  = CurTime() * ArrowSpeed

		for K = 1, ArrowCount do
			local Tail = T + (K - 1) * math.pi * 2 / ArrowCount
			local Last

			for I = 0, 8 do
				local Angle = Tail + ArrowArc * I / 8
				local Point = Center + (U * math.cos(Angle) + V * math.sin(Angle)) * Radius

				if Last then render.DrawBeam(Last, Point, 1.5, 0, 1, Tint) end

				Last = Point
			end

			local Head   = Tail + ArrowArc
			local Radial = U * math.cos(Head) + V * math.sin(Head)
			local Tip    = Center + Radial * Radius
			local Back   = (U * math.sin(Head) - V * math.cos(Head)) * Radius * 0.25

			for _, Side in ipairs({ Radial * Radius * 0.2, -Radial * Radius * 0.2, Up * Radius * 0.2, -Up * Radius * 0.2 }) do
				render.DrawBeam(Tip, Tip + Back + Side, 1.5, 0, 1, Tint)
			end
		end
	end

	local function DrawWheelAxis(Wheel, Aim, Alt)
		local Chosen, Dir, Defined = GetLinkAxis(Wheel, Aim, Alt)

		if not Chosen then return end

		local Center = Wheel:LocalToWorld(Wheel:OBBCenter())
		local Length = Wheel:BoundingRadius() * 1.3
		local Origin = Wheel:GetPos()
		local Tint   = Defined and AxisDefined or AxisAuto
		local Tip    = Center + Dir:GetNormalized() * Length

		cam.Start3D()
		render.SetColorMaterialIgnoreZ()

		for I, Local in ipairs(ACF.WheelAxes) do
			if I ~= Chosen then
				local Other = Wheel:LocalToWorld(Local) - Origin

				render.DrawLine(Center - Other * Length, Center + Other * Length, AxisOther, false)
			end
		end

		render.DrawBeam(Center - (Tip - Center), Tip, 1.5, 0, 1, Tint)
		render.DrawSphere(Tip, 4, 8, 8, Tint) -- The head marks the applied direction

		DrawSpinArrows(Center, Wheel:BoundingRadius() * 1.05, Dir * -1, Tint)

		cam.End3D()

		local Screen = Tip:ToScreen()

		if not Screen.visible then return end

		local Sign = Dir:Dot(Wheel:LocalToWorld(ACF.WheelAxes[Chosen]) - Origin) < 0 and "-" or "+"

		draw.SimpleTextOutlined(("Torque axis: %s%s (%s)"):format(Sign, ACF.WheelAxisName[Chosen], Defined and "defined" or "auto"), "GModToolHelp", Screen.x, Screen.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
	end

	function TOOL:DrawHUD()
		-- New framework's instruction HUD for the active new-style page (drawn before the entity
		-- overlay early-returns so it shows regardless of what you're aiming at). Swaps to the linking
		-- instruction set while the player has entities selected.
		if ACF.Menu and ACF.Menu.GetHUDInstructions then
			local Instructions = ACF.Menu.GetHUDInstructions()
			if Instructions then ACF.Menu.DrawInstructions(Instructions) end
		end

		local Trace = LocalPlayer():GetEyeTrace()
		local Distance = Trace.StartPos:DistToSqr(Trace.HitPos)
		local Entity = Trace.Entity

		-- Unlinking (R) doesn't use the axis, so there's nothing to preview then
		if next(ACF.Menu.LinkGearboxes) and not LocalPlayer():KeyDown(IN_RELOAD) and ACF.CanSetWheelAxis(Entity) then
			DrawWheelAxis(Entity, LocalPlayer():GetAimVector(), LocalPlayer():KeyDown(IN_WALK))
		end

		if not IsValid(Entity) then return end
		if not Entity.DrawOverlay then return end
		if Entity.CanDrawOverlay and not Entity:CanDrawOverlay() then return end

		if Distance <= 65536 then
			cam.Start3D()
			render.SetColorMaterial()

			Entity:DrawOverlay(Trace)

			cam.End3D()
		end
	end

	TOOL.BuildCPanel = ACF.CreateSpawnMenu

	hook.Add("ACF_OnDrawBoxes", "ACF Draw Hitboxes", function(Entity)
		if not Entity.HitBoxes then return end
		if not next(Entity.HitBoxes) then return end

		for _, Tab in pairs(Entity.HitBoxes) do
			local Pos = Entity:LocalToWorld(Tab.Pos)
			local Ang = Entity:LocalToWorldAngles(Tab.Angle)

			render.DrawWireframeBox(Pos, Ang, Tab.Scale * -0.5, Tab.Scale * 0.5, Tab.Sensitive and Sensitive or NotSoSensitive)
		end
	end)
end