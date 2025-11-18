DEFINE_BASECLASS("acf_base_simple")

include("shared.lua")

language.Add("Cleanup_acf_armor_controllers", "ACF Armor Controllers")
language.Add("Cleaned_acf_crew", "Cleaned up all ACF Armor Controllers")
language.Add("SBoxLimit__acf_crew", "You've reached the ACF Armor Controller limit!")

function ENT:Initialize(...)
	BaseClass.Initialize(self, ...)
end

function ENT:Draw(...)
	BaseClass.Draw(self, ...)
end

function ENT:VisualizeMesh()
	if not self.MeshData then
		self.MeshData = {
			Vertices = {},
			Convexes = {}
		}
	end

	local vertices = self.MeshData.Vertices
	local convexes = self.MeshData.Convexes

	local function drawVertex(pos)
		render.DrawWireframeSphere(pos, 1, 8, 8, Color(255, 0, 255))
	end

	local function drawConvex(convex)
		for _, vertex in ipairs(convex) do
			drawVertex(vertex)
		end
	end

	for _, vertex in ipairs(vertices) do
		drawVertex(vertex.Pos)
	end

	for _, convex in ipairs(convexes) do
		drawConvex(convex)
	end
end

function ENT:CanDrawOverlay() -- This is called to see if DrawOverlay can be called
	return true
end

function ENT:DrawOverlay() -- Draw the overlay
	self:VisualizeMesh()
end