local ACF = ACF
local Permissions = ACF.Permissions

local EditingSafezone = false
local EditName = nil

local Gizmo_mt_methods = {}
local Gizmo_mt = {__index = Gizmo_mt_methods}

local GIZMO_CYL_SIZE   = Vector(0.2, 0.2, 4)
local GIZMO_CONE_SIZE  = Vector(1.4, 1.4, 0.7)
local GIZMO_POINT_SIZE = Vector(0.5, 0.5, 0.5)

local GIZMO_CYL_TESTSIZE = GIZMO_CYL_SIZE * Vector(24, 24, 6)
local CYLINDER_OFFSET = 24
local CONE_OFFSET     = 48

local X_CYLINDER_OFFSET, X_CONE_OFFSET = Vector(CYLINDER_OFFSET, 0, 0), Vector(CONE_OFFSET, 0, 0)
local Y_CYLINDER_OFFSET, Y_CONE_OFFSET = Vector(0, CYLINDER_OFFSET, 0), Vector(0, CONE_OFFSET, 0)
local Z_CYLINDER_OFFSET, Z_CONE_OFFSET = Vector(0, 0, CYLINDER_OFFSET), Vector(0, 0, CONE_OFFSET)

local X_ROTATE = Angle(90, 0, 0)
local Y_ROTATE = Angle(0, 0, -90)
local Z_ROTATE = angle_zero

function Gizmo_mt_methods:TestDrag(Start, Dir)
	return util.IntersectRayWithPlane(Start, Dir, self.DragStartPos, self.DragStartNormal)
end

function Gizmo_mt_methods:TestAxis(Start, End, Pos, Angle)
	--[[local HookName = "QueueTest" .. SysTime()
	hook.Add("PreDrawEffects", HookName, function()
		hook.Remove("PreDrawEffects", HookName)

		render.DrawBox(Pos, Angle, -GIZMO_CYL_TESTSIZE, GIZMO_CYL_TESTSIZE, color_white)
	end)]]
	return util.IntersectRayWithOBB(Start, End, Pos, Angle, -GIZMO_CYL_TESTSIZE, GIZMO_CYL_TESTSIZE)
end

function Gizmo_mt_methods:HighlightOccured(Axis, Hit, EyeAngles)
	-- We got called because we're highlighting, so set highlight first
	self.HighlightedAxis = Axis
	-- Determine if dragging?
	if input.WasMousePressed(MOUSE_LEFT) then
		-- Enter drag mode on this axis. Save the normal and hit pos so we can build a test plane later.
		self:EnterDrag(Axis, Hit, EyeAngles)
	end
end

function Gizmo_mt_methods:HighlightFailed()
	self.HighlightedAxis = -1
end

function Gizmo_mt_methods:EnterDrag(Axis, Hit, EyeAngles)
	self.DraggingAxis = Axis
	self.DragStartPos = Hit
	self.DragStartOrigin = self.Origin

	local camForward = EyeAngles:Forward()
	self.DragStartNormal = camForward:GetNormalized()
end

function Gizmo_mt_methods:ExitDrag()
	self.DraggingAxis = -1
	self.DragStartPos = nil
	self.DragStartNormal = nil
end

local function ClosestPointOnLineToRay(R0, u, L0, v)
	local ulen = u:GetNormalized()
	local vlen = v:GetNormalized()

	local w0 = R0 - L0
	local a = ulen:Dot(ulen)
	local b = ulen:Dot(vlen)
	local c = vlen:Dot(vlen)
	local d = ulen:Dot(w0)
	local e = vlen:Dot(w0)

	local denom = (a * c - b * b)
	if math.abs(denom) < 1e-6 then
		local s = e / c
		return L0 + vlen * s
	end

	local s = (a * e - b * d) / denom
	return L0 + vlen * s
end

