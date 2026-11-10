local ACF     = ACF
local Overlay = ACF.Overlay

local GetRoundKindColor = ENT.GetRoundKindColor

local BAR_HEIGHT    = 30
local NUMBER_FONT   = "DermaDefault"
local ROW_HEIGHT    = 24 -- A row and the gap under it
local FRAME_HEIGHT  = 90 -- Title, margins and the apply button
local FRAME_WIDTH   = 360
local DIVIDER_GRAB  = 6 -- Pixels either side of a divider that pick it up
local BAR_BACKDROP  = Color( 30, 30, 30 ) -- Shows between sections, as the overlay's background does

do --MARK: Round counts menu
	local barData = {} -- Sections in the form Overlay.DrawSegmentBar takes, refilled every paint

	-- Fills a frame with a bar split between a crate's kinds of rounds by draggable dividers,
	-- drawn like the crate overlay's contents bar, and a row per kind to order or remove it.
	-- Kinds lists every kind top first as { Name, Count, Slot, Icon }, OnApply gets the slots
	-- in their new order and their counts. Also used by ponder.
	function ACF.BuildRoundCountsMenu( frame, capacity, kinds, onApply )
		local entries   = {}
		local barHeight = Overlay.GetSegmentBarHeight( Overlay.SurfacePainter, BAR_HEIGHT, NUMBER_FONT )

		capacity = math.max( capacity, 1 )
		frame:SetSize( FRAME_WIDTH, FRAME_HEIGHT + barHeight + #kinds * ROW_HEIGHT )

		-- Rounds before the divider after an entry
		local function boundary( index )
			local sum = 0

			for i = 1, index do sum = sum + entries[i].Count end

			return sum
		end

		-- Moves a divider to sit after the given number of rounds, every kind keeping a round
		local function moveDivider( index, rounds )
			local low   = boundary( index - 1 ) + 1
			local high  = boundary( index + 1 ) - 1
			local delta = math.Clamp( math.Round( rounds ), low, high ) - boundary( index )

			entries[index].Count     = entries[index].Count + delta
			entries[index + 1].Count = entries[index + 1].Count - delta
		end

		-- A section per kind, dragging a divider moves rounds between its two neighbours
		local bar = frame:Add( "DPanel" )
		bar:Dock( TOP )
		bar:DockMargin( 4, 0, 4, 8 )
		bar:SetTall( barHeight )

		-- The rightmost divider under the cursor, so dividers bunched together can still be pulled apart
		local function dividerAt( x )
			for index = #entries - 1, 1, -1 do
				local dividerX = bar:GetWide() * boundary( index ) / capacity

				if math.abs( dividerX - x ) <= DIVIDER_GRAB then return index end
			end
		end

		function bar:OnMousePressed()
			self.Dragging = dividerAt( self:CursorPos() )
			self:MouseCapture( self.Dragging ~= nil )
		end

		function bar:OnMouseReleased()
			self.Dragging = nil
			self:MouseCapture( false )
		end

		function bar:Think()
			local x     = self:CursorPos()
			local index = self.Dragging

			self:SetCursor( ( index or dividerAt( x ) ) and "sizewe" or "arrow" )

			if index then moveDivider( index, x / self:GetWide() * capacity ) end
		end

		-- Every section is full, the window splits the crate rather than showing what is left of it
		function bar.Paint( _, w )
			for index, entry in ipairs( entries ) do
				local base = ( index - 1 ) * 4

				barData[base + 1] = entry.Icon
				barData[base + 2] = entry.Count
				barData[base + 3] = entry.Count
				barData[base + 4] = GetRoundKindColor( index )
			end

			surface.SetDrawColor( BAR_BACKDROP )
			surface.DrawRect( 0, 0, w, BAR_HEIGHT )

			Overlay.DrawSegmentBar(
				Overlay.SurfacePainter,
				0, 0, w, BAR_HEIGHT,
				capacity, barData, 1, #entries,
				NUMBER_FONT, color_black
			)
		end

		local apply = frame:Add( "DButton" )
		apply:Dock( BOTTOM )
		apply:SetText( "Apply" )

		function apply.DoClick()
			local order, counts = {}, {}

			for index, entry in ipairs( entries ) do order[index], counts[index] = entry.Slot, entry.Count end

			if onApply then onApply( order, counts ) end

			frame:Close()
		end

		local rows = frame:Add( "DPanel" )
		rows:Dock( FILL )
		rows:SetPaintBackground( false )

		local buildRows

		-- Swaps an entry with its neighbour, keeping each kind's count
		local function moveEntry( index, step )
			local other = index + step

			if not entries[other] then return end

			entries[index], entries[other] = entries[other], entries[index]

			buildRows()
		end

		-- A removed kind's rounds go to the one above it, or below if it was the top
		local function removeEntry( index )
			local heir = entries[index - 1] or entries[index + 1]

			heir.Count = heir.Count + entries[index].Count

			table.remove( entries, index )
			frame:SetTall( frame:GetTall() - ROW_HEIGHT )

			buildRows()
		end

		local function addButton( row, icon, tooltip, enabled, onClick )
			local button = row:Add( "DImageButton" )
			button:Dock( LEFT )
			button:DockMargin( 0, 2, 2, 2 )
			button:SetWide( 16 )
			button:SetImage( icon )
			button:SetTooltip( tooltip )
			button:SetEnabled( enabled )
			button:SetAlpha( enabled and 255 or 60 )
			button.DoClick = onClick
		end

		-- A row per kind with its position, colour and count
		function buildRows()
			rows:Clear()

			for index, entry in ipairs( entries ) do
				local row = rows:Add( "DPanel" )
				row:Dock( TOP )
				row:DockMargin( 4, 0, 4, 4 )
				row:SetTall( ROW_HEIGHT - 4 )
				row:SetPaintBackground( false )

				local isTop, isBottom = index == 1, index == #entries

				local function moveUp() moveEntry( index, -1 ) end
				local function moveDown() moveEntry( index, 1 ) end
				local function remove() removeEntry( index ) end

				addButton( row, "icon16/arrow_up.png", "Move up", not isTop, moveUp )
				addButton( row, "icon16/arrow_down.png", "Move down", not isBottom, moveDown )
				addButton( row, "icon16/cross.png", "Remove", #entries > 1, remove )

				local swatch = row:Add( "DPanel" )
				swatch:Dock( LEFT )
				swatch:DockMargin( 4, 2, 4, 2 )
				swatch:SetWide( 16 )

				function swatch.Paint( _, w, h )
					surface.SetDrawColor( GetRoundKindColor( index ) )
					surface.DrawRect( 0, 0, w, h )
				end

				local label = row:Add( "DLabel" )
				label:Dock( FILL )
				label:SetDark( true )

				function label.Think() label:SetText( index .. ". " .. entry.Name .. ": " .. entry.Count ) end
			end
		end

		for _, kind in ipairs( kinds ) do
			entries[#entries + 1] = {
				Slot  = kind.Slot,
				Name  = kind.Name,
				Count = kind.Count,
				Icon  = kind.Icon,
			}
		end

		buildRows()

		return { Bar = bar, Apply = apply, Entries = entries, Boundary = boundary, MoveDivider = moveDivider }
	end

	-- Opens a window to order the crate's kinds of rounds and split it between them, sent by the property
	function ENT:OpenRoundCounts( property )
		local roundKinds = self.RoundKinds
		local version    = self.RoundMixVersion -- The server refuses the edit if the mix changes before Apply
		local frame      = g_ContextMenu:Add( "DFrame" )
		local kinds      = {}

		-- Rounds of one type can differ, mass and muzzle velocity tell them apart
		for index, kind in ipairs( roundKinds ) do
			local mass     = math.Round( kind.ProjMass, 2 )
			local velocity = math.Round( kind.MuzzleVel )

			kinds[index] = {
				Slot  = index,
				Name  = kind.Name .. ", " .. mass .. " kg, " .. velocity .. " m/s",
				Count = kind.Target,
				Icon  = kind.Icon,
			}
		end

		ACF.BuildRoundCountsMenu( frame, self.Capacity or 0, kinds, function( order, counts )
			if not IsValid( self ) then return end

			property:SendCounts( self, version, order, counts )
		end )

		frame:SetTitle( "Round Counts [" .. self:EntIndex() .. "]" )
		frame:Center()
		frame:MoveToFront()
	end
end
