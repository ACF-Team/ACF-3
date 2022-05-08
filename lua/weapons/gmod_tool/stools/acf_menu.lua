ACF.LoadToolFunctions(TOOL)

TOOL.Name = "ACF Menu"

if CLIENT then
	local DrawBoxes = GetConVar("acf_drawboxes")

	-- "Hitbox" colors
	local Sensitive      = Color(255, 0, 0, 50)
	local NotSoSensitive = Color(255, 255, 0, 50)

	language.Add("Tool.acf_menu.name", "Armored Combat Framework")
	language.Add("Tool.acf_menu.desc", "Main menu tool for the ACF addon")

	function TOOL:DrawHUD()
		local Trace = LocalPlayer():GetEyeTrace()
		local Distance = Trace.StartPos:DistToSqr(Trace.HitPos)
		local Entity = Trace.Entity

		cam.Start3D()
		render.SetColorMaterial()

		if IsValid(Entity) and Distance <= 65536 then
			if Entity:GetClass() == "acf_ammo" and DrawBoxes:GetBool() then hook.Run("ACF_DrawFunc", Entity, Trace) -- Ammo boxes have a special cvar to turn this off entirely
			else hook.Run("ACF_DrawFunc", Entity, Trace) end
		end

		cam.End3D()
	end

	TOOL.BuildCPanel = ACF.CreateSpawnMenu

	concommand.Add("acf_reload_spawn_menu", function()
		if not IsValid(ACF.SpawnMenu) then return end

		ACF.CreateSpawnMenu(ACF.SpawnMenu.Panel)
	end)

	hook.Add("ACF_DrawFunc", "ACF Draw Hitboxes", function(Entity)
		if not Entity.HitBoxes then return end
		if not next(Entity.HitBoxes) then return end

		for _, Tab in pairs(Entity.HitBoxes) do
			local Pos = Entity:LocalToWorld(Tab.Pos)
			local Ang = Entity:LocalToWorldAngles(Tab.Angle)

			render.DrawWireframeBox(Pos, Ang, Tab.Scale * -0.5, Tab.Scale * 0.5, Tab.Sensitive and Sensitive or NotSoSensitive)
		end
	end)
end
