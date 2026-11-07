-- Pages of overlay elements: a PageHeader splits the slots after it into pages,
-- PageBreak starts the next one and PageEnd closes them. The shown page is kept per target and
-- page header title on the client, so every viewer pages on their own with the header's arrows.
local Overlay = ACF.Overlay or {}
ACF.Overlay = Overlay

local HiddenSlots   = {}
local PageArrows    = {} -- Click areas of this frame's arrows, in screen space once their overlay is placed
local NumPageArrows = 0
local FirstArrow    = 1 -- First arrow of the overlay being drawn

do -- MARK: Paging
	function Overlay.GetShownPage(Target, Title, Pages)
		local Shown = IsValid(Target) and Target.ACF_OverlayPages and Target.ACF_OverlayPages[Title] or 1

		return math.min(Shown, Pages)
	end

	--- Marks the slots of every page but the shown ones as hidden, returns the reused set of them
	function Overlay.BeginPages(State, Target)
		local Page, Shown

		FirstArrow = NumPageArrows + 1

		for Idx, ElementSlot in State:IterateElementSlots() do
			local Marker = Overlay.GetElementType(ElementSlot.Type).PageMarker

			if Marker == "Header" then
				Page, Shown = 1, Overlay.GetShownPage(Target, ElementSlot.Data[1], ElementSlot.Data[2] or 1)
			elseif Marker == "Break" and Page then
				Page = Page + 1
			elseif Marker == "End" then
				Page = nil
			end

			-- The header shows on every page, the other markers draw nothing but would add padding
			HiddenSlots[Idx] = Marker ~= "Header" and (Marker ~= nil or (Page ~= nil and Page ~= Shown))
		end

		return HiddenSlots
	end
end

do -- MARK: Arrows
	--- Adds the click area of a page arrow button at X, Y on the slot being rendered, moving Delta pages
	function Overlay.AddPageArrow(Target, Title, Pages, Delta, X, Y, W, H)
		if not IsValid(Target) then return end -- Previews draw overlays of no entity

		NumPageArrows = NumPageArrows + 1

		local Arrow = PageArrows[NumPageArrows] or {}
		PageArrows[NumPageArrows] = Arrow

		Arrow.Target, Arrow.Title, Arrow.Pages, Arrow.Delta = Target, Title, Pages, Delta
		Arrow.X, Arrow.Y, Arrow.W, Arrow.H = X, Y + Overlay.GetSlotY(), W, H
	end

	--- Moves the arrows of the overlay just laid out to where it is drawn on screen
	function Overlay.PlacePageArrows(XScale, YScale)
		local Offset = Overlay.GetOverlayOffset()

		for I = FirstArrow, NumPageArrows do
			local Arrow = PageArrows[I]

			Arrow.X, Arrow.Y = Offset.x + Arrow.X * XScale, Offset.y + Arrow.Y * YScale
			Arrow.W, Arrow.H = Arrow.W * XScale, Arrow.H * YScale
		end
	end

	--- Called once per frame before the overlays render
	function Overlay.ResetPageArrows()
		NumPageArrows = 0
	end

	local function PageArrowAt(X, Y)
		for I = 1, NumPageArrows do
			local Arrow  = PageArrows[I]
			local Inside = X >= Arrow.X and X <= Arrow.X + Arrow.W and Y >= Arrow.Y and Y <= Arrow.Y + Arrow.H

			if Inside and IsValid(Arrow.Target) then return Arrow end
		end
	end

	-- The context menu frees the cursor, and the overlay stays up while it moves off the entity
	hook.Add("GUIMousePressed", "ACF_OverlayPageArrows", function(Code)
		if Code ~= MOUSE_LEFT then return end

		local Arrow = PageArrowAt(gui.MousePos())

		if not Arrow then return end

		local Target = Arrow.Target
		local Shown  = Overlay.GetShownPage(Target, Arrow.Title, Arrow.Pages)

		Target.ACF_OverlayPages = Target.ACF_OverlayPages or {}
		Target.ACF_OverlayPages[Arrow.Title] = (Shown - 1 + Arrow.Delta) % Arrow.Pages + 1

		surface.PlaySound("garrysmod/ui_click.wav")
	end)

	-- Keeps the click from also reaching the held weapon through the context menu's world clicker
	hook.Add("PreventScreenClicks", "ACF_OverlayPageArrows", function()
		if PageArrowAt(gui.MousePos()) then return true end
	end)
end