function Gizmo_mt_methods:DoHitTesting(Origin, Angles)
	local Hit
	local Vec = self.Origin

	if not self:IsDragging() then
		local End   = Origin + (Angles:Forward() * 4800000)
		Hit = self:TestAxis(Origin, End, Vec + X_CYLINDER_OFFSET, X_ROTATE)
		if Hit then
			self:HighlightOccured(0, Hit, Angles)
			return
		end

		Hit = self:TestAxis(Origin, End, Vec + Y_CYLINDER_OFFSET, Y_ROTATE)
		if Hit then
			self:HighlightOccured(1, Hit, Angles)
			return
		end

		Hit = self:TestAxis(Origin, End, Vec + Z_CYLINDER_OFFSET, Z_ROTATE)
		if Hit then
			self:HighlightOccured(2, Hit, Angles)
			return
		end

		self:HighlightFailed()
	else
		if not input.IsMouseDown(MOUSE_LEFT) then
			self:ExitDrag()
			return
		end

		local Axis = self.DraggingAxis
		local NewPosition = self:TestDrag(Origin, Angles:Forward())

		if not NewPosition then
			local axisVec = Vector(1, 0, 0)
			if Axis == 1 then axisVec = Vector(0, 1, 0) end
			if Axis == 2 then axisVec = Vector(0, 0, 1) end

			local RayStart = Origin
			local RayDir = Angles:Forward()
			NewPosition = ClosestPointOnLineToRay(RayStart, RayDir, self.DragStartPos, axisVec)
		end

		if NewPosition then
			local axisVec = Vector(1, 0, 0)
			if Axis == 1 then axisVec = Vector(0, 1, 0) end
			if Axis == 2 then axisVec = Vector(0, 0, 1) end

			local delta = NewPosition - self.DragStartPos
			local projected = axisVec * delta:Dot(axisVec)

			local ProposedOrigin = self.DragStartOrigin + projected
			-- Clamp the proposed origin to a trace boundary
			if not input.IsShiftDown() then
				local Test = util.TraceLine {
					start = self.Origin,
					endpos = ProposedOrigin
				}
				if Test.Hit then
					ProposedOrigin = Test.HitPos
				end
			end
			self.Origin = ProposedOrigin
		end
	end
end

function Gizmo_mt_methods:IsHighlighted(Axis)
	return self.HighlightedAxis ~= (Axis or -1)
end

function Gizmo_mt_methods:IsDragging(Axis)
	return self.DraggingAxis ~= (Axis or -1)
end

function Gizmo_mt_methods:Init(Position)
	self.Origin = Position or Vector(0, 0, 0)
	self.HighlightedAxis = -1
	self.DraggingAxis = -1
	self.DragStartPos = nil
	self.DragStartNormal = nil
end

if IsValid(ACF.SafezoneEdit_Cone) then ACF.SafezoneEdit_Cone:Destroy() end
if IsValid(ACF.SafezoneEdit_Cylinder) then ACF.SafezoneEdit_Cylinder:Destroy() end
if IsValid(ACF.SafezoneEdit_Sphere) then ACF.SafezoneEdit_Sphere:Destroy() end
local RenderMaterial = CreateMaterial("acf_editsafezone_colormat", "UnlitGeneric", {
	["$basetexture"] = "color/white",
	["$vertexcolor"] = 1,
	["$vertexalpha"] = 1
})

local function VerifyRequiredModels()
	if not IsValid(ACF.SafezoneEdit_Cone) then
		ACF.SafezoneEdit_Cone = Mesh(RenderMaterial)
		ACF.SafezoneEdit_Cone:BuildFromTriangles(util.GetModelMeshes("models/holograms/hq_cone.mdl")[1].triangles)
	end
	if not IsValid(ACF.SafezoneEdit_Cylinder) then
		ACF.SafezoneEdit_Cylinder = Mesh(RenderMaterial)
		ACF.SafezoneEdit_Cylinder:BuildFromTriangles(util.GetModelMeshes("models/holograms/hq_cylinder.mdl")[1].triangles)
	end
	if not IsValid(ACF.SafezoneEdit_Sphere) then
		ACF.SafezoneEdit_Sphere = Mesh(RenderMaterial)
		ACF.SafezoneEdit_Sphere:BuildFromTriangles(util.GetModelMeshes("models/holograms/hq_sphere.mdl")[1].triangles)
	end
	return ACF.SafezoneEdit_Cone, ACF.SafezoneEdit_Cylinder, ACF.SafezoneEdit_Sphere
