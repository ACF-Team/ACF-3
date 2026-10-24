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

	-- Link view colors
	local Explicit = Color(0, 200, 255)
	local Implicit = Color(255, 170, 0)

	-- Draws a line from the entity to each entity linked to it, colored by whether the player or the system made the link
	local function DrawLinks(Entity)
		local Links = ACF.Menu.GetLinkView(Entity)

		if not Links then return end

		local Start = Entity:WorldSpaceCenter()

		cam.Start3D()
		render.SetColorMaterialIgnoreZ()

		for Linked, IsImplicit in pairs(Links) do
			if IsValid(Linked) then render.DrawBeam(Start, Linked:WorldSpaceCenter(), 1, 0, 1, IsImplicit and Implicit or Explicit) end
		end

		cam.End3D()

		-- Labels each line at its midpoint
		for Linked, IsImplicit in pairs(Links) do
			if not IsValid(Linked) then continue end

			local Screen = ((Start + Linked:WorldSpaceCenter()) * 0.5):ToScreen()
			local Label  = IsImplicit and "Implicit link" or "Explicit link"
			local Tint   = IsImplicit and Implicit or Explicit

			if Screen.visible then
				draw.SimpleTextOutlined(Label, "GModToolHelp", Screen.x, Screen.y, Tint, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			end
		end
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

		if not IsValid(Entity) then return end
		if LocalPlayer():KeyDown(IN_DUCK) then DrawLinks(Entity) end
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