ACF.LoadToolFunctions(TOOL)

TOOL.Name = "#tool.acf_menu.menu_name"

if CLIENT then
	-- "Hitbox" colors
	local Sensitive      = Color(255, 0, 0, 50)
	local NotSoSensitive = Color(255, 255, 0, 50)

	function RenderContraption(Entity)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect( 100, 200, 400, 400 )

		surface.SetTextColor(255, 255, 255, 255)
		surface.SetFont("DermaLarge")
		surface.SetTextPos( 110, 210 )
		surface.DrawText("Baseplate: " .. tostring(Entity.BaseplateType))
		surface.SetTextPos( 110, 240 )
		surface.DrawText("Name: " .. tostring(Entity.Name))
		surface.SetTextPos( 110, 270 )
		surface.DrawText("Cost: " .. tostring(Entity.Cost))
		surface.SetTextPos( 110, 300 )
		surface.DrawText("Entity Count: " .. tostring(Entity.Count))
		surface.SetTextPos( 110, 330 )
		surface.DrawText("Total Mass: " .. tostring(Entity.TotalMass) .. " kg")
		surface.SetTextPos( 110, 360 )
		surface.DrawText("Max Pen: " .. tostring(Entity.MaxPen) .. " mm")
		surface.SetTextPos( 110, 390 )
		surface.DrawText("Max Nominal: " .. tostring(Entity.MaxNominal) .. " mm")
	end

	function TOOL:DrawHUD()
		local Trace = LocalPlayer():GetEyeTrace()
		local Distance = Trace.StartPos:DistToSqr(Trace.HitPos)
		local Entity = Trace.Entity

		if not IsValid(Entity) then self.LastEntity = nil return end

		if self.LastEntity ~= Entity then
			net.Start("ReqContraption")
			net.WriteEntity(Entity)
			net.SendToServer()
			self.LastEntity = Entity
		end

		if Entity.Cost then RenderContraption(Entity) end

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