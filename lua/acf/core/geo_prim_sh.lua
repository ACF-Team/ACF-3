local ACF = ACF

-- GeoPrim: a minimal geometric-primitive tree for describing what a projectile is physically made of.
-- Ammo types build one of these once (in UpdateRoundData / BaseConvert), and it becomes the single
-- source of truth for both the ammo menu's 2D visualizer AND any volume-derived quantity (e.g. an
-- explosive filler's mass) that currently gets hand-rolled per ammo type. Primitives are laid out
-- end-to-end along a single local axis ("X" = down the length of the round); Offset is a scalar
-- distance along that axis, not a full 3D position, since every round ACF models is axially symmetric.
--
-- Each shape ("Cylinder", "Cone", "Box") is its own subclass rather than a tag switched on everywhere:
-- GeoPrim.New dispatches to the matching subclass, and GetLength/GetRadius/GetShapeVolume/DrawShape are
-- overridden per shape instead of branching on self.Shape at every call site.
local GeoPrim = {}
GeoPrim.__index = GeoPrim

ACF.GeoPrim = GeoPrim

local Shapes = {}

-- Registers a shape subclass under Name (e.g. "Cylinder"), inheriting the base GeoPrim methods.
-- Returns the new class table for the caller to fill in with GetLength/GetRadius/GetShapeVolume/DrawShape.
local function DefineShape(Name)
	local Class = setmetatable({}, { __index = GeoPrim })
	Class.__index = Class
	Shapes[Name] = Class
	return Class
end

-- Shape is one of "Cylinder" (Radius, Height), "Cone" (Radius, TipRadius, Height -- a frustum; TipRadius
-- defaults to 0 for a true point), or "Box" (SizeX, SizeY, SizeZ). Height/SizeX run along the axis.
function GeoPrim.New(Shape, Params)
	local Class = Shapes[Shape]

	if not Class then error("GeoPrim.New: unknown shape '" .. tostring(Shape) .. "'", 2) end

	return setmetatable({
		Params    = Params or {},
		Offset    = 0,     -- distance along the parent's axis where this primitive starts
		Material  = nil,   -- descriptive label shown in visualizer tooltips, e.g. "Steel Penetrator"
		IsVoid    = false, -- true for cavities (hollow point, shaped-charge liner): subtracts volume instead of adding it
		Children  = {},
		CachedVol = nil,
	}, Class)
end

function GeoPrim:SetOffset(Offset)
	self.Offset = Offset
	return self
end

function GeoPrim:SetMaterial(Material)
	self.Material = Material
	return self
end

function GeoPrim:SetVoid(IsVoid)
	self.IsVoid = IsVoid
	return self
end

-- Adds Child as a sub-primitive positioned Offset units along this primitive's axis. Returns Child so
-- calls can be chained: Parent:AddChild(GeoPrim.New(...)):SetMaterial(...).
function GeoPrim:AddChild(Child, Offset)
	Child.Offset = Offset or Child.Offset
	self.Children[#self.Children + 1] = Child
	self.CachedVol = nil
	return Child
end

-- Cached volume of this primitive plus its children, with void children (cavities) subtracted rather
-- than added. Units follow whatever units Params was built with (ACF round geometry is in cm, so this
-- comes out in cm^3). Cache is invalidated automatically by AddChild; call :Invalidate() after mutating
-- Params or IsVoid directly.
function GeoPrim:GetVolume()
	if self.CachedVol then return self.CachedVol end

	local Total = self:GetShapeVolume()

	for _, Child in ipairs(self.Children) do
		local ChildVol = Child:GetVolume()
		Total = Total + (Child.IsVoid and -ChildVol or ChildVol)
	end

	Total = math.max(Total, 0)
	self.CachedVol = Total
	return Total
end

function GeoPrim:Invalidate()
	self.CachedVol = nil
end

-- Builds the tooltip text for a hover region: the material name plus this primitive's own bounding
-- box (length x diameter), converted from cm (the units ACF round geometry is built in) to mm.
function GeoPrim:GetRegionLabel()
	local LengthMm   = math.Round(self:GetLength() * 10)
	local DiameterMm = math.Round(self:GetRadius() * 2 * 10)

	return ("%s\n%dx%d mm"):format(self.Material, DiameterMm, LengthMm)
end

-- Draws this primitive's side-profile silhouette into an ammo visualizer panel (see acf_panel.lua's
-- Panel:AddVisualizer/AddRegion) and recurses into children. X is this primitive's own left edge in
-- panel pixels; a child's edge is X + Child.Offset * Scale. MaxDiameterPx clamps how tall the shape is
-- allowed to draw regardless of physical radius, so an oversized caliber doesn't blow out the panel.
-- Void children are drawn in Panel's background color on top of their parent, so cavities read as a
-- visible cut rather than requiring real polygon subtraction. The shape-specific rasterization lives in
-- each subclass's :DrawShape.
function GeoPrim:Draw(Panel, X, CenterY, Scale, MaxDiameterPx, Color, BGColor)
	local LengthPx = self:GetLength() * Scale

	if LengthPx > 0 then
		local DrawColor = self.IsVoid and (BGColor or Color(40, 40, 45)) or Color

		self:DrawShape(Panel, X, CenterY, Scale, MaxDiameterPx, LengthPx, DrawColor)
	end

	for _, Child in ipairs(self.Children) do
		Child:Draw(Panel, X + Child.Offset * Scale, CenterY, Scale, MaxDiameterPx, Color, BGColor)
	end

	return X + LengthPx
