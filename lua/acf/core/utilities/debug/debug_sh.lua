local ACF	= ACF
ACF.Debug	= {}

local CVar	= CLIENT and CreateClientConVar("acf_developer", "0", true, false, "Debug drawing level, independent of 'developer'. Calls draw when their level is at or below this, level 0 calls are player facing and always drawn", 0, 9)

local NetName	= "ACF_DebugDraw"
local LevelNet	= "ACF_DebugLevel"
local MaxLevel	= 0
local ID_BITS	= 5
local MAX_BYTES	= 60000
local LIFE_RES	= 20
local DEFAULT_LIFE = 1
local Level		= 1
local Target
local Group
local Registry	= {}
local Queue		= {}
local QueueSize	= 0
local Passes	= {World = {}, HUD = {}, Halo = {}}

local function writeColor(Col)
	local HasAlpha = Col.a ~= 255

	net.WriteBool(HasAlpha)
	net.WriteColor(Col, HasAlpha)
end

local function readColor()
	return net.ReadColor(net.ReadBool())
end

-- Argument types, each with a net writer, a net reader and an optional default
local Types = {
	Vector	= {Write = net.WriteVector, Read = net.ReadVector},
	Angle	= {Write = net.WriteAngle, Read = net.ReadAngle},
	Number	= {Write = net.WriteFloat, Read = net.ReadFloat},
	String	= {Write = net.WriteString, Read = net.ReadString},
	Bool	= {Write = function(V) net.WriteBool(V and true or false) end, Read = net.ReadBool, Default = false},
	Color	= {Write = writeColor, Read = readColor, Default = color_white},
	Line	= {Write = function(V) net.WriteInt(V, 8) end, Read = function() return net.ReadInt(8) end},
	Entity	= {Write = net.WriteEntity, Read = net.ReadEntity},
	Life	= {
		Write	= function(V) net.WriteUInt(math.Clamp(math.Round(V * LIFE_RES), 0, 65535), 16) end,
		Read	= function() return net.ReadUInt(16) / LIFE_RES end,
		Default	= DEFAULT_LIFE
	},
}

-- True if a call at the current level would be drawn for anyone (server) or the local player (client)
local function isEnabled()
	return Level <= (SERVER and MaxLevel or CVar:GetInt())
end

