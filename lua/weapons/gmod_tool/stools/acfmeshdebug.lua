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
local NetTag = "ACF_MeshDebug_ServerConvexes"

local function GetConvexVertices(Entity, Verts, Convex)
	local Unique = {}
	local WorldVerts = {}

	for _, Tri in ipairs(Convex.Tris) do
		for i = 1, 3 do
			local Pos = Verts[Tri[i]]
			local Key = Pos.x .. " " .. Pos.y .. " " .. Pos.z

			if not Unique[Key] then
				Unique[Key] = true
				WorldVerts[#WorldVerts + 1] = Entity:LocalToWorld(Pos)
			end
		end
	end

	if #WorldVerts == 0 then return end

	local Center = Vector(0, 0, 0)
	for _, Vertex in ipairs(WorldVerts) do
		Center = Center + Vertex
	end
	Center = Center / #WorldVerts

	return WorldVerts, Center
end

if CLIENT then
	local NextRequest = 0
	local RequestedEnt
	local ServerConvexCache = {}

	language.Add("tool.acfmeshdebug.name", "ACF Mesh Debugger")
	language.Add("tool.acfmeshdebug.desc", "Visualizes the convex decomposition of an ACF volumetric mesh")
	language.Add("tool.acfmeshdebug.info", "Look at a volumetric mesh entity to compare client and server convex indices")

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

	-- Draws the unique convex vertices so client and server geometry can be compared directly.
	local function DrawConvexVertices(Entity, HighlightID)
		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then return end

		for Index, Convex in ipairs(MeshData.Convexes) do
			local Vertices = GetConvexVertices(Entity, MeshData.Verts, Convex)
			if Vertices then
				local IsHighlighted = Index == HighlightID
				local Col = HSVToColor((Index * 47) % 360, 1, 1)
				Col.a = IsHighlighted and 255 or 180

				for _, Pos in ipairs(Vertices) do
					render.DrawSphere(Pos, 0.6, 8, 8, Col)
				end
			end
		end
	end

	local function GetConvexCenter(Entity, Verts, Convex)
		local _, Center = GetConvexVertices(Entity, Verts, Convex)
		return Center
	end

	local function DrawConvexIndices(Entity, HighlightID)
		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then return end

		local Verts = MeshData.Verts
		local EyePos = EyePos()

		cam.IgnoreZ(true)

		for Index, Convex in ipairs(MeshData.Convexes) do
			local Pos = GetConvexCenter(Entity, Verts, Convex)

			if Pos then
				local Dist = math.max(EyePos:Distance(Pos), 1)
				local Scale = math.Clamp(Dist / 2200, 0.08, 0.22)
				local IsHighlighted = Index == HighlightID
				local Col = IsHighlighted and Color(255, 255, 255, 255) or Color(220, 220, 220, 220)
				local ToEye = (EyePos - Pos):Angle()
				local TextAng = Angle(ToEye.p, ToEye.y, 0)
				TextAng:RotateAroundAxis(TextAng:Right(), -90)
				TextAng:RotateAroundAxis(TextAng:Up(), 90)

				cam.Start3D2D(Pos, TextAng, Scale)
					draw.SimpleTextOutlined("C:" .. Index, "Trebuchet24", 0, 0, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
				cam.End3D2D()
			end
		end

		cam.IgnoreZ(false)
	end

	local function DrawServerConvexVertices(Entity)
		local Data = ServerConvexCache[Entity:EntIndex()]
		if not Data or Data.Expire < CurTime() then return end

		local Col = Color(255, 180, 80, 180)
		for _, Convex in ipairs(Data.Convexes) do
			if Convex.Verts then
				for _, Pos in ipairs(Convex.Verts) do
					render.DrawSphere(Pos, 0.6, 8, 8, Col)
				end
			end
		end
	end

	local function DrawServerConvexIndices(Entity)
		local Data = ServerConvexCache[Entity:EntIndex()]
		if not Data or Data.Expire < CurTime() then return end

		local EyePos = EyePos()

		cam.IgnoreZ(true)

		for _, Convex in ipairs(Data.Convexes) do
			local Pos = Convex.Pos
			if Pos then
				local Dist = math.max(EyePos:Distance(Pos), 1)
				local Scale = math.Clamp(Dist / 2200, 0.08, 0.22)
				local ToEye = (EyePos - Pos):Angle()
				local TextAng = Angle(ToEye.p, ToEye.y, 0)
				TextAng:RotateAroundAxis(TextAng:Right(), -90)
				TextAng:RotateAroundAxis(TextAng:Up(), 90)

				cam.Start3D2D(Pos, TextAng, Scale)
					draw.SimpleTextOutlined("S:" .. Convex.ID, "Trebuchet24", 0, 20, Color(255, 180, 80, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
				cam.End3D2D()
			end
		end

		cam.IgnoreZ(false)
	end

	local function RequestServerConvexes(Entity)
		if CurTime() < NextRequest then return end

		local EntIndex = Entity:EntIndex()

		if RequestedEnt ~= EntIndex then
			NextRequest = 0
			RequestedEnt = EntIndex
		end

		NextRequest = CurTime() + 0.25

		net.Start(NetTag)
			net.WriteEntity(Entity)
		net.SendToServer()
	end

	net.Receive(NetTag, function()
		local Entity = net.ReadEntity()
		if not IsValid(Entity) then return end

		local Count = net.ReadUInt(16)
		local Convexes = {}

		for i = 1, Count do
			local VertCount = net.ReadUInt(16)
			local Vertices = {}

			for v = 1, VertCount do
				Vertices[v] = net.ReadVector()
			end

			Convexes[i] = {
				ID = net.ReadUInt(16),
				Pos = net.ReadVector(),
				Verts = Vertices,
			}
		end

		ServerConvexCache[Entity:EntIndex()] = {
			Convexes = Convexes,
			Expire = CurTime() + 1
		}
	end)

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
		DrawConvexVertices(Entity, HighlightID)
		DrawConvexIndices(Entity, HighlightID)
		DrawServerConvexVertices(Entity)
		DrawServerConvexIndices(Entity)
		RequestServerConvexes(Entity)
	end)
elseif SERVER then
	util.AddNetworkString(NetTag)

	net.Receive(NetTag, function(_, Player)
		if not IsValid(Player) then return end

		local Weapon = Player:GetActiveWeapon()
		if not IsValid(Weapon) or Weapon:GetClass() ~= "gmod_tool" then return end

		local Tool = Player:GetTool()
		if not Tool or Tool ~= Player:GetTool("acfmeshdebug") then return end

		local Entity = net.ReadEntity()
		if not IsValid(Entity) then return end

		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then return end

		local Verts = MeshData.Verts
		local Convexes = MeshData.Convexes

		net.Start(NetTag)
			net.WriteEntity(Entity)
			net.WriteUInt(#Convexes, 16)

			for Index, Convex in ipairs(Convexes) do
				local Vertices, Pos = GetConvexVertices(Entity, Verts, Convex)

				net.WriteUInt(#Vertices, 16)
				for _, Vertex in ipairs(Vertices) do
					net.WriteVector(Vertex)
				end

				net.WriteUInt(Index, 16)
				net.WriteVector(Pos or Entity:GetPos())
			end
		net.Send(Player)
	end)

	function TOOL:LeftClick(_) return true end
	function TOOL:RightClick(_) return true end
	function TOOL:Reload(_) return true end
end
