local ACF = ACF

include( "shared.lua" )

killicon.Add( "acf_ammo", "HUD/killicons/acf_ammo", ACF.KillIconColor )

local ChargeModelPath    = "models/acf/munitions/charge.mdl"    -- propellant bag model, alternated in for two-piece rounds
-- charge.mdl's casing bodygroup: 0 full, 1 half, 2 combustible, 3 mortar
local ChargeBodygroup    = 0
local CartridgeModelPath = "models/acf/munitions/cartridge.mdl" -- last-resort fallback; the server normally names the model

do --MARK: Networking
	local MaxRounds = GetConVar( "acf_maxroundsdrawn" )
	local Queued    = {}

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
			entity.CassetteCounts   = entity.ProjectileCounts
			entity.ProjectileCounts = ACF.GetCassetteGrid( entity.ProjectileCounts:Unpack() )
		end

		-- Bodygroups of the rounds overriding the crate's own, by slot
		local slotBodygroups = {}

		for _ = 1, net.ReadUInt( 6 ) do
			slotBodygroups[net.ReadUInt( 6 )] = net.ReadUInt( 4 )
		end

		entity.SlotBodygroups = slotBodygroups

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

		-- Reset model state
		if entity._RoundModels then
			for _, model in pairs( entity._RoundModels ) do
				if IsValid( model ) then
					model:Remove()
				end
			end
		end

		entity._RoundModels      = nil
		entity._RoundBoxes       = nil
		entity.DisplayAmmo       = nil
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
	local getRoundOffset = ACF.GetRoundOffset
	local WireRender     = Wire_Render
	local slotColor      = Color( 0, 255, 0, 255 )
	local overrideColor  = Color( 255, 160, 0, 255 )
	local hoveredColor   = Color( 255, 255, 255, 255 )

	local function cleanupRoundModels( entity )
		if not entity._RoundModels then return end

		for _, model in pairs( entity._RoundModels ) do
			if IsValid( model ) then
				model:Remove()
			end
		end

		entity._RoundModels = nil
		entity._RoundBoxes  = nil
	end

	function ENT:SetAmount( count )
		if not self.HasData then return end

		-- Models don't exist yet - create table from scratch
		local previous
		if not self._RoundModels then
			self._RoundModels = {}
			self._RoundBoxes  = {}
			previous = 0
		else
			previous = self.DisplayAmmo or 0
		end
		self.DisplayAmmo = count

		-- No change
		if count == previous then return end

		-- Two-piece rounds store as two physical pieces (projectile + charge) per round of ammo, so
		-- twice as many model slots need to be filled to match the crate's physical grid/ring layout.
		local slotMul       = self.IsTwoPiece and 2 or 1
		local previousSlots = previous * slotMul
		local countSlots    = count * slotMul

		-- Decrease: remove excess models (includes going to 0)
		if count < previous then
			local models = self._RoundModels
			local boxes  = self._RoundBoxes
			for i = previousSlots, countSlots + 1, -1 do
				local m = models[i]
				models[i] = nil
				boxes[i]  = nil
				if IsValid( m ) then m:Remove() end
			end

			return
		end

		-- Increase: add new models from previousSlots+1 to countSlots
		local modelPath        = self.CachedModelPath
		local localAngle       = self.CachedLocalAngle
		-- roundSize is in crate space (x = length), so boxes skip localAngle's model-correction pitch
		local boxAngle         = self.LocalAng
		local roundSize        = self.RoundSize
		local scaleMatrix      = self.CachedScaleMatrix
		local chargeScaleMatrix = self.CachedChargeScaleMatrix
		local modelOffset      = self.CachedModelOffset
		local bodygroup        = self.RoundBodygroup or 0
		local isTwoPiece       = self.IsTwoPiece

		local models = self._RoundModels
		local boxes  = self._RoundBoxes

		-- Two-piece rounds pair along the stacking axis: charge on the bottom tier, projectile above it.
		-- Keyed off the tier rather than the flat slot index, which advances around a drum's ring first.
		local function GetSlotModel( tier, slot )
			if isTwoPiece and tier % 2 == 0 then
				return ChargeModelPath, chargeScaleMatrix, ChargeBodygroup
			end

			return modelPath, scaleMatrix, self.SlotBodygroups[slot] or bodygroup
		end

		-- Two-piece rounds take two model slots each, overrides are by round
		local function GetRoundSlot( index )
			return isTwoPiece and math.ceil( index * 0.5 ) or index
		end

		if self.IsDrum then
			-- MARK: Drum
			-- The shape's layout owns the arrangement; this loop only places what it hands back

			local layout    = ACF.GetDrumLayout( self.DrumShape )
			local primary   = self.DrumPrimary
			local numStacks = self.DrumStacks

			for index = previousSlots + 1, countSlots do
				local localPos, localAng = layout.GetRoundOffset( index, primary, numStacks, roundSize, self.IsHexPacked )

				-- The layout also owns orientation: how the round sits, and any origin correction it needs
				local finalPos, drumAngle, drumBoxAngle = layout.GetRenderTransform(
					localPos, localAng.yaw, localAngle, boxAngle, roundSize, self.CachedNeedsRotation
				)

				local slot = GetRoundSlot( index )
				local slotPath, slotScale, slotBodygroup = GetSlotModel( layout.GetTier( index, primary ), slot )

				local model = ClientsideModel( slotPath, RENDERGROUP_OPAQUE )
				if IsValid( model ) then
					model:SetParent( self )
					model:SetPos( self:LocalToWorld( finalPos ) )
					model:SetAngles( self:LocalToWorldAngles( drumAngle ) )
					model:SetNoDraw( true )
					model:DrawShadow( false )
					model:EnableMatrix( "RenderMultiply", slotScale )
					model:SetBodygroup( 0, slotBodygroup ) -- Apply ammo type bodygroup
					models[index] = model
					boxes[index]  = { Pos = localPos, Ang = drumBoxAngle, Size = roundSize, Slot = slot }
				end
			end
		else
			-- MARK: Box
			local fits          = self.ProjectileCounts
			local localStartPos = self.CachedLocalStartPos
			local isCassette    = self.IsCassette
			local cassette      = self.CassetteCounts

			-- WorldAngle must be recalculated as entity orientation can change
			local worldAngle = self:LocalToWorldAngles( localAngle )

			local index = 1

			for x = 1, fits.x do
				for y = 1, fits.y do
					for z = 1, fits.z do
						-- The cassette's conveyor runs through these cells, so they hold no rounds
						local isVoid = isCassette and ACF.IsCassetteVoid( y, z, cassette:Unpack() )

						-- Only create models we don't have yet
						if not isVoid and index > previousSlots and index <= countSlots then
							local localGridPos  = getRoundOffset( x, y, z, roundSize, self.IsHexPacked )
							local localModelPos = localStartPos + localGridPos + modelOffset

							local slot = GetRoundSlot( index )
							local slotPath, slotScale, slotBodygroup = GetSlotModel( z - 1, slot )

							local model = ClientsideModel( slotPath, RENDERGROUP_OPAQUE )
							if IsValid( model ) then
								model:SetParent( self )
								model:SetPos( self:LocalToWorld( localModelPos ) )
								model:SetAngles( worldAngle )
								model:SetNoDraw( true )
								model:DrawShadow( false )
								model:EnableMatrix( "RenderMultiply", slotScale )
								model:SetBodygroup( 0, slotBodygroup ) -- Apply ammo type bodygroup
								models[index] = model
								boxes[index]  = { Pos = localStartPos + localGridPos, Ang = boxAngle, Size = roundSize, Slot = slot }
							end
						end

						if not isVoid then index = index + 1 end
						if index > countSlots then return end
					end
				end
			end
		end
	end

	-- Finds the slot of the round the local player is aiming at, nearest box first
	function ENT:UpdateHoveredSlot()
		local player  = LocalPlayer()
		local start   = player:EyePos()
		local delta   = player:GetAimVector() * 32768
		local nearest = math.huge
		local hovered

		for _, box in pairs( self._RoundBoxes ) do
			local half = box.Size * 0.5
			local _, _, fraction = util.IntersectRayWithOBB( start, delta, self:LocalToWorld( box.Pos ), self:LocalToWorldAngles( box.Ang ), -half, half )

			if fraction and fraction < nearest then
				nearest, hovered = fraction, box.Slot
			end
		end

		self.HoveredSlot = hovered

		return hovered
	end

	function ENT:GetHoveredSlot()
		if ACF.RenderContext.LookAt ~= self then return end

		return self.HoveredSlot
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

		-- Sync models with target ammo count (only when looking at crate)
		local targetAmmo = self.TargetDisplayAmmo or 0
		if self.DisplayAmmo ~= targetAmmo or not self._RoundModels then
			self:SetAmount( targetAmmo )
		end

		-- Draw models
		if self._RoundModels then
			for _, model in pairs( self._RoundModels ) do
				if IsValid( model ) then
					model:DrawModel()
				end
			end
		end

		-- Draw a wireframe box around each slot showing the true space it occupies
		if self._RoundBoxes then
			local hovered   = self:UpdateHoveredSlot()
			local overrides = self.SlotBodygroups

			for _, box in pairs( self._RoundBoxes ) do
				local Half  = box.Size * 0.5
				local color = box.Slot == hovered and hoveredColor or overrides[box.Slot] and overrideColor or slotColor

				render.DrawWireframeBox( self:LocalToWorld( box.Pos ), self:LocalToWorldAngles( box.Ang ), -Half, Half, color, true )
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
		self.DisplayAmmo = nil

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