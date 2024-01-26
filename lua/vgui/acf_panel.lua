local PANEL     = {}
local ACF       = ACF
local ModelData = ACF.ModelData

DEFINE_BASECLASS("Panel")

-- Panels don't have a CallOnRemove function
-- This roughly replicates the same behavior
local function AddOnRemove(Panel, Parent)
	local OldRemove = Panel.Remove

	function Panel:Remove()
		Parent:EndTemporal(self)
		Parent:ClearTemporal(self)

		Parent.Items[self] = nil

		for TempParent in pairs(self.TempParents) do
			TempParent.TempItems[self] = nil
		end

		if self == Parent.LastItem then
			Parent.LastItem = self.PrevItem
		end

		if IsValid(self.PrevItem) then
			self.PrevItem.NextItem = self.NextItem
		end

		if IsValid(self.NextItem) then
			self.NextItem.PrevItem = self.PrevItem
		end

		OldRemove(self)
	end
end

function PANEL:Init()
	self.Items = {}
	self.TempItems = {}
end

function PANEL:ClearAll()
	for Item in pairs(self.Items) do
		Item:Remove()
	end

	self:Clear()
end

function PANEL:ClearTemporal(Panel)
	local Target = IsValid(Panel) and Panel or self

	if not Target.TempItems then return end

	for K in pairs(Target.TempItems) do
		K:Remove()
	end
end

local TemporalPanels = {}

function PANEL:StartTemporal(Panel)
	local Target = IsValid(Panel) and Panel or self

	if not Target.TempItems then
		Target.TempItems = {}
	end

	TemporalPanels[Target] = true
end

function PANEL:EndTemporal(Panel)
	local Target = IsValid(Panel) and Panel or self

	TemporalPanels[Target] = nil
end

function PANEL:ClearAllTemporal()
	for Panel in pairs(TemporalPanels) do
		self:EndTemporal(Panel)
		self:ClearTemporal(Panel)
	end
end

function PANEL:AddPanel(Name)
	if not Name then return end

	local Panel = vgui.Create(Name, self)

	if not IsValid(Panel) then return end

	Panel:Dock(TOP)
	Panel:DockMargin(0, 0, 0, 10)
	Panel:InvalidateParent()
	Panel:InvalidateLayout()
	Panel.TempParents = {}

	self:InvalidateLayout()
	self.Items[Panel] = true

	local LastItem = self.LastItem

	if IsValid(LastItem) then
		LastItem.NextItem = Panel

		Panel.PrevItem = LastItem

		for Temp in pairs(LastItem.TempParents) do
			Panel.TempParents[Temp] = true
			Temp.TempItems[Panel] = true
		end
	end

	self.LastItem = Panel

	for Temp in pairs(TemporalPanels) do
		Panel.TempParents[Temp] = true
		Temp.TempItems[Panel] = true
	end

	AddOnRemove(Panel, self)

	return Panel
end

function PANEL:AddButton(Text, Command, ...)
	local Panel = self:AddPanel("DButton")
	Panel:SetText(Text or "Button")
	Panel:SetFont("ACF_Control")

	if Command then
		Panel:SetConsoleCommand(Command, ...)
	end

	return Panel
end

function PANEL:AddCheckBox(Text)
	local Panel = self:AddPanel("DCheckBoxLabel")
	Panel:SetText(Text or "Checkbox")
	Panel:SetFont("ACF_Control")
	Panel:SetDark(true)

	return Panel
end

function PANEL:AddTitle(Text)
	local Panel = self:AddPanel("DLabel")
	Panel:SetAutoStretchVertical(true)
	Panel:SetText(Text or "Text")
	Panel:SetFont("ACF_Title")
	Panel:SetWrap(true)
	Panel:SetDark(true)

	return Panel
end

function PANEL:AddLabel(Text)
	local Panel = self:AddTitle(Text)
	Panel:SetFont("ACF_Label")

	return Panel
end

function PANEL:AddHelp(Text)
	local TextColor = self:GetSkin().Colours.Tree.Hover
	local Panel = self:AddLabel(Text)
	Panel:DockMargin(10, 0, 10, 10)
	Panel:SetTextColor(TextColor)
	Panel:InvalidateLayout()

	return Panel
end

function PANEL:AddComboBox()
	local Panel = self:AddPanel("DComboBox")
	Panel:SetFont("ACF_Control")
	Panel:SetSortItems(false)
	Panel:SetDark(true)
	Panel:SetWrap(true)

	return Panel
end

function PANEL:AddSlider(Title, Min, Max, Decimals)
	local Panel = self:AddPanel("DNumSlider")
	Panel:DockMargin(0, 0, 0, 5)
	Panel:SetDecimals(Decimals or 0)
	Panel:SetText(Title or "")
	Panel:SetMinMax(Min, Max)
	Panel:SetValue(Min)
	Panel:SetDark(true)

	Panel.Label:SetFont("ACF_Control")

	return Panel
