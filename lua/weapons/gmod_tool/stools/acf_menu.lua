ACF.LoadToolFunctions(TOOL)

TOOL.Name = "ACF Menu"

if CLIENT then

	local NO_ANGLE = Angle()

	local function DrawCylinder(Pos, Ang, Scale, Col)
		local Points = math.max(math.ceil(math.max(Scale.y, Scale.z) * 1.5), 5)
		local R      = 360 / Points
		local T      = {}
		local B      = {}

		for I = 1, Points do
			local P = Vector(0.5, 0, 0.5)
				P:Rotate(Angle(0, 0, R * I))

			T[I] = LocalToWorld(P * Vector(Scale.x, Scale.y, Scale.y), NO_ANGLE, Pos, Ang)
			B[I] = LocalToWorld(P * Vector(-Scale.x, Scale.z, Scale.z), NO_ANGLE, Pos, Ang)
		end

		for I = 1, Points do
			local N = I % Points + 1

			render.DrawLine(T[I], T[N], Col)
			render.DrawLine(T[N], B[N], Color(Col.r, Col.g, Col.b, 50))
			render.DrawLine(B[I], B[N], Col)
		end
	end

	local DrawBoxes = GetConVar("acf_drawboxes")

	-- "Hitbox" colors
	local Sensitive      = Color(255, 0, 0, 255)
	local NotSoSensitive = Color(255, 255, 0, 255)

	language.Add("Tool.acf_menu.name", "Armored Combat Framework")
	language.Add("Tool.acf_menu.desc", "Main menu tool for the ACF addon")

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

	TOOL.BuildCPanel = ACF.CreateSpawnMenu

	concommand.Add("acf_reload_spawn_menu", function()
		if not IsValid(ACF.SpawnMenu) then return end

		ACF.CreateSpawnMenu(ACF.SpawnMenu.Panel)
	end)

	hook.Add("ACF_DrawBoxes", "ACF Draw Hitboxes", function(Entity)
		if not Entity.HitBoxes then return end
		if not next(Entity.HitBoxes) then return end

		for _, Tab in pairs(Entity.HitBoxes) do
			local Pos = Entity:LocalToWorld(Tab.Pos)
			local Ang = Entity:LocalToWorldAngles(Tab.Angle)

			if Tab.Cylinder then
				DrawCylinder(Pos, Ang, Tab.Scale, Tab.Sensitive and Sensitive or NotSoSensitive)
			else
				render.DrawWireframeBox(Pos, Ang, Tab.Scale * -0.5, Tab.Scale * 0.5, Tab.Sensitive and Sensitive or NotSoSensitive)
			end
		end
	end)
end