end

----------------------------------------------------------------------------------------------------
-- Group: no Params -- a shapeless node that exists purely to parent other primitives under one label.
-- Draws no fill of its own, but registers a single hover region spanning its children's full bounding
-- box, so e.g. a penetrator's cylindrical body and its tapered nose -- two different shapes that must
-- be separate GeoPrims to draw correctly -- can still read as one "Steel Penetrator" on hover instead
-- of two independently-hoverable pieces. GetVolume() already sums a primitive's children regardless of
-- its own shape, so a Group's total volume/mass falls out of the existing recursion for free.
----------------------------------------------------------------------------------------------------

local Group = DefineShape("Group")

function Group:GetLength()
	local Farthest = 0

	for _, Child in ipairs(self.Children) do
		Farthest = math.max(Farthest, Child.Offset + Child:GetLength())
	end

	return Farthest
end

function Group:GetRadius()
	local Radius = 0

	for _, Child in ipairs(self.Children) do
		Radius = math.max(Radius, Child:GetRadius())
	end

	return Radius
end

function Group:GetShapeVolume()
	return 0 -- a Group has no geometry of its own; its total volume is entirely its children's
end

function Group:DrawShape(Panel, X, CenterY, Scale, MaxDiameterPx, LengthPx)
	if not self.Material then return end

	local DiaPx = math.min(self:GetRadius() * 2 * Scale, MaxDiameterPx)

	Panel:AddRegion(X, CenterY - DiaPx * 0.5, LengthPx, DiaPx, self:GetRegionLabel())
end

----------------------------------------------------------------------------------------------------
-- Cylinder: Params = { Radius, Height }
----------------------------------------------------------------------------------------------------

local Cylinder = DefineShape("Cylinder")

-- Shared by Cylinder and Box, both of which draw as a plain axis-aligned rect. Top/Bottom are rounded
-- outward (floor/ceil) rather than passing float y/height straight to DrawRect: Cone rounds its own
-- radius outward the same way (see Cone:DrawShape), and this class's radius is often flush against a
-- cone's base (e.g. a projectile body meeting its nose cone) -- if only one side rounded outward, the
-- seam between the two shapes would show a 1px step where the "same" radius resolved to different pixel
-- widths.

local function DrawRect(self, Panel, X, CenterY, Scale, MaxDiameterPx, LengthPx, DrawColor)
	local RadiusPx = math.min(self:GetRadius() * Scale, MaxDiameterPx * 0.5)
	local Top      = math.floor(CenterY - RadiusPx)
	local Bottom   = math.ceil(CenterY + RadiusPx)

	draw.NoTexture()
	surface.SetDrawColor(DrawColor)
	surface.DrawRect(X, Top, LengthPx, Bottom - Top)

	if self.Material then
		Panel:AddRegion(X, Top, LengthPx, Bottom - Top, self:GetRegionLabel())
	end

	return RadiusPx, Top, Bottom
end

local MATERIAL_CYLINDER_MAIN_GRADIENT   = Material("gui/center_gradient")
local function DrawCylinder(self, Panel, X, CenterY, Scale, MaxDiameterPx, LengthPx, DrawColor)
	local _, Top, Bottom = DrawRect(self, Panel, X, CenterY, Scale, MaxDiameterPx, LengthPx, DrawColor)

	local GradientColor = DrawColor:Copy()
	GradientColor:AddBrightness(0.2)
	GradientColor.a = 255
	surface.SetMaterial(MATERIAL_CYLINDER_MAIN_GRADIENT)
	surface.SetDrawColor(GradientColor)

	local Width = LengthPx
	local Height = Bottom - Top

	surface.SetMaterial(MATERIAL_CYLINDER_MAIN_GRADIENT)
	surface.SetDrawColor(GradientColor)
	surface.DrawTexturedRectRotated(X + (Width * 0.5), Top + (Height * 0.5), Height, Width, 90)