end

-- this sucks but idc rn its an editor
local RED, GREEN, BLUE = Color(255, 50, 50), Color(50, 255, 50), Color(50, 50, 255)
local function DrawModel(Mesh, Color, Position, Angle, Scale)
	local M = Matrix()
	M:Translate(Position)
	M:Rotate(Angle)
	M:Scale(Scale)

	-- this REALLY sucks wow
	RenderMaterial:SetVector("$color", Vector(Color.r / 255, Color.g / 255, Color.b / 255))
	RenderMaterial:Recompute()

	cam.PushModelMatrix(M)
	render.SetMaterial(RenderMaterial)
		Mesh:Draw()
	cam.PopModelMatrix()
end

local BACKGROUND = Color(31, 31, 31, 237)
local TEXT       = Color(245, 245, 245, 255)

function Gizmo_mt_methods:Draw()
	local Cone, Cylinder, Sphere = VerifyRequiredModels()
	local Pos = self.Origin
	local Highlighted = self.HighlightedAxis
	local Dragging = self.DraggingAxis
	local R, G, B = RED, GREEN, BLUE
	if Highlighted == 0 or Dragging == 0 then
		R = R:Copy()
		R:SetSaturation(0.4)
	elseif Highlighted == 1 or Dragging == 1 then
		G = G:Copy()
		G:SetSaturation(0.4)
	elseif Highlighted == 2 or Dragging == 2 then
		B = B:Copy()
		B:SetSaturation(0.4)
	end

	if Dragging ~= -1 then
		if Dragging ~= 0 then
			R = R:Copy()
			R:SetBrightness(0.4)
		end
		if Dragging ~= 1 then
			G = G:Copy()
			G:SetBrightness(0.4)
		end
		if Dragging ~= 2 then
			B = B:Copy()
			B:SetBrightness(0.4)
		end
	end

	DrawModel(Sphere, color_white, Pos, angle_zero, GIZMO_POINT_SIZE)

	DrawModel(Cylinder, R, Pos + X_CYLINDER_OFFSET, X_ROTATE, GIZMO_CYL_SIZE)
	DrawModel(Cone, R, Pos + X_CONE_OFFSET, X_ROTATE, GIZMO_CONE_SIZE)

	DrawModel(Cylinder, G, Pos + Y_CYLINDER_OFFSET, Y_ROTATE, GIZMO_CYL_SIZE)
	DrawModel(Cone, G, Pos + Y_CONE_OFFSET, Y_ROTATE, GIZMO_CONE_SIZE)

	DrawModel(Cylinder, B, Pos + Z_CYLINDER_OFFSET, Z_ROTATE, GIZMO_CYL_SIZE)
	DrawModel(Cone, B, Pos + Z_CONE_OFFSET, Z_ROTATE, GIZMO_CONE_SIZE)

	cam.Start2D()
		local Pos2D = Pos:ToScreen()
		local x, y = Pos2D.x, Pos2D.y
		local w, h = 48, 32
		draw.RoundedBox(2, x - (w / 2), y - (h / 2), w, h, BACKGROUND)
		draw.SimpleText(self.ID == 1 and "Min" or "Max", "DermaLarge", x, y, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End2D()
end

local function Gizmo(ID)
	local Instance = setmetatable({ID = ID}, Gizmo_mt)
	Instance:Init()
	return Instance
end

local EditMin, EditMax = Gizmo(1), Gizmo(2)

local posOffset = Vector(-35, 0, 70)
local angOffset = Angle(0, 0, 0)
local mouseZoom = 300 -- source units a second
local lastCalc = CurTime()

local lastAng
hook.Add("PlayerButtonDown", "ACF_Scanner_BlockInputs", function(_, btn)
	if EditingSafezone then
		if btn == KEY_C then
			gui.EnableScreenClicker(true)
		end
		return true
	end
end)

hook.Add("PlayerButtonUp", "ACF_Scanner_BlockInputs", function()
	if EditingSafezone then
		gui.EnableScreenClicker(false)
	end
end)
local function AddMouseZoom(zoom)
	mouseZoom = mouseZoom + zoom
	mouseZoom = math.Clamp(mouseZoom, 50, 1000000)
end

hook.Add("CreateMove", "ACF_SafezoneCreation_BlockInputs", function(cmd)
	if EditingSafezone then
		if lastAng == nil then
			lastAng = cmd:GetViewAngles()
		end

		local delta = cmd:GetViewAngles() - lastAng
		angOffset = angOffset + delta
		angOffset.pitch = math.Clamp(angOffset.pitch, -90, 90)
		cmd:SetViewAngles(lastAng)
		lastAng = cmd:GetViewAngles()

		local wheel = cmd:GetMouseWheel()
		if wheel ~= 0 then
			AddMouseZoom(50 * wheel)
		end
		cmd:ClearMovement()
		cmd:ClearButtons()

		EditMin:DoHitTesting(posOffset, angOffset)
		EditMax:DoHitTesting(posOffset, angOffset)
	else
		lastAng = nil
	end
end)

hook.Add("CalcView", "ACF_SafezoneCreation_CalcView", function(_, pos, ang, fov, znear, zfar)
	if not EditingSafezone then return end

	local xMove, yMove, zMove = 0, 0, 0

	local appliedZoom = mouseZoom * (CurTime() - lastCalc)

	if not IsValid(vgui.GetKeyboardFocus()) then
		if input.IsKeyDown(KEY_W)        then xMove = xMove + appliedZoom end
		if input.IsKeyDown(KEY_S)        then xMove = xMove - appliedZoom end
		if input.IsKeyDown(KEY_A)        then yMove = yMove + appliedZoom end
		if input.IsKeyDown(KEY_D)        then yMove = yMove - appliedZoom end
		if input.IsKeyDown(KEY_LCONTROL) then zMove = zMove - appliedZoom end
		if input.IsKeyDown(KEY_SPACE)    then zMove = zMove + appliedZoom end
	end

	ang = angOffset
	posOffset = posOffset + (
		(ang:Forward() * xMove) +
		(ang:Right() * -yMove) +
		vector_up * zMove
	)

	pos = posOffset

	lastCalc = CurTime()

	return {
		origin = pos,
		angles = ang,
		fov = fov,
		znear = znear,
		zfar = zfar,
		drawviewer = true
	}
end)

hook.Add("PreDrawEffects", "ACF_SafezoneCreation_PreDrawEffects", function()
	if not EditingSafezone then return end

	EditMin:Draw()
	EditMax:Draw()
	render.DrawWireframeBox(vector_origin, angle_zero, EditMin.Origin, EditMax.Origin, TEXT, false)
end)

local function CancelSafezone()
	EditingSafezone = false
	EditName = nil
	if IsValid(ACF.EditingSafezoneUI) then ACF.EditingSafezoneUI:Remove() end
	hook.Remove("HUDShouldDraw", "ACF_SafezoneCreation_HUDShouldDraw")
end
CancelSafezone()

local function SaveSafezone()
	if not EditingSafezone then return end

	RunConsoleCommand("acf_addsafezone", EditName,
		tostring(EditMin.Origin.x), tostring(EditMin.Origin.y), tostring(EditMin.Origin.z),
		tostring(EditMax.Origin.x), tostring(EditMax.Origin.y), tostring(EditMax.Origin.z))
	RunConsoleCommand("acf_savesafezones")
	CancelSafezone()
end

local function BeginEditSafezone(_, SafezoneName, Min, Max)
	CancelSafezone()
	lastCalc = CurTime()

	if SafezoneName then
		Min, Max = unpack(Permissions.Safezones[SafezoneName])
	end
	EditingSafezone = true
	EditName = SafezoneName
	EditMin:Init(Min)
	EditMax:Init(Max)

	posOffset = (Max + Min) / 2

	hook.Add("HUDShouldDraw", "ACF_SafezoneCreation_HUDShouldDraw", function(element)
		if element == "CHudWeaponSelection" then return false end
	end)

	local UI = vgui.Create("DPanel")
	ACF.EditingSafezoneUI = UI
	UI:Dock(BOTTOM)
	UI:SetSize(0, 64)
	UI:SetPaintBackground(false)

	local Save = UI:Add("DButton")
	Save:SetText(SafezoneName and "Save safezone '" .. SafezoneName .. "'" or "Save new safezone")
	Save:SetSize(300, 48)

	local Cancel = UI:Add("DButton")
	Cancel:SetText("Cancel")
	Cancel:SetSize(300, 48)

	function Save:DoClick()
		if SafezoneName then
			SaveSafezone()
		else
			-- Prompt
			local TryPrompt, TryEnter
			function TryEnter(Name)
				Name = string.Trim(Name)

				if not Name or #Name == 0 then
					Derma_Query("Must provide a name!", "No name provided", "Back to Editor", function() end, "Try Again", TryPrompt)
				elseif Permissions.Safezones[Name] then
					Derma_Query("A safezone with the name '" .. Name .. "' already exists.", "Safezone name not unique", "Back to Editor", function() end, "Try Again", TryPrompt)
				else
					EditName = Name
					SaveSafezone()
				end
			end
			function TryPrompt()
				Derma_StringRequest("Enter a name for the safezone.", "Must be unique!", "", function() end, TryEnter, "Back to Editor", "Save")
			end
			TryPrompt()
		end
	end

	function Cancel:DoClick()
		CancelSafezone()
	end

	function UI:PerformLayout(w, h)
		local Padding = 4
		Save:SetPos((w / 2) - (Save:GetWide() / 1) - Padding, (h / 2) - (Save:GetTall() / 2))
		Cancel:SetPos((w / 2) + Padding, (h / 2) - (Cancel:GetTall() / 2))
	end
end

local function BeginNewSafezone()
	BeginEditSafezone(nil, nil, LocalPlayer():GetPos() - Vector(256, 256, 0), LocalPlayer():GetPos() + Vector(256, 256, 512))
end

concommand.Add("acf_beginnewsafezone", function()
	BeginNewSafezone()
end)

concommand.Add("acf_begineditsafezone", function(_, _, args)
	if not Permissions.Safezones[args[1]] then return print("No such safezone.") end
	BeginEditSafezone(_, args[1])
end)

do
	local function RequestSafezones()
		net.Start("ACF_OnUpdateSafezones")
		net.SendToServer()
	end

	timer.Simple(0, function()
		RequestSafezones()
	end)

	local function CreateMenu(Menu)
		Menu:AddTitle("Safezones")

		ACF.SetToolMode("acf_menu", "ZoneModifier", "Update")

		local SafezonesBase = Menu:AddCollapsible("#acf.menu.permissions.safezones", nil, "icon16/lock_edit.png")
		SafezonesBase:AddCheckBox("#acf.menu.permissions.safezones.enable"):LinkToServerData("EnableSafezones")
		SafezonesBase:AddHelp("#acf.menu.permissions.safezones.enable_desc")
		SafezonesBase:AddCheckBox("#acf.menu.permissions.safezones.noclip"):LinkToServerData("NoclipOutsideZones")
		local List = SafezonesBase:AddListView()
		List:AddColumn("#acf.menu.permissions.safezones.all")

		local function Update()
			if not IsValid(List) then return end
			for Safezone in pairs(Permissions.Safezones) do
				List:AddLine(Safezone)
			end
		end
		Update()

		SafezonesBase:AddButton("#acf.menu.permissions.safezones.new", "acf_beginnewsafezone")
		SafezonesBase:AddButton("#acf.menu.permissions.safezones.reload", function()
			RunConsoleCommand("acf_reloadsafezones")
			List:Clear()
			hook.Add("ACF_OnUpdateSafezones", "ACF_UpdatePanel", function()
				hook.Remove("ACF_OnUpdateSafezones", "ACF_UpdatePanel")
				Update()
			end)
		end)
	end

	ACF.AddMenuItem(3, "#acf.menu.permissions", "Safezones", "shield", CreateMenu)
end