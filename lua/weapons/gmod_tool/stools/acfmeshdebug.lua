local debugoverlay = debugoverlay

TOOL.Category   = (ACF and ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction"
TOOL.Name       = "#tool.acfmeshdebug.name"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Information = {
	{ name = "left0", stage = 0 },
	{ name = "right0", stage = 0 },
}

local FadeTime = 10
local Alpha = 50

if CLIENT then
	language.Add("tool.acfmeshdebug.name", "ACF Mesh Debugger")
	language.Add("tool.acfmeshdebug.desc", "Visualizes the convex decomposition of an ACF volumetric mesh")
	language.Add("tool.acfmeshdebug.left0", "Visualize convexes of a mesh entity")
	language.Add("tool.acfmeshdebug.right0", "Cast a ray and visualize mesh intersections")

	function TOOL:LeftClick(_) return true end
	function TOOL:RightClick(_) return true end
	function TOOL:Reload(_) return true end

	TOOL.BuildCPanel = function() end
elseif SERVER then
	local White = Color(255, 255, 255, 255)

	local function VisualizeConvexes(Entity, ConvexIDs, HighlightID)
		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then return end

		local Verts = MeshData.Verts

		for Index, Convex in ipairs(MeshData.Convexes) do
			local IsHighlighted = Index == HighlightID
			local Col = (ConvexIDs and not ConvexIDs[Index]) and Color(255, 255, 255) or HSVToColor((Index * 47) % 360, 1, 1)
			Col.a = IsHighlighted and 150 or Alpha

			local AveragePos = Vector(0, 0, 0)
			for _, Tri in ipairs(Convex.Tris) do
				local A = Entity:LocalToWorld(Verts[Tri[1]])
				local B = Entity:LocalToWorld(Verts[Tri[2]])
				local C = Entity:LocalToWorld(Verts[Tri[3]])
				debugoverlay.Triangle(A, B, C, FadeTime, Col, true)

				if IsHighlighted then
					debugoverlay.Line(A, B, FadeTime, White, true)
					debugoverlay.Line(B, C, FadeTime, White, true)
					debugoverlay.Line(C, A, FadeTime, White, true)
				end

				AveragePos = AveragePos + A + B + C
			end
			AveragePos = AveragePos / (3 * #Convex.Tris)

			local Label = IsHighlighted and string.format("Mat: %s | HP: %.2f | Vol: %.2f", Convex.Material, Convex.Health, Convex.Volume) or tostring(Index)

			debugoverlay.Text(AveragePos, Label, FadeTime, Col, true)
		end
	end

	function TOOL:LeftClick(Trace)
		local Entity = Trace.Entity
		if not IsValid(Entity) then return true end

		local Dir       = (Trace.HitPos - Trace.StartPos):GetNormalized()
		local ConvexHit = ACF.GetConvexHit(Entity, Trace.HitPos, Dir)

		VisualizeConvexes(Entity, nil, ConvexHit and ConvexHit.ConvexID)
		return true
	end

	function TOOL:RightClick(Trace)
		local Entity = Trace.Entity
		if not IsValid(Entity) then return true end

		local Dir  = (Trace.HitPos - Trace.StartPos):GetNormalized()
		local Hits = ACF.RayIntersectMesh(Entity, Trace.StartPos, Dir, 8192)

		local HitConvexIDs = {}
		for _, Hit in ipairs(Hits) do
			HitConvexIDs[Hit.ConvexID] = true
		end

		debugoverlay.Line(Trace.StartPos, Trace.HitPos, FadeTime, Color(255, 255, 0, 255), true)
		VisualizeConvexes(Entity, HitConvexIDs)

		for I, Hit in ipairs(Hits) do
			debugoverlay.Cross(Hit.Pos, 3, FadeTime, Color(255, 0, 0, 200), true)
			debugoverlay.Line(Hit.Pos, Hit.Pos + Hit.Normal * 5, FadeTime, Color(0, 255, 255, 255), true)
			if Hits[I - 1] then
				debugoverlay.Line(Hits[I - 1].Pos, Hit.Pos, FadeTime, Color(255, 128, 0, 255), true)
			end
		end

		return true
	end
	function TOOL:Reload(_) return true end
end
