local ACF = ACF
local IsValid = IsValid

TOOL.Category   = (ACF and ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction"
TOOL.Name       = "#tool.acfmeshdebug.name"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Information = {
	{ name = "info", stage = 0 },
}

local Alpha = 50

if CLIENT then
	language.Add("tool.acfmeshdebug.name", "ACF Mesh Debugger")
	language.Add("tool.acfmeshdebug.desc", "Visualizes the convex decomposition of an ACF volumetric mesh")
	language.Add("tool.acfmeshdebug.info", "Look at a volumetric mesh entity to see its convexes and the index of the one under your crosshair")

	function TOOL:LeftClick(_) return true end
	function TOOL:RightClick(_) return true end
	function TOOL:Reload(_) return true end

	TOOL.BuildCPanel = function() end

	-- Draws every convex of the mesh as a translucent quad, tinted by index, with the one under the crosshair highlighted.
	-- Runs every frame instead of using debugoverlay so the visualization doesn't flicker.
	local function DrawConvexes(Entity, HighlightID)
		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then return end

		local Verts = MeshData.Verts

		render.SetColorMaterial()

		for Index, Convex in ipairs(MeshData.Convexes) do
			local IsHighlighted = Index == HighlightID
			local Col = HSVToColor((Index * 47) % 360, 1, 1)
			Col.a = IsHighlighted and 120 or Alpha

			for _, Tri in ipairs(Convex.Tris) do
				local A = Entity:LocalToWorld(Verts[Tri[1]])
				local B = Entity:LocalToWorld(Verts[Tri[2]])
				local C = Entity:LocalToWorld(Verts[Tri[3]])

				render.DrawQuad(A, B, C, C, Col)
			end
		end
	end

	-- Returns the entity under the crosshair if the mesh debug tool is active and it has a volumetric mesh.
	local function GetMeshTraceTarget()
		local Player = LocalPlayer()
		local Weapon = Player:GetActiveWeapon()
		if not IsValid(Weapon) or Weapon:GetClass() ~= "gmod_tool" then return end

		local Tool = Player:GetTool()
		if not Tool or Tool ~= Player:GetTool("acfmeshdebug") then return end

		local Trace  = Player:GetEyeTrace()
		local Entity = Trace.Entity
		if not IsValid(Entity) or not Entity.ACF_Volumetric_Mesh then return end

		return Trace, Entity
	end

	-- The targeted prop is hidden while its convexes are being drawn, so it doesn't occlude or z-fight with the overlay.
	-- SetNoDraw only takes effect on the following frame's opaque pass, so the prop is unhidden again as soon as it
	-- stops being the target.
	local HiddenEntity

	hook.Add("PostDrawOpaqueRenderables", "ACF_MeshDebug_Visualizer", function(bDrawingDepth, _, bDrawingSkybox)
		if bDrawingDepth or bDrawingSkybox then return end

		local Trace, Entity = GetMeshTraceTarget()

		if IsValid(HiddenEntity) and HiddenEntity ~= Entity then
			HiddenEntity:SetNoDraw(false)
			HiddenEntity = nil
		end

		if not Entity then return end

		Entity:SetNoDraw(true)
		HiddenEntity = Entity

		local Dir         = (Trace.HitPos - Trace.StartPos):GetNormalized()
		local ConvexHit   = ACF.GetConvexHit(Entity, Trace.HitPos, Dir, true)
		local HighlightID = ConvexHit and ConvexHit.ConvexID

		DrawConvexes(Entity, HighlightID)

		if HighlightID then
			AddWorldTip(Entity, "Index: " .. HighlightID, nil, Trace.HitPos)
		end
	end)
elseif SERVER then
	function TOOL:LeftClick(_) return true end
	function TOOL:RightClick(_) return true end
	function TOOL:Reload(_) return true end
end