local function addItem(Item)
	-- Clear removes everything drawn under its group before it expires
	if Item.Def.Pass == "Clear" then
		for _, List in pairs(Passes) do
			for I = #List, 1, -1 do
				if List[I].Group == Item[1] then table.remove(List, I) end
			end
		end

		return
	end

	local Pass = Passes[Item.Def.Pass]
	local Life = Item[Item.Def.LifeIndex] or DEFAULT_LIFE

	Item.Expire = CurTime() + Life
	Pass[#Pass + 1] = Item
end

-- Registers a debug shape, Args is a list of {Name, TypeName, Default}, Draw runs clientside with the args
local function register(Name, Pass, Args, Draw)
	local Def = {Name = Name, Pass = Pass, Draw = Draw, Count = #Args, Args = {}, Writers = {}, Readers = {}, ID = #Registry + 1}

	assert(Def.ID < 2 ^ ID_BITS, "Too many debug shapes for ID_BITS")

	for I, Arg in ipairs(Args) do
		local Type = Types[Arg[2]]

		Def.Writers[I] = Type.Write
		Def.Readers[I] = Type.Read
		Def.Args[I] = {Default = Arg[3] == nil and Type.Default or Arg[3]}

		if Arg[2] == "Life" then Def.LifeIndex = I end
	end

	Registry[Def.ID] = Def

	ACF.Debug[Name] = function(...)
		if not isEnabled() then return end

		local Item = {...}

		Item.Level = Level
		Item.Target = Target
		Item.Group = Group

		for I = 1, Def.Count do
			if Item[I] == nil then Item[I] = Def.Args[I].Default end
		end

		Item.Def = Def

		if SERVER then
			QueueSize = QueueSize + 1
			Queue[QueueSize] = Item
		else
			addItem(Item)
		end
	end
end

ACF.Debug.Register = register

-- Sets the level of all following calls, returns whether they would be drawn so debug-only work can be skipped
-- Level 0 is for player facing drawings such as legality violations, shown even with acf_developer 0
function ACF.Debug.SetDeveloperLevel(NewLevel)
	Level = math.max(0, math.floor(NewLevel or 1))

	return isEnabled()
end

function ACF.Debug.GetDeveloperLevel()
	return Level
end

-- Restricts all following serverside calls to a player or a list of players, nil means everyone
function ACF.Debug.SetTarget(NewTarget)
	local Old = Target

	Target = NewTarget

	return Old
end

function ACF.Debug.GetTarget()
	return Target
end

-- Tags all following calls with an entity, so ACF.Debug.Clear can remove them before they expire
function ACF.Debug.SetGroup(NewGroup)
	local Old = Group

	Group = NewGroup

	return Old
end

local Vec	= {"Origin", "Vector"}
local Life	= {"Lifetime", "Life"}
local Col	= {"Color", "Color"}
local IgnZ	= {"IgnoreZ", "Bool"}

register("Axis", "World", {Vec, {"Angle", "Angle"}, {"Size", "Number"}, Life, IgnZ}, function(Origin, Ang, Size, _, IgnoreZ)
	render.DrawLine(Origin, Origin + Ang:Forward() * Size, Color(255, 0, 0), not IgnoreZ)
	render.DrawLine(Origin, Origin - Ang:Right() * Size, Color(0, 255, 0), not IgnoreZ)
	render.DrawLine(Origin, Origin + Ang:Up() * Size, Color(0, 0, 255), not IgnoreZ)
end)

register("Box", "World", {Vec, {"Mins", "Vector"}, {"Maxs", "Vector"}, Life, Col}, function(Origin, Mins, Maxs, _, Color)
	render.DrawWireframeBox(Origin, angle_zero, Mins, Maxs, Color, true)
end)

register("BoxAngles", "World", {Vec, {"Mins", "Vector"}, {"Maxs", "Vector"}, {"Angle", "Angle"}, Life, Col}, function(Origin, Mins, Maxs, Ang, _, Color)
	render.DrawWireframeBox(Origin, Ang, Mins, Maxs, Color, true)
end)

register("Cross", "World", {Vec, {"Size", "Number"}, Life, Col, IgnZ}, function(Origin, Size, _, Color, IgnoreZ)
	render.DrawLine(Origin - Vector(Size, 0, 0), Origin + Vector(Size, 0, 0), Color, not IgnoreZ)
	render.DrawLine(Origin - Vector(0, Size, 0), Origin + Vector(0, Size, 0), Color, not IgnoreZ)
	render.DrawLine(Origin - Vector(0, 0, Size), Origin + Vector(0, 0, Size), Color, not IgnoreZ)
end)

register("Grid", "World", {Vec}, function(Origin)
	local Color = Color(255, 255, 255, 80)

	for I = -10, 10 do
		render.DrawLine(Origin + Vector(I * 16, -160, 0), Origin + Vector(I * 16, 160, 0), Color, true)
		render.DrawLine(Origin + Vector(-160, I * 16, 0), Origin + Vector(160, I * 16, 0), Color, true)
	end
end)

register("Line", "World", {{"Start", "Vector"}, {"End", "Vector"}, Life, Col, IgnZ}, function(Start, End, _, Color, IgnoreZ)
	render.DrawLine(Start, End, Color, not IgnoreZ)
end)

register("Sphere", "World", {Vec, {"Size", "Number"}, Life, Col, IgnZ}, function(Origin, Size, _, Color, IgnoreZ)
	cam.IgnoreZ(IgnoreZ)
	render.DrawWireframeSphere(Origin, Size, 8, 8, Color, true)
	cam.IgnoreZ(false)
end)

register("SweptBox", "World", {{"Start", "Vector"}, {"End", "Vector"}, {"Mins", "Vector"}, {"Maxs", "Vector"}, {"Angle", "Angle"}, Life, Col}, function(Start, End, Mins, Maxs, Ang, _, Color)
	render.DrawWireframeBox(Start, Ang, Mins, Maxs, Color, true)
	render.DrawWireframeBox(End, Ang, Mins, Maxs, Color, true)

	for I = 0, 7 do
		local Corner = Vector(I % 2 == 0 and Mins.x or Maxs.x, I % 4 < 2 and Mins.y or Maxs.y, I < 4 and Mins.z or Maxs.z)
		local Offset = LocalToWorld(Corner, angle_zero, vector_origin, Ang)

		render.DrawLine(Start + Offset, End + Offset, Color, true)
	end
end)

register("Triangle", "World", {{"A", "Vector"}, {"B", "Vector"}, {"C", "Vector"}, Life, Col, IgnZ}, function(A, B, C, _, Color, IgnoreZ)
	render.SetColorMaterial() -- Wireframe shapes drawn before this one change the material
	cam.IgnoreZ(IgnoreZ)
	render.DrawQuad(A, B, C, C, Color)
	render.DrawQuad(C, B, A, A, Color)
	cam.IgnoreZ(false)
end)

local TextFont	= "BudgetLabel"
local LINE_HEIGHT = 14

register("Text", "HUD", {Vec, {"Text", "String"}, Life, {"ViewCheck", "Bool"}}, function(Origin, Text, _, ViewCheck)
	if ViewCheck and util.TraceLine({start = EyePos(), endpos = Origin, mask = MASK_OPAQUE}).Hit then return end

	local Pos = Origin:ToScreen()

	if Pos.visible then draw.SimpleText(Text, TextFont, Pos.x, Pos.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
end)

register("EntityTextAtPosition", "HUD", {Vec, {"Line", "Line"}, {"Text", "String"}, Life, Col}, function(Origin, Line, Text, _, Color)
	local Pos = Origin:ToScreen()

	if Pos.visible then draw.SimpleText(Text, TextFont, Pos.x, Pos.y + Line * LINE_HEIGHT, Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
end)

-- Entity shapes are drawn where the entity is now, so they follow moving vehicles between calls
local Ent = {"Entity", "Entity"}

register("EntityText", "HUD", {Ent, {"Line", "Line"}, {"Text", "String"}, Life, Col}, function(Entity, Line, Text, _, Color)
	if not IsValid(Entity) then return end

	local Pos = Entity:WorldSpaceCenter():ToScreen()

	if Pos.visible then draw.SimpleTextOutlined(Text, TextFont, Pos.x, Pos.y + Line * LINE_HEIGHT, Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black) end
end)

register("EntityBox", "World", {Ent, Life, Col, IgnZ}, function(Entity, _, Color, IgnoreZ)
	if not IsValid(Entity) then return end

	local Mins, Maxs = Entity:GetCollisionBounds()

	render.DrawWireframeBox(Entity:GetPos(), Entity:GetAngles(), Mins, Maxs, Color, not IgnoreZ)
end)

register("EntityLine", "World", {{"Start", "Entity"}, {"End", "Entity"}, Life, Col, IgnZ}, function(Start, End, _, Color, IgnoreZ)
	if not IsValid(Start) or not IsValid(End) then return end

	render.DrawLine(Start:GetPos(), End:GetPos(), Color, not IgnoreZ)
end)

-- Draws one convex of an entity's volumetric mesh, which only exists clientside, optionally scaled about its centroid
register("Convex", "World", {Ent, {"Convex", "Number"}, Life, Col, IgnZ, {"Scale", "Number", 1}}, function(Entity, ConvexID, _, Color, IgnoreZ, Scale)
	local MeshData = IsValid(Entity) and Entity.ACF_Volumetric_Mesh
	local Convex   = MeshData and MeshData.Convexes[ConvexID]
	if not Convex then return end

	local Center = Convex.Centroid

	for _, Tri in ipairs(Convex.Tris) do
		local A = Entity:LocalToWorld(Center + (Tri[1] - Center) * Scale)
		local B = Entity:LocalToWorld(Center + (Tri[2] - Center) * Scale)
		local C = Entity:LocalToWorld(Center + (Tri[3] - Center) * Scale)

		render.DrawLine(A, B, Color, not IgnoreZ)
		render.DrawLine(B, C, Color, not IgnoreZ)
		render.DrawLine(C, A, Color, not IgnoreZ)
	end
end)

register("Clear", "Clear", {{"Group", "Entity"}})

-- Halos are batched per color, since every halo.Add call is a separate render pass
local Halos = {}

register("Halo", "Halo", {Ent, Life, Col}, function(Entity, _, Color)
	if not IsValid(Entity) then return end

	local Key   = string.format("%d %d %d %d", Color.r, Color.g, Color.b, Color.a)
	local Batch = Halos[Key]

	if not Batch then
		Batch = {Color = Color}
		Halos[Key] = Batch
	end

	Batch[#Batch + 1] = Entity
end)

register("ScreenText", "HUD", {{"X", "Number"}, {"Y", "Number"}, {"Text", "String"}, Life, Col}, function(X, Y, Text, _, Color)
	draw.SimpleText(Text, TextFont, X * ScrW(), Y * ScrH(), Color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end)

if SERVER then
	util.AddNetworkString(NetName)
	util.AddNetworkString(LevelNet)

	local function updateMaxLevel(Ignore)
		MaxLevel = 0

		for _, Ply in player.Iterator() do
			if Ply ~= Ignore then MaxLevel = math.max(MaxLevel, Ply.ACF_DebugLevel or 0) end
		end
	end

	-- Clients report their own acf_developer, so the server only sends what someone will draw
	-- Non-admins only get level 0, server drawings would otherwise show them entities through walls
	net.Receive(LevelNet, function(_, Ply)
		Ply.ACF_DebugLevel = Ply:IsAdmin() and math.min(net.ReadUInt(4), 9) or 0

		updateMaxLevel()
	end)

	hook.Add("PlayerDisconnected", "ACF Debug Draw", updateMaxLevel)

	-- Each entry is a continue bit, a shape ID and its args
	local function sendList(Recipients, List)
		local Open = false

		for I = 1, #List do
			if Open and net.BytesWritten() > MAX_BYTES then
				net.WriteBool(false)
				net.Send(Recipients)

				Open = false
			end

			if not Open then
				net.Start(NetName)

				Open = true
			end

			local Item = List[I]
			local Def = Item.Def

			net.WriteBool(true)
			net.WriteUInt(Def.ID, ID_BITS)
			net.WriteBool(Item.Group ~= nil)

			if Item.Group ~= nil then net.WriteEntity(Item.Group) end

			for J = 1, Def.Count do Def.Writers[J](Item[J]) end
		end

		if Open then
			net.WriteBool(false)
			net.Send(Recipients)
		end
	end

	local function addTo(Lists, Key, Item)
		local List = Lists[Key]

		if not List then
			List = {}
			Lists[Key] = List
		end

		List[#List + 1] = Item
	end

	-- Calls are batched per tick, shared ones are sent once per distinct client level and targeted ones per player
	hook.Add("Tick", "ACF Debug Draw", function()
		Level, Target, Group = 1, nil, nil

		if QueueSize == 0 then return end

		local Groups, Shared, Own = {}, {}, {}

		for _, Ply in player.Iterator() do
			addTo(Groups, Ply.ACF_DebugLevel or 0, Ply)
		end

		for I = 1, QueueSize do
			local Item = Queue[I]
			local Wanted = Item.Target

			Queue[I] = nil

			if Wanted == nil then
				for Limit in pairs(Groups) do
					if Item.Level <= Limit then addTo(Shared, Limit, Item) end
				end
			elseif isentity(Wanted) then
				if IsValid(Wanted) and (Wanted.ACF_DebugLevel or 0) >= Item.Level then addTo(Own, Wanted, Item) end
			else
				for _, Ply in ipairs(Wanted) do
					if IsValid(Ply) and (Ply.ACF_DebugLevel or 0) >= Item.Level then addTo(Own, Ply, Item) end
				end
			end
		end

		QueueSize = 0

		for Limit, List in pairs(Shared) do sendList(Groups[Limit], List) end
		for Ply, List in pairs(Own) do sendList(Ply, List) end
	end)
else
	local function sendLevel()
		net.Start(LevelNet)
		net.WriteUInt(CVar:GetInt(), 4)
		net.SendToServer()
	end

	cvars.AddChangeCallback("acf_developer", sendLevel, "ACF Debug Draw")
	hook.Add("InitPostEntity", "ACF Debug Draw", sendLevel)

	net.Receive(NetName, function()
		while net.ReadBool() do
			local Def = Registry[net.ReadUInt(ID_BITS)]
			local Item = {Def = Def, Group = net.ReadBool() and net.ReadEntity() or nil}

			for I = 1, Def.Count do Item[I] = Def.Readers[I]() end

			addItem(Item)
		end
	end)

	local function run(List)
		local Now = CurTime()

		for I = #List, 1, -1 do
			local Item = List[I]
			local Def = Item.Def

			Def.Draw(unpack(Item, 1, Def.Count))

			if Item.Expire <= Now then
				List[I] = List[#List]
				List[#List] = nil
			end
		end
	end

	hook.Add("PostDrawTranslucentRenderables", "ACF Debug Draw", function(_, Skybox)
		if Skybox or not Passes.World[1] then return end

		render.SetColorMaterial()
		run(Passes.World)
	end)

	hook.Add("HUDPaint", "ACF Debug Draw", function()
		if Passes.HUD[1] then run(Passes.HUD) end
	end)

	hook.Add("PreDrawHalos", "ACF Debug Draw", function()
		if not Passes.Halo[1] then return end

		run(Passes.Halo)

		for Key, Batch in pairs(Halos) do
			halo.Add(Batch, Batch.Color, 3, 3, 1, true, true)

			Halos[Key] = nil
		end
	end)
end

local FunDebuggingFunctions = CreateConVar("acf_fundebuggingfuncs", "0", {FCVAR_CHEAT, FCVAR_REPLICATED}, "Fun ACF debugging functions, probably not a good idea to enable this unless you know what you're doing", 0, 1)
ACF.FunDebuggingFunctions = FunDebuggingFunctions