end

function Cylinder:GetLength()
	return self.Params.Height or 0
end

function Cylinder:GetRadius()
	return self.Params.Radius or 0
end

function Cylinder:GetShapeVolume()
	local R, H = self.Params.Radius or 0, self.Params.Height or 0
	return math.pi * R * R * H
end

Cylinder.DrawShape = DrawCylinder

----------------------------------------------------------------------------------------------------
-- Cone: Params = { Radius, TipRadius, Height } -- a frustum; TipRadius defaults to 0 for a true point
----------------------------------------------------------------------------------------------------

local Cone = DefineShape("Cone")

function Cone:GetLength()
	return self.Params.Height or 0
end

function Cone:GetRadius()
	local P = self.Params
	return math.max(P.Radius or 0, P.TipRadius or 0)
end

function Cone:GetShapeVolume()
	local P = self.Params
	local R1, R2, H = P.Radius or 0, P.TipRadius or 0, P.Height or 0
	return (math.pi * H / 3) * (R1 * R1 + R1 * R2 + R2 * R2) -- frustum volume
end

function Cone:DrawShape(Panel, X, CenterY, Scale, MaxDiameterPx, LengthPx, DrawColor)
	local P    = self.Params
	local R1Px = math.min((P.Radius or 0) * Scale, MaxDiameterPx * 0.5)
	local R2Px = math.min((P.TipRadius or 0) * Scale, MaxDiameterPx * 0.5)

	-- Rasterized as a stack of columns rather than surface.DrawPoly: a triangle/frustum
	-- polygon here rendered inconsistently (and sometimes not at all) across GMod versions
	-- regardless of vertex winding, so this sidesteps DrawPoly entirely for tapered shapes.
	--
	-- Columns are walked at whole-pixel boundaries (not fractional LengthPx/Cols slices) --
	-- surface.DrawRect rounds x and w independently, so two adjacent fractional-width rects
	-- can round to boundaries that don't quite meet, leaving a 1px seam. Integer columns of
	-- width 1 can't drift apart from each other since there's nothing left to round.
	local StartPx = math.floor(X)
	local EndPx   = math.floor(X + LengthPx)

	surface.SetDrawColor(DrawColor)

	-- Top/Bottom are rounded outward (floor/ceil) rather than passing float y/height straight
	-- to DrawRect: it floors y and height independently, and near the tip -- where RadiusHere
	-- is a fraction of a pixel -- that let one side's rounding collapse to nothing a few
	-- columns before the other side did, making the taper look lopsided instead of symmetric.
	-- Clamped back to the silhouette's own outward-rounded bounds so that outward rounding
	-- can't push a column's rect a pixel past the parent shape's outline.
	local MaxTop    = math.floor(CenterY - MaxDiameterPx * 0.5)
	local MaxBottom = math.ceil(CenterY + MaxDiameterPx * 0.5)

	for PixelX = StartPx, EndPx - 1 do
		local T = (PixelX + 0.5 - X) / LengthPx
		local RadiusHere = Lerp(math.Clamp(T, 0, 1), R1Px, R2Px)
		local Top    = math.max(math.floor(CenterY - RadiusHere), MaxTop)
		local Bottom = math.min(math.ceil(CenterY + RadiusHere), MaxBottom)

		if Bottom > Top then
			surface.DrawRect(PixelX, Top, 1, Bottom - Top)
		end
	end

	if self.Material then
		local TallPx = math.max(R1Px, R2Px) * 2
		Panel:AddRegion(X, CenterY - TallPx * 0.5, LengthPx, TallPx, self:GetRegionLabel())
	end
end

----------------------------------------------------------------------------------------------------
-- Box: Params = { SizeX, SizeY, SizeZ }
----------------------------------------------------------------------------------------------------

local Box = DefineShape("Box")

function Box:GetLength()
	return self.Params.SizeX or 0
end

function Box:GetRadius()
	local P = self.Params
	return math.max(P.SizeY or 0, P.SizeZ or 0) * 0.5
end

function Box:GetShapeVolume()
	local P = self.Params
	return (P.SizeX or 0) * (P.SizeY or 0) * (P.SizeZ or 0)
end

Box.DrawShape = DrawRect
