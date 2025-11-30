ACF.LoadToolFunctions(TOOL)

TOOL.Name = "#tool.acf_menu.menu_name"

if CLIENT then
	-- "Hitbox" colors
	local Sensitive      = Color(255, 0, 0, 50)
	local NotSoSensitive = Color(255, 255, 0, 50)

	net.Receive("ReqContraption", function()
		local Entity = net.ReadEntity()
		local Cost = math.Round(net.ReadFloat(8), 2)
		Entity.Cost = Cost
		print("Contraption Cost: ", Cost)
	end)

	function RenderContraption(Entity, Cost)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect( 100, 100, 400, 400 )

		surface.SetTextColor(255, 255, 255, 255)
		surface.SetTextPos( 300, 300 )
		surface.DrawText( "Contraption Cost: " .. tostring(Cost) )
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

		if Entity.Cost then RenderContraption(Entity, Entity.Cost) end

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
elseif SERVER then
	util.AddNetworkString( "ReqContraption" )

	net.Receive("ReqContraption", function(Len, Player)
		local Entity = net.ReadEntity()

		if not IsValid(Entity) then return end
		if not Entity.GetContraption then return end

		local Contraption = Entity:GetContraption()

		if not Contraption then return end

		net.Start("ReqContraption")
		net.WriteEntity(Entity)
		net.WriteFloat(Contraption.Cost or 0, 8)
		net.Send(Player)
	end)
end