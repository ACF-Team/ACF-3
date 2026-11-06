local ACF = ACF

include( "shared.lua" )

killicon.Add( "acf_ammo", "HUD/killicons/acf_ammo", ACF.KillIconColor )

local ChargeModelPath    = "models/acf/munitions/charge.mdl"    -- propellant bag model, alternated in for two-piece rounds
-- charge.mdl's casing bodygroup: 0 full, 1 half, 2 combustible, 3 mortar
local ChargeBodygroup    = 0
local CartridgeModelPath = "models/acf/munitions/cartridge.mdl" -- last-resort fallback; the server normally names the model

local function removeModels( models )
	for _, model in ipairs( models ) do
		if IsValid( model ) then model:Remove() end
	end
end

local function cleanupRoundModels( entity )
	if not entity._RoundModels then return end

	for _, models in pairs( entity._RoundModels ) do
		removeModels( models )
	end

	entity._RoundModels = nil
	entity._RoundBoxes  = nil
	entity._RoundKinds  = nil
end

do --MARK: Networking
	local MaxRounds = GetConVar( "acf_maxroundsdrawn" )
	local Queued    = {}

	-- Crate space placement of the pieces of every round that can be drawn. A two piece round takes a charge cell
	-- and the projectile cell after it along the shape's pairing axis, the same pairing the server counts by.
	local function buildRoundPieces( entity )
		local rounds    = {}
		local limit     = math.min( entity.Capacity, ACF.MaxRoundsDrawn )
		local pieces    = entity.IsTwoPiece and 2 or 1
		local roundSize = entity.RoundSize

		local function addPiece( round, pos, ang, modelPos, modelAng )
			local list = rounds[round] or {}

			list[#list + 1] = { Pos = pos, Ang = ang, ModelPos = modelPos, ModelAng = modelAng, Charge = pieces == 2 and #list == 0 }
			rounds[round]   = list
		end

		if entity.IsDrum then
			local layout  = ACF.GetDrumLayout( entity.DrumShape )
			local primary = entity.DrumPrimary
			local perDisk = layout.GetPerDisk( primary )

			-- Drums pair a disk with the one above it
			for round = 1, limit do
				local layer = math.floor( ( round - 1 ) / perDisk )
				local spot  = ( round - 1 ) % perDisk

				for piece = 1, pieces do
					local index    = ( layer * pieces + piece - 1 ) * perDisk + spot + 1
					local pos, ang = layout.GetRoundOffset( index, primary, entity.DrumStacks, roundSize, entity.IsHexPacked )
					local modelPos, modelAng, boxAng = layout.GetRenderTransform(
						pos, ang.yaw, entity.CachedLocalAngle, entity.LocalAng, roundSize, entity.CachedNeedsRotation
					)

					addPiece( round, pos, boxAng, modelPos, modelAng )
				end
			end

			return rounds
		end

		-- Box crates pair a layer with the one above it, cassettes pair end to end along their length
		local axis  = entity.IsCassette and "x" or "z"
		local units = Vector( entity.ProjectileCounts )
		local round = 0

		units[axis] = math.floor( units[axis] / pieces )

		for x = 1, units.x do
			for y = 1, units.y do
				for z = 1, units.z do
					if round >= limit then return rounds end

					-- The cassette's conveyor runs through these cells, so they hold no rounds
					if not ( entity.IsCassette and ACF.IsCassetteVoid( y, z, entity.CassetteCounts:Unpack() ) ) then
						round = round + 1

						for piece = 1, pieces do
							local cell = Vector( x, y, z )

							cell[axis] = ( cell[axis] - 1 ) * pieces + piece

							local pos = entity.CachedLocalStartPos + ACF.GetRoundOffset( cell.x, cell.y, cell.z, roundSize, entity.IsHexPacked )

							addPiece( round, pos, entity.LocalAng, pos + entity.CachedModelOffset, entity.CachedLocalAngle )
						end
					end
				end
			end
		end

		return rounds
	end

	local function updateAmmoCount( entity, ammo )
		if not IsValid( entity ) then return end

		if entity:GetClass() ~= "acf_ammo" then return end

		if not entity.HasData then
			if entity.HasData == nil then
				entity:RequestAmmoData()
			end

			return
		end

		local newAmmo = ammo or entity:GetNWInt( "Ammo", 0 )

		if entity.Ammo == newAmmo then return end

		entity.Ammo = newAmmo

		local maxDisplayRounds = math.max( 0, MaxRounds:GetInt() )
		entity.TargetDisplayAmmo = math.min( newAmmo, maxDisplayRounds )
	end

	net.Receive( "ACF_RequestAmmoData", function()
		local entity = net.ReadEntity()
		if not IsValid( entity ) then return end

		entity.HasData = net.ReadBool()

		if not entity.HasData then return end

		entity.Capacity         = net.ReadUInt( 25 )
		entity.IsRound          = net.ReadBool()
		entity.RoundSize        = net.ReadVector()
		entity.LocalAng         = net.ReadAngle()
		entity.ProjectileCounts = net.ReadVector()
		entity.Spacing          = net.ReadFloat()
		entity.MagSize          = net.ReadUInt( 10 )
		entity.AmmoStage        = net.ReadUInt( 5 )
		entity.IsBelted         = net.ReadBool()
		entity.RoundBodygroup   = net.ReadUInt( 4 ) -- Bodygroup index (0-15)

		entity.IsDrum = net.ReadBool()

		if entity.IsDrum then
			entity.DrumShape   = net.ReadString()
			entity.DrumPrimary = net.ReadUInt( 8 )
			entity.DrumStacks  = net.ReadUInt( 8 )
		end

		local hasCustomModel = net.ReadBool()

		if hasCustomModel then
			entity.RoundModel  = net.ReadString()
			entity.RoundOffset = net.ReadVector()
		end

		-- Read rotation flag (cartridge models need -90 degree rotation)
		local needsRotation = net.ReadBool()

		entity.IsTwoPiece  = net.ReadBool()
		entity.IsHexPacked = net.ReadBool()
		entity.IsCassette  = net.ReadBool()

		-- Cassette counts are stacks and conveyor size; render from the full grid they wrap into
		if entity.IsCassette then
			local counts = entity.ProjectileCounts

			entity.CassetteCounts   = counts
			entity.ProjectileCounts = ACF.GetCassetteGrid( counts.x, counts.y, counts.z, entity.IsTwoPiece )
		end

		-- Bodygroup and count of each kind of round, the crate's own first
		local kinds = {}

		for index = 1, net.ReadUInt( ACF.ProfileBits ) + 1 do
			kinds[index] = { Bodygroup = net.ReadUInt( 4 ), Target = net.ReadUInt( 25 ) }
		end

		entity.RoundKinds = kinds

		-- Resolve model path - use cartridge model with bodygroups for ammo visualization
		local modelPath = entity.RoundModel

		if not modelPath then
			-- Use the unified cartridge model with bodygroups
			modelPath = CartridgeModelPath
		end

		-- Calculate a scale matrix that fits a given model's bounding box into the round's cell size
		local function getScaleMatrix( path )
			local size  = ACF.ModelData.GetModelSize( path )
			local scale = Vector( 1, 1, 1 )

			if size then
				if needsRotation then
					-- Cartridge model needs axis swap due to rotation
					scale = Vector(
						entity.RoundSize.y / size.x,
						entity.RoundSize.z / size.y,
						entity.RoundSize.x / size.z
					)
				else
					scale = Vector(
						entity.RoundSize.x / size.x,
						entity.RoundSize.y / size.y,
						entity.RoundSize.z / size.z
					)
				end
			end

			local matrix = Matrix()
			matrix:SetScale( scale )
			return matrix
		end

		-- Calculate projectile angle
		local localAngle = Angle( entity.LocalAng )
		if needsRotation then
			localAngle:RotateAroundAxis( entity.LocalAng:Right(), -90 )
		end

		-- Cache data for model creation
		entity.CachedModelPath      = modelPath
		entity.CachedLocalAngle     = localAngle
		entity.CachedNeedsRotation  = needsRotation
		entity.CachedScaleMatrix    = getScaleMatrix( modelPath )

		-- Two-piece rounds alternate in a propellant bag model between projectiles; cache its scale too
		if entity.IsTwoPiece then
			entity.CachedChargeScaleMatrix = getScaleMatrix( ChargeModelPath )
		end

		-- Cache model offset for box positioning (base-origin models need centering)
		local modelOffset = Vector( 0, 0, 0 )

		if needsRotation then
			modelOffset = -Vector( entity.RoundSize.x * 0.5, 0, 0 )
		elseif entity.RoundOffset then
			modelOffset = entity.RoundOffset
		end

		entity.CachedModelOffset = modelOffset

		-- Cache crate start position for box crates
		if not entity.IsDrum then
			local crateDimensions = ACF.GetCrateDimensions( entity.ProjectileCounts, entity.RoundSize, entity.IsHexPacked )
			entity.CachedLocalStartPos = Vector(
				-crateDimensions.x * 0.5 + entity.RoundSize.x * 0.5,
				-crateDimensions.y * 0.5 + entity.RoundSize.y * 0.5,
				-crateDimensions.z * 0.5 + entity.RoundSize.z * 0.5
			)
		end

		entity.CachedRounds = buildRoundPieces( entity )

		-- Reset model state
		cleanupRoundModels( entity )

		entity.TargetDisplayAmmo = nil
		entity.Ammo              = nil -- Forces a recount, the data can change without the ammo count changing

		if Queued[entity] then
			Queued[entity] = nil
		end

		updateAmmoCount( entity )
	end )

	function ENT:Initialize()
		self:SetNWVarProxy( "Ammo", function( _, _, _, ammo )
			updateAmmoCount( self, ammo )
		end )

		cvars.AddChangeCallback( "acf_maxroundsdrawn", function()
			updateAmmoCount( self )
		end, "Ammo Crate " .. self:EntIndex() )

		self.BaseClass.Initialize( self )
	end

	function ENT:RequestAmmoData()
		if Queued[self] then return end

		Queued[self] = true

		net.Start( "ACF_RequestAmmoData" )
			net.WriteEntity( self )
		net.SendToServer()
	end

	function ENT:OnFullUpdate()
		net.Start( "ACF_RequestAmmoData" )
			net.WriteEntity( self )
		net.SendToServer()
	end
end

do --MARK: Ammo rendering
	local drawBoxes      = GetConVar( "acf_drawboxes" )
	local WireRender     = Wire_Render
	local slotColor      = Color( 0, 255, 0, 255 )
	local overrideColor  = Color( 255, 160, 0, 255 )

	-- Kind of each drawn round, every kind in one block. The other kinds come first so the crate's own never hides them
	function ENT:GetDrawnKinds( count )
		local kinds = self.RoundKinds
		local drawn = {}

		for index = 2, #kinds do
			for _ = 1, self:GetNW2Int( "RoundCount" .. ACF.GetCrateNWSuffix( index - 1 ) ) do
				if #drawn >= count then return drawn end

				drawn[#drawn + 1] = index
			end
		end

		for round = #drawn + 1, count do drawn[round] = 1 end

		return drawn
	end

	-- Rebuilds the models of every drawn round whose kind changed, the rest are kept
	function ENT:SetRounds( kinds )
		if not self.HasData then return end

		if not self._RoundModels then
			self._RoundModels = {}
			self._RoundBoxes  = {}
			self._RoundKinds  = {}
		end

		local models  = self._RoundModels
		local boxes   = self._RoundBoxes
		local current = self._RoundKinds

		local modelPath         = self.CachedModelPath
		local scaleMatrix       = self.CachedScaleMatrix
		local chargeScaleMatrix = self.CachedChargeScaleMatrix
		local roundSize         = self.RoundSize

		for round = 1, math.max( #current, #kinds ) do
			local kind = kinds[round]

			if current[round] ~= kind then
				removeModels( models[round] or {} )

				models[round], boxes[round], current[round] = nil, nil, kind
			end

			if kind and not models[round] then
				local roundModels, roundBoxes = {}, {}

				for _, piece in ipairs( self.CachedRounds[round] or {} ) do
					local path, scale, group = modelPath, scaleMatrix, self.RoundKinds[kind].Bodygroup

					if piece.Charge then
						path, scale, group = ChargeModelPath, chargeScaleMatrix, ChargeBodygroup
					end

					local model = ClientsideModel( path, RENDERGROUP_OPAQUE )
					if IsValid( model ) then
						model:SetParent( self )
						model:SetPos( self:LocalToWorld( piece.ModelPos ) )
						model:SetAngles( self:LocalToWorldAngles( piece.ModelAng ) )
						model:SetNoDraw( true )
						model:DrawShadow( false )
						model:EnableMatrix( "RenderMultiply", scale )
						model:SetBodygroup( 0, group ) -- Apply ammo type bodygroup
						roundModels[#roundModels + 1] = model
					end

					roundBoxes[#roundBoxes + 1] = { Pos = piece.Pos, Ang = piece.Ang, Size = roundSize }
				end

				models[round] = roundModels
				boxes[round]  = roundBoxes
			end
		end
	end

	function ENT:Draw()
		local RenderContext = ACF.RenderContext
		local LookedAt = RenderContext.LookAt == self

		-- Not looking at the crate or ammo drawing is disabled
		if not LookedAt or not drawBoxes:GetBool() or not self.HasData then
			cleanupRoundModels( self )

			local BaseClass = self.BaseClass

			if BaseClass and BaseClass.Draw then
				BaseClass.Draw( self )
			else
				self:DrawModel()
			end

			return
		end

		-- Optional wireframe outline
		if RenderContext.ShouldDrawOutline then
			self:DrawEntityOutline()
		end

		-- Sync models with the rounds left (only when looking at crate)
		self:SetRounds( self:GetDrawnKinds( self.TargetDisplayAmmo or 0 ) )

		-- Draw models
		if self._RoundModels then
			for _, models in pairs( self._RoundModels ) do
				for _, model in ipairs( models ) do
					if IsValid( model ) then model:DrawModel() end
				end
			end
		end

		-- Draw a wireframe box around each piece showing the true space it occupies, colored by its round
		if self._RoundBoxes then
			for round, boxes in pairs( self._RoundBoxes ) do
				local color = self._RoundKinds[round] > 1 and overrideColor or slotColor

				for _, box in ipairs( boxes ) do
					local Half = box.Size * 0.5

					render.DrawWireframeBox( self:LocalToWorld( box.Pos ), self:LocalToWorldAngles( box.Ang ), -Half, Half, color, true )
				end
			end
		end

		render.CullMode( MATERIAL_CULLMODE_CW )
		self:DrawModel()
		render.CullMode( MATERIAL_CULLMODE_CCW )

		if WireRender then
			WireRender( self )
		end
	end

	-- Ammo data doesn't depend on the crate's size, only the models placed for the old size are stale
	function ENT:OnResized( _ )
		cleanupRoundModels(self)
	end

	function ENT:OnRemove()
		cleanupRoundModels( self )
		cvars.RemoveChangeCallback( "acf_maxroundsdrawn", "Ammo Crate " .. self:EntIndex() )
	end

	function ENT:CanDrawOverlay()
		return drawBoxes:GetBool()
	end
end

do --MARK: Stages overlay
	function ENT:DrawStage()
		local cratePos = self:GetPos():ToScreen()
		local orange   = Color( 255, 127, 0 )

		cam.Start2D()
			draw.SimpleTextOutlined(
				"S: " .. ( self.AmmoStage or -1 ),
				"ACF_Title",
				cratePos.x,
				cratePos.y,
				orange,
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER,
				1,
				color_black
			)

			draw.SimpleTextOutlined(
				"A: " .. ( self.Ammo or -1 ),
				"ACF_Title",
				cratePos.x,
				cratePos.y + 15,
				orange,
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER,
				1,
				color_black
			)
		cam.End2D()
	end

	function ENT:DrawOverlay()
		self:DrawStage()
	end
end
do --MARK: Round counts menu
	local ownColor = Color( 130, 130, 130 )

	-- Fills a frame with a bar split between a crate's kinds of rounds by draggable dividers, and a row per other kind
	-- Kinds lists the other kinds as { Name, Count, Slot }, OnApply gets the counts by slot. Also used by ponder.
	function ACF.BuildRoundCountsMenu( frame, capacity, kinds, onApply )
		local entries = {}

		capacity = math.max( capacity, 1 )
		frame:SetSize( 320, 120 + #kinds * 24 )

		-- Rounds before the divider after an entry
		local function boundary( index )
			local sum = 0

			for i = 1, index do sum = sum + entries[i].Count end

			return sum
		end

		local function ownCount() return capacity - boundary( #entries ) end

		-- Moves a divider to sit after the given number of rounds, every kind keeping a round
		local function moveDivider( index, rounds )
			local after = entries[index + 1]
			local low   = boundary( index - 1 ) + 1
			local high  = after and boundary( index + 1 ) - 1 or capacity
			local delta = math.Clamp( math.Round( rounds ), low, high ) - boundary( index )

			entries[index].Count = entries[index].Count + delta

			if after then after.Count = after.Count - delta end
		end

		-- A segment per kind, dragging a divider moves rounds between its two neighbours
		local bar = frame:Add( "DPanel" )
		bar:Dock( TOP )
		bar:DockMargin( 4, 0, 4, 8 )
		bar:SetTall( 24 )

		-- The rightmost divider under the cursor, so dividers bunched together can still be pulled apart
		local function dividerAt( x )
			for index = #entries, 1, -1 do
				if math.abs( bar:GetWide() * boundary( index ) / capacity - x ) <= 6 then return index end
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

		function bar.Paint( _, w, h )
			local x = 0

			for index = 1, #entries + 1 do
				local entry = entries[index]
				local right = entry and math.Round( w * boundary( index ) / capacity ) or w
				local count = entry and entry.Count or ownCount()

				-- The gap after each segment is its divider
				surface.SetDrawColor( entry and entry.Color or ownColor )
				surface.DrawRect( x, 0, right - x - ( entry and 2 or 0 ), h )

				if right - x >= 20 then
					draw.SimpleText( count, "DermaDefault", ( x + right ) * 0.5, h * 0.5, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end

				x = right
			end
		end

		-- A row per kind with its colour and count, its X removes it and gives its rounds to the crate's own
		for index, kind in ipairs( kinds ) do
			local entry = {
				Slot  = kind.Slot,
				Name  = kind.Name,
				Color = HSVToColor( index * 90, 0.6, 0.9 ),
				Count = kind.Count,
			}

			entries[#entries + 1] = entry

			local row = frame:Add( "DPanel" )
			row:Dock( TOP )
			row:DockMargin( 4, 0, 4, 4 )
			row:SetTall( 20 )
			row:SetPaintBackground( false )

			local remove = row:Add( "DButton" )
			remove:Dock( LEFT )
			remove:SetWide( 20 )
			remove:SetText( "X" )

			function remove.DoClick()
				table.RemoveByValue( entries, entry )
				row:Remove()
				frame:SetTall( frame:GetTall() - 24 )
			end

			local swatch = row:Add( "DPanel" )
			swatch:Dock( LEFT )
			swatch:DockMargin( 4, 2, 4, 2 )
			swatch:SetWide( 16 )

			function swatch.Paint( _, w, h )
				surface.SetDrawColor( entry.Color )
				surface.DrawRect( 0, 0, w, h )
			end

			local label = row:Add( "DLabel" )
			label:Dock( FILL )
			label:SetDark( true )

			function label.Think() label:SetText( entry.Name .. ": " .. entry.Count ) end
		end

		local own = frame:Add( "DLabel" )
		own:Dock( TOP )
		own:DockMargin( 28, 0, 4, 4 )
		own:SetDark( true )

		function own.Think() own:SetText( "Crate's own round: " .. ownCount() ) end

		local apply = frame:Add( "DButton" )
		apply:Dock( BOTTOM )
		apply:SetText( "Apply" )

		function apply.DoClick()
			local counts = {}

			for _, entry in ipairs( entries ) do counts[entry.Slot] = entry.Count end

			if onApply then onApply( counts ) end

			frame:Close()
		end

		return { Bar = bar, Apply = apply, Entries = entries, Boundary = boundary, MoveDivider = moveDivider }
	end

	-- Opens a window to split the crate between its kinds of rounds, sent through the given property
	function ENT:OpenRoundCounts( property )
		local roundKinds = self.RoundKinds
		local frame      = g_ContextMenu:Add( "DFrame" )
		local kinds      = {}

		for index = 2, #roundKinds do
			local suffix = ACF.GetCrateNWSuffix( index - 1 )

			kinds[#kinds + 1] = {
				Slot  = index - 1,
				Name  = ACF.GetLegacyStyleClassName( self:GetNW2String( "AmmoType" .. suffix, "" ) ) .. ", " .. math.Round( self:GetNW2Float( "ProjMass" .. suffix ), 2 ) .. " kg",
				Count = roundKinds[index].Target,
			}
		end

		ACF.BuildRoundCountsMenu( frame, self.Capacity or 0, kinds, function( counts )
			if not IsValid( self ) then return end

			property:MsgStart()
				net.WriteEntity( self )
				net.WriteUInt( #roundKinds - 1, ACF.ProfileBits )

				for slot = 1, #roundKinds - 1 do net.WriteUInt( counts[slot] or 0, 25 ) end
			property:MsgEnd()
		end )

		frame:SetTitle( "Round Counts [" .. self:EntIndex() .. "]" )
		frame:Center()
		frame:MoveToFront()
	end
end
