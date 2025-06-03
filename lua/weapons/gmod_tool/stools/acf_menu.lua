ACF.LoadToolFunctions(TOOL)

TOOL.Name = "#tool.acf_menu.menu_name"

if CLIENT then
	-- "Hitbox" colors
	local Sensitive      = Color(255, 0, 0, 50)
	local NotSoSensitive = Color(255, 255, 0, 50)

	function TOOL:DrawHUD()
		local Trace = LocalPlayer():GetEyeTrace()
		local Distance = Trace.StartPos:DistToSqr(Trace.HitPos)
		local Entity = Trace.Entity

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