end

function PANEL:AddNumberWang(Label, Min, Max, Decimals)
	local Base = self:AddPanel("ACF_Panel")

	local Wang = Base:Add("DNumberWang")
	Wang:SetDecimals(Decimals or 0)
	Wang:SetMinMax(Min, Max)
	Wang:SetTall(20)
	Wang:Dock(RIGHT)

	local Text = Base:Add("DLabel")
	Text:SetText(Label or "Text")
	Text:SetFont("ACF_Control")
	Text:SetDark(true)
	Text:Dock(TOP)

	return Wang, Text
end

function PANEL:AddCollapsible(Text, State)
	if State == nil then State = true end

	local Base = vgui.Create("ACF_Panel")
	Base:DockMargin(5, 5, 5, 10)

	local Category = self:AddPanel("DCollapsibleCategory")
	Category:SetLabel(Text or "Title")
	Category:DoExpansion(State)
	Category:SetContents(Base)

	return Base, Category
end

-- Lerps linearly between two matrices
-- This is in no way correct, but works fine for this purpose
-- Matrices need to be affine, shear is not preserved
local function LerpMatrix(A, B, t)
	if not A:IsRotationMatrix() or not B:IsRotationMatrix() then
		return B
	end

	t = math.Clamp(t, 0, 1)

	local Pos = A:GetTranslation() * (1 - t) + B:GetTranslation() * t

	-- rotate A angle towards B angle
	local Ang = A:GetAngles()
	local A_Dir = A:GetForward()
	local B_Dir = B:GetForward()

	local Dot = A_Dir:Dot(B_Dir)
	if Dot < 0.999999 then
		local RotAxis = A_Dir:Cross(B_Dir)
		RotAxis:Normalize()

		local RotAngle = 180 / math.pi * math.acos(Dot)
		Ang:RotateAroundAxis(RotAxis, RotAngle * t)
	end

	local Scale = A:GetScale() * (1 - t) + B:GetScale() * t

	local C = Matrix()
	C:SetTranslation(Pos)
	C:SetAngles(Ang)
	C:SetScale(Scale)

	return C
end

-- Rotates the matrix roll towards zero
local function RotateMatrixRollToZero(A, t)
	local Angles = A:GetAngles()
	Angles:RotateAroundAxis(A:GetForward(), -t * Angles.r)

	local B = Matrix(A)
	B:SetAngles(Angles)

	return B
end

-- Returns the distance from P to the closest point on a box
-- From https://iquilezles.org/articles/distfunctions/
local function BoxSDF(P, Box)
	local Q = Vector(math.abs(P.x), math.abs(P.y), math.abs(P.z)) - Box

	local D1 = Vector(math.max(0, Q.x), math.max(0, Q.y), math.max(0, Q.z)):Length()
	local D2 = math.min(math.max(Q.x, math.max(Q.y, Q.z)), 0)

	return D1 + D2
end

