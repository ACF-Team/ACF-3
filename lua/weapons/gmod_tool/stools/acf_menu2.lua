TOOL.Name	  = "ACF Menu Test"
TOOL.Category = "Construction"

ACF.LoadToolFunctions(TOOL)

cleanup.Register("acfmenu")

if CLIENT then
	local DrawBoxes = GetConVar("acf_drawboxes")

	-- "Hitbox" colors
	local Sensitive      = Color(255, 0, 0, 50)
	local NotSoSensitive = Color(255, 255, 0, 50)

	language.Add("Tool.acf_menu2.name", "Armored Combat Framework")
	language.Add("Tool.acf_menu2.desc", "Testing the new menu tool")

	function TOOL:DrawHUD()
		local Trace = LocalPlayer():GetEyeTrace()
		local Distance = Trace.StartPos:DistToSqr(Trace.HitPos)
		local Entity = Trace.Entity

		cam.Start3D()
		render.SetColorMaterial()

		if DrawBoxes:GetBool() and IsValid(Entity) and Distance <= 65536 then
			hook.Run("ACF_DrawBoxes", Entity, Trace)
		end

		cam.End3D()
	end

	TOOL.BuildCPanel = ACF.BuildContextPanel

	concommand.Add("acf_reload_menu", function()
		if not IsValid(ACF.Menu) then return end

		ACF.BuildContextPanel(ACF.Menu.Panel)
	end)

	hook.Add("ACF_DrawBoxes", "ACF Draw Hitboxes", function(Entity)
		if not Entity.HitBoxes then return end
		if not next(Entity.HitBoxes) then return end

		for _, Tab in pairs(Entity.HitBoxes) do
			local Pos = Entity:LocalToWorld(Tab.Pos)
			local Ang = Entity:LocalToWorldAngles(Tab.Angle)

			render.DrawWireframeBox(Pos, Ang, Tab.Scale * -0.5, Tab.Scale * 0.5, Tab.Sensitive and Sensitive or NotSoSensitive)
		end
	end)
end
