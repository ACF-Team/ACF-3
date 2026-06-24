local ACF     = ACF
local IsValid = IsValid

TOOL.Category   = (ACF and ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction"
TOOL.Name       = "#tool.acfmeshdebug.name"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Information = {
	{ name = "info",  stage = 0 },
	{ name = "right", stage = 0 },
}

local Alpha      = 50
local NetVolTag  = "ACF_MeshDebug_ServerVolumetric"
local NetMeshTag = "ACF_MeshDebug_ServerMesh"
local NetCycle   = "ACF_MeshDebug_CycleMode"

-- Used by both client draw and server send for ACF_Volumetric_Mesh convexes.
local function GetConvexVertices(Entity, Verts, Convex)
	local Unique     = {}
	local WorldVerts = {}

	for _, Tri in ipairs(Convex.Tris) do
		for i = 1, 3 do
			local Pos = Verts[Tri[i]]
			local Key = Pos.x .. " " .. Pos.y .. " " .. Pos.z

			if not Unique[Key] then
				Unique[Key]                 = true
				WorldVerts[#WorldVerts + 1] = Entity:LocalToWorld(Pos)
			end
		end
	end

	if #WorldVerts == 0 then return end

	local Center = Vector(0, 0, 0)
	for _, V in ipairs(WorldVerts) do Center = Center + V end

	return WorldVerts, Center / #WorldVerts
end

if CLIENT then
	local ServerVolCache  = {}
	local ServerMeshCache = {}
	local PhysHullCache   = {}  -- Entity:GetPhysicsObject():GetMeshConvexes(), local-space, per EntIndex

	local NextVolRequest   = 0
	local RequestedVolEnt
	local NextMeshRequest  = 0
	local RequestedMeshEnt

	-- ─── Mode System ──────────────────────────────────────────────────────────
	local Modes      = {}
	local ModeCVName = "acfmeshdebug_mode"
	CreateClientConVar(ModeCVName, "1", true, false)
	local ModeCVar = GetConVar(ModeCVName)

	local function AddMode(Name, Draw, Request)
		Modes[#Modes + 1] = { Name = Name, Draw = Draw, Request = Request }
	end

	local function GetCurrentMode()
		return Modes[math.Clamp(ModeCVar:GetInt(), 1, math.max(1, #Modes))]
	end

	net.Receive(NetCycle, function()
		local Dir  = net.ReadInt(8)
		local Next = ((ModeCVar:GetInt() - 1 + Dir) % #Modes) + 1
		RunConsoleCommand(ModeCVName, Next)
	end)
	-- ──────────────────────────────────────────────────────────────────────────

	language.Add("tool.acfmeshdebug.name",  "ACF Mesh Debugger")
	language.Add("tool.acfmeshdebug.desc",  "Visualizes ACF volumetric and physics mesh convex data")
	language.Add("tool.acfmeshdebug.info",  "Look at a volumetric mesh entity to inspect its convex decomposition")
	language.Add("tool.acfmeshdebug.right", "Cycle visualization mode (hold E for reverse)")

	surface.CreateFont("ACF_MeshDebug_Screen", {
		font   = "Arial",
		size   = 24,
		weight = 700,
	})

	function TOOL:DrawToolScreen(Width, Height)
		local CurrentIdx = math.Clamp(ModeCVar:GetInt(), 1, math.max(1, #Modes))
		local LineH      = math.floor(Height / #Modes)
		local PadX       = 8

		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawRect(0, 0, Width, Height)

		for i, Mode in ipairs(Modes) do
			local IsSelected = i == CurrentIdx
			local Y          = (i - 1) * LineH

			if IsSelected then
				surface.SetDrawColor(40, 40, 40, 255)
				surface.DrawRect(0, Y, Width, LineH)
			end

			draw.SimpleText(
				Mode.Name,
				"ACF_MeshDebug_Screen",
				PadX,
				Y + LineH * 0.5,
				IsSelected and Color(255, 255, 255) or Color(110, 110, 110),
				TEXT_ALIGN_LEFT,
				TEXT_ALIGN_CENTER
			)
		end
	end

	function TOOL:LeftClick(_) return true end

	TOOL.BuildCPanel = function(Panel)
		Panel:AddControl("Header", {
			Text        = "ACF Mesh Debugger",
			Description = "Visualizes ACF volumetric and physics mesh convex data",
		})
		Panel:Help("Right-click to cycle modes. Hold E + right-click to go backwards.")
	end

	-- ─── Physics hull cache ───────────────────────────────────────────────────
	-- Processes PhysObj:GetMeshConvexes() once per entity and stores local-space
	-- data. LocalToWorld is called at draw time so moving entities stay correct.

	local function GetPhysHullsData(Entity)
		local EntIdx = Entity:EntIndex()

		if PhysHullCache[EntIdx] then
			return PhysHullCache[EntIdx]
		end

		local PhysObj = Entity:GetPhysicsObject()
		if not IsValid(PhysObj) then return end

		local RawHulls = PhysObj:GetMeshConvexes()
		if not RawHulls then return end

		local Processed = {}

		for Index, Hull in ipairs(RawHulls) do
			local UniqueLocal = {}
			local Seen        = {}
			local LocalCenter = Vector(0, 0, 0)

			for _, V in ipairs(Hull) do
				local Pos = V.pos
				local Key = Pos.x .. " " .. Pos.y .. " " .. Pos.z
				if not Seen[Key] then
					Seen[Key]                   = true
					UniqueLocal[#UniqueLocal + 1] = Pos
					LocalCenter                 = LocalCenter + Pos
				end
			end

			if #UniqueLocal > 0 then LocalCenter = LocalCenter / #UniqueLocal end

			Processed[Index] = {
				Hull        = Hull,
				LocalVerts  = UniqueLocal,
				LocalCenter = LocalCenter,
			}
		end

		PhysHullCache[EntIdx] = Processed
		return Processed
	end

	-- ─── Generic SV draw helpers ──────────────────────────────────────────────
	-- Both SV caches share the same layout:
	--   Cache[entIdx].Convexes[i] = { ID, Tris={{A,B,C},...}, Verts={...}, Pos }

	local function DrawSVTriangles(Cache, Entity, HighlightID)
		local Data = Cache[Entity:EntIndex()]
		if not Data or Data.Expire < CurTime() then return end

		render.SetColorMaterial()

		for _, Convex in ipairs(Data.Convexes) do
			local IsHighlighted = Convex.ID == HighlightID
			local Col           = HSVToColor((Convex.ID * 47) % 360, 1, 1)
			Col.a               = IsHighlighted and 120 or Alpha

			for _, Tri in ipairs(Convex.Tris) do
				render.DrawQuad(Tri[1], Tri[2], Tri[3], Tri[3], Col)
			end
		end
	end

	local function DrawSVVertices(Cache, Entity, HighlightID)
		local Data = Cache[Entity:EntIndex()]
		if not Data or Data.Expire < CurTime() then return end

		for _, Convex in ipairs(Data.Convexes) do
			local IsHighlighted = Convex.ID == HighlightID
			local Col           = HSVToColor((Convex.ID * 47) % 360, 1, 1)
			Col.a               = IsHighlighted and 255 or 180

			for _, Pos in ipairs(Convex.Verts) do
				render.DrawSphere(Pos, 0.6, 8, 8, Col)
			end
		end
	end

	local function DrawSVIndices(Cache, Entity, HighlightID, Prefix)
		local Data = Cache[Entity:EntIndex()]
		if not Data or Data.Expire < CurTime() then return end

		local EyePos = EyePos()
		cam.IgnoreZ(true)

		for _, Convex in ipairs(Data.Convexes) do
			local Pos = Convex.Pos
			if Pos then
				local Dist          = math.max(EyePos:Distance(Pos), 1)
				local Scale         = math.Clamp(Dist / 2200, 0.08, 0.22)
				local IsHighlighted = Convex.ID == HighlightID
				local Col           = IsHighlighted and Color(255, 255, 255, 255) or Color(220, 220, 220, 220)
				local ToEye         = (EyePos - Pos):Angle()
				local TextAng       = Angle(ToEye.p, ToEye.y, 0)
				TextAng:RotateAroundAxis(TextAng:Right(), -90)
				TextAng:RotateAroundAxis(TextAng:Up(), 90)

				cam.Start3D2D(Pos, TextAng, Scale)
					draw.SimpleTextOutlined(Prefix .. Convex.ID, "Trebuchet24", 0, 0, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
				cam.End3D2D()
			end
		end

		cam.IgnoreZ(false)
	end

	-- ─── Draw: MeshConvexes (CL) ──────────────────────────────────────────────

	local function DrawMeshConvexTriangles(Entity, HighlightID)
		local HullsData = GetPhysHullsData(Entity)
		if not HullsData then return end

		render.SetColorMaterial()

		for Index, Data in ipairs(HullsData) do
			local IsHighlighted = Index == HighlightID
			local Col           = HSVToColor((Index * 47) % 360, 1, 1)
			Col.a               = IsHighlighted and 120 or Alpha

			local Hull = Data.Hull
			for I = 1, #Hull - 2, 3 do
				local A = Entity:LocalToWorld(Hull[I].pos)
				local B = Entity:LocalToWorld(Hull[I + 1].pos)
				local C = Entity:LocalToWorld(Hull[I + 2].pos)
				render.DrawQuad(A, B, C, C, Col)
			end
		end
	end

	local function DrawMeshConvexVertices(Entity, HighlightID)
		local HullsData = GetPhysHullsData(Entity)
		if not HullsData then return end

		for Index, Data in ipairs(HullsData) do
			local IsHighlighted = Index == HighlightID
			local Col           = HSVToColor((Index * 47) % 360, 1, 1)
			Col.a               = IsHighlighted and 255 or 180

			for _, LocalPos in ipairs(Data.LocalVerts) do
				render.DrawSphere(Entity:LocalToWorld(LocalPos), 0.6, 8, 8, Col)
			end
		end
	end

	local function DrawMeshConvexIndices(Entity, HighlightID)
		local HullsData = GetPhysHullsData(Entity)
		if not HullsData then return end

		local EyePos = EyePos()
		cam.IgnoreZ(true)

		for Index, Data in ipairs(HullsData) do
			local Pos = Entity:LocalToWorld(Data.LocalCenter)

			local Dist          = math.max(EyePos:Distance(Pos), 1)
			local Scale         = math.Clamp(Dist / 2200, 0.08, 0.22)
			local IsHighlighted = Index == HighlightID
			local Col           = IsHighlighted and Color(255, 255, 255, 255) or Color(220, 220, 220, 220)
			local ToEye         = (EyePos - Pos):Angle()
			local TextAng       = Angle(ToEye.p, ToEye.y, 0)
			TextAng:RotateAroundAxis(TextAng:Right(), -90)
			TextAng:RotateAroundAxis(TextAng:Up(), 90)

			cam.Start3D2D(Pos, TextAng, Scale)
				draw.SimpleTextOutlined("M:" .. Index, "Trebuchet24", 0, 0, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
			cam.End3D2D()
		end

		cam.IgnoreZ(false)
	end

	-- ─── Draw: Volumetric (CL) ────────────────────────────────────────────────

	local function DrawVolTriangles(Entity, HighlightID)
		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then return end

		local Verts = MeshData.Verts
		render.SetColorMaterial()

		for Index, Convex in ipairs(MeshData.Convexes) do
			local IsHighlighted = Index == HighlightID
			local Col           = HSVToColor((Index * 47) % 360, 1, 1)
			Col.a               = IsHighlighted and 120 or Alpha

			for _, Tri in ipairs(Convex.Tris) do
				local A = Entity:LocalToWorld(Verts[Tri[1]])
				local B = Entity:LocalToWorld(Verts[Tri[2]])
				local C = Entity:LocalToWorld(Verts[Tri[3]])
				render.DrawQuad(A, B, C, C, Col)
			end
		end
	end

	local function DrawVolVertices(Entity, HighlightID)
		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then return end

		for Index, Convex in ipairs(MeshData.Convexes) do
			local WorldVerts = GetConvexVertices(Entity, MeshData.Verts, Convex)
			if WorldVerts then
				local IsHighlighted = Index == HighlightID
				local Col           = HSVToColor((Index * 47) % 360, 1, 1)
				Col.a               = IsHighlighted and 255 or 180

				for _, Pos in ipairs(WorldVerts) do
					render.DrawSphere(Pos, 0.6, 8, 8, Col)
				end
			end
		end
	end

	local function DrawVolIndices(Entity, HighlightID)
		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then return end

		local Verts  = MeshData.Verts
		local EyePos = EyePos()
		cam.IgnoreZ(true)

		for Index, Convex in ipairs(MeshData.Convexes) do
			local _, Center = GetConvexVertices(Entity, Verts, Convex)
			if Center then
				local Dist          = math.max(EyePos:Distance(Center), 1)
				local Scale         = math.Clamp(Dist / 2200, 0.08, 0.22)
				local IsHighlighted = Index == HighlightID
				local Col           = IsHighlighted and Color(255, 255, 255, 255) or Color(220, 220, 220, 220)
				local ToEye         = (EyePos - Center):Angle()
				local TextAng       = Angle(ToEye.p, ToEye.y, 0)
				TextAng:RotateAroundAxis(TextAng:Right(), -90)
				TextAng:RotateAroundAxis(TextAng:Up(), 90)

				cam.Start3D2D(Center, TextAng, Scale)
					draw.SimpleTextOutlined("C:" .. Index, "Trebuchet24", 0, 0, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
				cam.End3D2D()
			end
		end

		cam.IgnoreZ(false)
	end

	-- ─── Server Requests ──────────────────────────────────────────────────────

	local function RequestServerVolumetric(Entity)
		if CurTime() < NextVolRequest then return end

		local EntIndex = Entity:EntIndex()
		if RequestedVolEnt ~= EntIndex then
			NextVolRequest  = 0
			RequestedVolEnt = EntIndex
		end

		NextVolRequest = CurTime() + 0.25

		net.Start(NetVolTag)
			net.WriteEntity(Entity)
		net.SendToServer()
	end

	local function RequestServerMesh(Entity)
		if CurTime() < NextMeshRequest then return end

		local EntIndex = Entity:EntIndex()
		if RequestedMeshEnt ~= EntIndex then
			NextMeshRequest  = 0
			RequestedMeshEnt = EntIndex
		end

		NextMeshRequest = CurTime() + 0.25

		net.Start(NetMeshTag)
			net.WriteEntity(Entity)
		net.SendToServer()
	end

	-- ─── Net Receivers ────────────────────────────────────────────────────────
	-- Both protocols: entity, convexCount, then per convex:
	--   id (uint16), triCount (uint16), A/B/C per tri (vector×3), center (vector)
	-- Client extracts unique verts from the triangle data locally.

	local function ReadSVConvexes()
		local Count    = net.ReadUInt(16)
		local Convexes = {}

		for i = 1, Count do
			local ID       = net.ReadUInt(16)
			local TriCount = net.ReadUInt(16)
			local Tris     = {}
			local Verts    = {}
			local Seen     = {}

			for t = 1, TriCount do
				local A = net.ReadVector()
				local B = net.ReadVector()
				local C = net.ReadVector()
				Tris[t] = { A, B, C }

				for _, V in ipairs({ A, B, C }) do
					local K = V.x .. " " .. V.y .. " " .. V.z
					if not Seen[K] then
						Seen[K]             = true
						Verts[#Verts + 1]   = V
					end
				end
			end

			Convexes[i] = { ID = ID, Tris = Tris, Verts = Verts, Pos = net.ReadVector() }
		end

		return Convexes
	end

	net.Receive(NetVolTag, function()
		local Entity = net.ReadEntity()
		if not IsValid(Entity) then return end
		ServerVolCache[Entity:EntIndex()] = { Convexes = ReadSVConvexes(), Expire = CurTime() + 1 }
	end)

	net.Receive(NetMeshTag, function()
		local Entity = net.ReadEntity()
		if not IsValid(Entity) then return end
		ServerMeshCache[Entity:EntIndex()] = { Convexes = ReadSVConvexes(), Expire = CurTime() + 1 }
	end)

	-- ─── Mode Definitions ─────────────────────────────────────────────────────

	AddMode("MeshConvexes (CL)", function(Entity, HighlightID)
		DrawMeshConvexTriangles(Entity, HighlightID)
		DrawMeshConvexVertices(Entity, HighlightID)
		DrawMeshConvexIndices(Entity, HighlightID)
	end)

	AddMode("MeshConvexes (SV)", function(Entity, HighlightID)
		DrawSVTriangles(ServerMeshCache, Entity, HighlightID)
		DrawSVVertices(ServerMeshCache, Entity, HighlightID)
		DrawSVIndices(ServerMeshCache, Entity, HighlightID, "M:")
	end, RequestServerMesh)

	AddMode("Volumetric (CL)", function(Entity, HighlightID)
		DrawVolTriangles(Entity, HighlightID)
		DrawVolVertices(Entity, HighlightID)
		DrawVolIndices(Entity, HighlightID)
	end)

	AddMode("Volumetric (SV)", function(Entity, HighlightID)
		DrawSVTriangles(ServerVolCache, Entity, HighlightID)
		DrawSVVertices(ServerVolCache, Entity, HighlightID)
		DrawSVIndices(ServerVolCache, Entity, HighlightID, "C:")
	end, RequestServerVolumetric)

	-- ──────────────────────────────────────────────────────────────────────────

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

		local Mode = GetCurrentMode()
		if Mode then
			Mode.Draw(Entity, HighlightID)
			if Mode.Request then Mode.Request(Entity) end
		end
	end)
elseif SERVER then
	util.AddNetworkString(NetVolTag)
	util.AddNetworkString(NetMeshTag)
	util.AddNetworkString(NetCycle)

	local function ValidatePlayer(Player)
		if not IsValid(Player) then return false end
		local Weapon = Player:GetActiveWeapon()
		if not IsValid(Weapon) or Weapon:GetClass() ~= "gmod_tool" then return false end
		local Tool = Player:GetTool()
		return Tool and Tool == Player:GetTool("acfmeshdebug")
	end

	-- Shared write helper: id (uint16), triCount (uint16), A/B/C per tri (vector×3), center (vector)
	local function WriteConvex(ID, Tris, Center)
		net.WriteUInt(ID, 16)
		net.WriteUInt(#Tris, 16)
		for _, Tri in ipairs(Tris) do
			net.WriteVector(Tri[1])
			net.WriteVector(Tri[2])
			net.WriteVector(Tri[3])
		end
		net.WriteVector(Center)
	end

	net.Receive(NetVolTag, function(_, Player)
		if not ValidatePlayer(Player) then return end

		local Entity = net.ReadEntity()
		if not IsValid(Entity) then return end

		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData then return end

		local Verts    = MeshData.Verts
		local Convexes = MeshData.Convexes

		net.Start(NetVolTag)
			net.WriteEntity(Entity)
			net.WriteUInt(#Convexes, 16)

			for Index, Convex in ipairs(Convexes) do
				local Tris   = {}
				local Center = Vector(0, 0, 0)
				local Unique = {}
				local Seen   = {}

				for _, Tri in ipairs(Convex.Tris) do
					local A = Entity:LocalToWorld(Verts[Tri[1]])
					local B = Entity:LocalToWorld(Verts[Tri[2]])
					local C = Entity:LocalToWorld(Verts[Tri[3]])
					Tris[#Tris + 1] = { A, B, C }

					for _, V in ipairs({ A, B, C }) do
						local K = V.x .. " " .. V.y .. " " .. V.z
						if not Seen[K] then
							Seen[K] = true
							Unique[#Unique + 1] = V
							Center = Center + V
						end
					end
				end

				if #Unique > 0 then Center = Center / #Unique end

				WriteConvex(Index, Tris, Center)
			end
		net.Send(Player)
	end)

	net.Receive(NetMeshTag, function(_, Player)
		if not ValidatePlayer(Player) then return end

		local Entity = net.ReadEntity()
		if not IsValid(Entity) then return end

		local PhysObj = Entity:GetPhysicsObject()
		if not IsValid(PhysObj) then return end

		local Hulls = PhysObj:GetMeshConvexes()
		if not Hulls then return end

		net.Start(NetMeshTag)
			net.WriteEntity(Entity)
			net.WriteUInt(#Hulls, 16)

			for Index, Hull in ipairs(Hulls) do
				local Tris   = {}
				local Center = Vector(0, 0, 0)
				local Unique = {}
				local Seen   = {}

				for I = 1, #Hull - 2, 3 do
					local A = Entity:LocalToWorld(Hull[I].pos)
					local B = Entity:LocalToWorld(Hull[I + 1].pos)
					local C = Entity:LocalToWorld(Hull[I + 2].pos)
					Tris[#Tris + 1] = { A, B, C }

					for _, V in ipairs({ A, B, C }) do
						local K = V.x .. " " .. V.y .. " " .. V.z
						if not Seen[K] then
							Seen[K] = true
							Unique[#Unique + 1] = V
							Center = Center + V
						end
					end
				end

				if #Unique > 0 then Center = Center / #Unique end

				WriteConvex(Index, Tris, Center)
			end
		net.Send(Player)
	end)

	function TOOL:LeftClick(_) return true end

	function TOOL:RightClick(_)
		local Dir = self:GetOwner():KeyDown(IN_USE) and -1 or 1
		net.Start(NetCycle)
			net.WriteInt(Dir, 8)
		net.Send(self:GetOwner())
		self:GetWeapon():EmitSound("weapons/pistol/pistol_empty.wav", 100, math.random(50, 150))
		return false
	end

	function TOOL:Reload(_) return true end
end
