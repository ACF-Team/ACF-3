local debugoverlay = debugoverlay

TOOL.Category   = (ACF and ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction"
TOOL.Name       = "#tool.acfmeshdebug.name"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Information = {
	{ name = "left0", stage = 0 },
}

if CLIENT then
	language.Add("tool.acfmeshdebug.name", "ACF Mesh Debugger")
	language.Add("tool.acfmeshdebug.desc", "Visualizes the convex decomposition of an ACF volumetric mesh")
	language.Add("tool.acfmeshdebug.left0", "Visualize convexes of a mesh entity")

	function TOOL:LeftClick(_) return true end
	function TOOL:RightClick(_) return true end
	function TOOL:Reload(_) return true end

	TOOL.BuildCPanel = function() end
elseif SERVER then
	local function VisualizeConvexes(Entity)
		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then return end

		local Verts = MeshData.Verts

		for Index, ConvexTris in ipairs(MeshData.Convexes) do
			local Col = HSVToColor((Index * 47) % 360, 1, 1)
			Col.a = 150

			local AveragePos = Vector(0, 0, 0)
			for _, Tri in ipairs(ConvexTris) do
				local A = Entity:LocalToWorld(Verts[Tri[1]])
				local B = Entity:LocalToWorld(Verts[Tri[2]])
				local C = Entity:LocalToWorld(Verts[Tri[3]])
				debugoverlay.Triangle(A, B, C, 5, Col, true)
				AveragePos = AveragePos + A + B + C
			end
			AveragePos = AveragePos / (3 * #ConvexTris)
			debugoverlay.Text(AveragePos, tostring(Index), 5, Col, true)
		end
	end

	function TOOL:LeftClick(Trace)
		local Entity = Trace.Entity
		if not IsValid(Entity) then return true end

		VisualizeConvexes(Entity)
		return true
	end

	function TOOL:RightClick(_) return true end
	function TOOL:Reload(_) return true end
end
