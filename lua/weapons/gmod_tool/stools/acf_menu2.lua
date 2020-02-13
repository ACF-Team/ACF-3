TOOL.Name	  = "ACF Menu Test"
TOOL.Category = "Construction"

cleanup.Register("acfmenu")

if CLIENT then
	local DrawBoxes = CreateConVar("acf_drawboxes", 0, FCVAR_ARCHIVE, "Whether or not to draw hitboxes on ACF entities", 0, 1)

	language.Add("Tool.acf_menu2.name", "Armored Combat Framework")
	language.Add("Tool.acf_menu2.desc", "Testing the new menu tool")

	function TOOL:DrawHUD()
		if not DrawBoxes:GetBool() then return end

		local Ent = LocalPlayer():GetEyeTrace().Entity

		if not IsValid(Ent) then return end
		if not Ent.HitBoxes then return end

		cam.Start3D()
		render.SetColorMaterial()

		for _, Tab in pairs(Ent.HitBoxes) do
			local BoxColor = Tab.Sensitive and Color(214, 160, 190, 50) or Color(160, 190, 215, 50)

			render.DrawBox(Ent:LocalToWorld(Tab.Pos), Ent:LocalToWorldAngles(Tab.Angle), Tab.Scale * -0.5, Tab.Scale * 0.5, BoxColor)
		end

		cam.End3D()
	end

	function TOOL:LeftClick(Trace)
		return not Trace.HitSky
	end

	function TOOL:RightClick(Trace)
		return not Trace.HitSky
	end

	TOOL.BuildCPanel = ACF.BuildContextPanel

	concommand.Add("acf_reload_menu", function()
		if not IsValid(ACF.Menu) then return end

		ACF.BuildContextPanel(ACF.Menu.Panel)
	end)
else
	function TOOL:LeftClick(Trace)
		return not Trace.HitSky
	end

	function TOOL:RightClick(Trace)
		return not Trace.HitSky
	end
end