function PANEL:AddModelPreview(Model, Rotate)
	local Settings = {
		Height   = 120,
		FOV      = 60,

		Pitch    = 15,				-- Default pitch angle, camera will kinda bob up and down with nonzero setting
		Rotation = Angle(0, -35, 0) -- Default rotation rate
	}

	local Panel    = self:AddPanel("DModelPanel")
	Panel.Rotate   = tobool(Rotate)
	Panel.Settings = Settings -- Storing the default settings

	Panel.IsMouseDown = false
	Panel.InitialMouseOffset = Vector(0, 0)
	Panel.LastMouseOffset = Vector(0, 0)

	Panel.RotationDirection = 1

	function Panel:SetRotateModel(Bool)
		self.Rotate = tobool(Bool)
	end

	function Panel:DrawEntity(Bool)
		local Entity = self:GetEntity()

		if IsValid(Entity) then
			Entity:SetNoDraw(not Bool)
		end

		self.NotDrawn = not Bool
	end

	function Panel:UpdateModel(Path, Material)
		if not isstring(Path) then
			return self:DrawEntity(false)
		end

		local Center = ModelData.GetModelCenter(Path)

		if not Center then
			if ModelData.IsOnStandby(Path) then
				ModelData.QueueRefresh(Path, self, function()
					self:UpdateModel(Path)
				end)
			end

			return self:DrawEntity(false)
		end

		local Size = ModelData.GetModelSize(Path)

		local StartMatrix = Matrix()

		-- looks a bit nicer with this
		if string.find(Path, "engines") ~= nil then
			StartMatrix:Rotate(Angle(self.Settings.Pitch, 0, 0))
		elseif string.find(Path, "reciever") ~= nil then
			StartMatrix:Rotate(Angle(self.Settings.Pitch, 180, 0))
		else
			StartMatrix:Rotate(Angle(self.Settings.Pitch, -90, 0))
		end

		self.RotMatrix = Matrix(StartMatrix)
		self.TargetRotMatrix = Matrix(StartMatrix)

		self.CamCenter = Center
		self.CamDistance = 1.2 * math.max(Size.x, math.max(Size.y, Size.z))

		self.BoxSize = Vector(Size) -- Used for zooming

		self.CamDistanceMul = 1
		self.CamDistanceMulTarget = 1

		self:DrawEntity(true)
		self:SetModel(Path)
		self:SetCamPos(Center + Vector(-self.CamDistance, 0, 0))

		if Material then
			local Entity = self:GetEntity()

			Entity:SetMaterial(Material)
		end
	end

	function Panel:UpdateSettings(Data)
		if not istable(Data) then Data = nil end

		self:SetHeight(Data and Data.Height or Settings.Height)
		self:SetFOV(Data and Data.FOV or Settings.FOV)
	end

	function Panel:OnMousePressed(Button)
		if Button ~= MOUSE_LEFT then return end

		local MouseOffset = Vector(self:ScreenToLocal(input.GetCursorPos()))

		if MouseOffset:WithinAABox(Vector(0, 0, -1), Vector(self:GetWide(), self:GetTall(), 1)) then
			self.IsMouseDown = true
			self.InitialMouseOffset = MouseOffset
			self.LastMouseOffset = MouseOffset
		end
	end

	function Panel:OnMouseReleased_impl(Button)
		if Button ~= MOUSE_LEFT then return end

		self.IsMouseDown = false

		-- Reset target angles
		self.TargetRotMatrix:SetAngles(Angle(self.Settings.Pitch, self.TargetRotMatrix:GetAngles().y, 0))

		-- Find what direction user was rotating, and keep rotating in the same direction
		local YawDiff = self.TargetRotMatrix:GetAngles().y - self.RotMatrix:GetAngles().y
		self.RotationDirection = (YawDiff <= 0) and 1 or -1
	end

	function Panel:OnMouseReleased(Button)
		self:OnMouseReleased_impl(Button)
	end

	function Panel:LayoutEntity()
		if self.NotDrawn then return end

		if self.bAnimated then
			self:RunAnimation()
		end

		if not self.Rotate then return end
		if not self.RotMatrix then return end

		-- Handle mouse movement
		if self.IsMouseDown then
			local MouseOffset = Vector(self:ScreenToLocal(input.GetCursorPos()))
			local Delta = MouseOffset - self.LastMouseOffset

			-- Rotate towards mouse movement
			local Rotation = Angle(Delta.y * 0.7, -Delta.x, 0) * FrameTime() * 48

			Rotation.p = math.Clamp(Rotation.p, -5, 5)
			Rotation.y = math.Clamp(Rotation.y, -15, 15)

			self.TargetRotMatrix:Rotate(Rotation)

			self.LastMouseOffset = MouseOffset
		else
			-- Spin around like normal when not panning
			self.TargetRotMatrix:Rotate(self.Settings.Rotation * FrameTime() * self.RotationDirection)
		end

		-- Lerp rotation towards target
		local LerpT = math.Clamp(FrameTime() * 4, 0.05, 0.3)
		self.RotMatrix = LerpMatrix(self.RotMatrix, self.TargetRotMatrix, LerpT)

		-- Rotate roll towards zero when not panning
		if not self.IsMouseDown then
			self.RotMatrix = RotateMatrixRollToZero(self.RotMatrix, LerpT * 0.25)
		end

		-- Compute zoom distance
		if self.IsMouseDown and input.IsMouseDown(MOUSE_RIGHT) then
			local DistToBox = BoxSDF(self.RotMatrix * Vector(-self.CamDistance, 0, 0), self.BoxSize)
			local Fraction = math.pow(1 - DistToBox / self.CamDistance, 0.5)

			self.CamDistanceMulTarget = Fraction
		else
			self.CamDistanceMulTarget = 1
		end

		-- Lerp distance towards target
		self.CamDistanceMul = self.CamDistanceMul + (self.CamDistanceMulTarget - self.CamDistanceMul) * LerpT * 0.5

		local CamTransform = Matrix()
		CamTransform:Translate(self.CamCenter)
		CamTransform:Rotate(self.RotMatrix:GetAngles())
		CamTransform:Translate(Vector(-self.CamDistance * self.CamDistanceMul, 0, 0))

		self:SetLookAng(CamTransform:GetAngles())
		self:SetCamPos(CamTransform:GetTranslation())

		-- Mousedown state gets "stuck" if cursor is outside the panel when releasing, so, adding this
		if self.IsMouseDown and not input.IsMouseDown(MOUSE_LEFT) then
			self:OnMouseReleased_impl(MOUSE_LEFT)
		end
	end

	Panel:UpdateModel(Model)
	Panel:UpdateSettings()

	return Panel
end

function PANEL:PerformLayout()
	self:SizeToChildren(true, true)
end

function PANEL:GenerateExample()
end

derma.DefineControl("ACF_Panel", "", PANEL, "Panel")