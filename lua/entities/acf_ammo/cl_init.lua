local ACF       = ACF
local MaxRounds = GetConVar( "acf_maxroundsdisplay" )
local Queued    = {}

include( "shared.lua" )

killicon.Add( "acf_ammo", "HUD/killicons/acf_ammo", ACF.KillIconColor )


local function updateAmmoCount( entity, ammo )
	if not IsValid( entity ) then return end
	-- Networking fail - is there a better way to handle this...
	if entity:GetClass() ~= "acf_ammo" then return end
	if not entity.HasData then
		if entity.HasData == nil then
			entity:RequestAmmoData()
		end

		return
	end

	-- Avoid redundant GetNWInt call when ammo is already provided
	local newAmmo = ammo or entity:GetNWInt( "Ammo", 0 )

	-- Early-out if ammo hasn't changed
	if entity.Ammo == newAmmo then return end

	entity.Ammo = newAmmo

	local maxDisplayRounds = math.max( 0, MaxRounds:GetInt() )
	entity.TargetDisplayAmmo = math.min( newAmmo, maxDisplayRounds )

	-- Don't call SetAmount here - models are only created/updated in Draw()
	-- when the player is actually looking at this crate
end

net.Receive( "ACF_RequestAmmoData", function()
	local entity = net.ReadEntity()
	if not IsValid( entity ) then return end

	entity.HasData = net.ReadBool()

	if not entity.HasData then return end

	-- Read network data
	entity.Capacity         = net.ReadUInt( 25 )
	entity.IsRound          = net.ReadBool()
	entity.RoundSize        = net.ReadVector()
	entity.LocalAng         = net.ReadAngle()
	entity.ProjectileCounts = net.ReadVector()
	entity.Spacing          = net.ReadFloat()
	entity.MagSize          = net.ReadUInt( 10 )
	entity.AmmoStage        = net.ReadUInt( 5 )
	entity.IsBelted         = net.ReadBool()

	local hasCustomModel = net.ReadBool()

	if hasCustomModel then
		entity.RoundModel  = net.ReadString()
		entity.RoundOffset = net.ReadVector()
	end

	-- Determine model path
	local modelPath = entity.RoundModel

	if not modelPath then
		modelPath = "models/munitions/round_100mm.mdl"

		if entity.BulletData and entity.BulletData.Type then
			local ammoType = ACF.Classes.AmmoTypes.Get( entity.BulletData.Type )
			if ammoType and ammoType.Model then
				modelPath = ammoType.Model
			end
		end
	end

	-- Calculate model scale
	local modelSize  = ACF.ModelData.GetModelSize( modelPath )
	local modelScale = Vector( 1, 1, 1 )

	if modelSize then
		if hasCustomModel then
			modelScale = Vector(
				entity.RoundSize.x / modelSize.x,
				entity.RoundSize.y / modelSize.y,
				entity.RoundSize.z / modelSize.z
			)
		else
			modelScale = Vector(
				entity.RoundSize.y / modelSize.x,
				entity.RoundSize.z / modelSize.y,
				entity.RoundSize.x / modelSize.z
			)
		end
	end

	-- Calculate projectile angle
	local localAngle = Angle( entity.LocalAng )
	if not hasCustomModel then
		localAngle:RotateAroundAxis( entity.LocalAng:Right(), -90 )
	end

	-- Cache calculated data for model creation
	entity.CachedModelPath     = modelPath
	entity.CachedLocalAngle    = localAngle
	entity.CachedDefaultOffset = not hasCustomModel and Vector( entity.RoundSize.x * 0.5, 0, 0 ) or nil

	-- Cache model scale matrix
	local scaleMatrix = Matrix()
	scaleMatrix:SetScale( modelScale )
	entity.CachedScaleMatrix = scaleMatrix

	-- Cache model offset
	local modelOffset = Vector( 0, 0, 0 )
	if hasCustomModel and entity.RoundOffset then
		modelOffset = entity.RoundOffset
	elseif entity.CachedDefaultOffset then
		modelOffset = -entity.CachedDefaultOffset
	end

	entity.CachedModelOffset = modelOffset

	-- Cache crate start position
	local crateDimensions = ACF.GetCrateDimensions( entity.ProjectileCounts, entity.RoundSize )
	entity.CachedLocalStartPos = Vector(
		-crateDimensions.x * 0.5 + entity.RoundSize.x * 0.5,
		-crateDimensions.y * 0.5 + entity.RoundSize.y * 0.5,
		-crateDimensions.z * 0.5 + entity.RoundSize.z * 0.5
	)

	-- Clear existing models since data changed
	if entity._RoundModels then
		for _, model in pairs( entity._RoundModels ) do
			if IsValid( model ) then
				model:Remove()
			end
		end
	end

	entity._RoundModels      = nil
	entity.DisplayAmmo       = nil
	entity.TargetDisplayAmmo = nil

	if Queued[entity] then
		Queued[entity] = nil
	end

	updateAmmoCount( entity )
end )

function ENT:Initialize()
	self:SetNWVarProxy( "Ammo", function( _, _, _, ammo )
		updateAmmoCount( self, ammo )
	end )

	cvars.AddChangeCallback( "acf_maxroundsdisplay", function()
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

do -- Ammo overlay rendering
	local drawBoxes      = GetConVar( "acf_drawboxes" )
	local wireOutline    = GetConVar( "wire_drawoutline" )
	local getRoundOffset = ACF.GetRoundOffset

	local function cleanupRoundModels( entity )
		if not entity._RoundModels then return end

		for _, model in pairs( entity._RoundModels ) do
			if IsValid( model ) then
				model:Remove()
			end
		end

		entity._RoundModels = nil
	end

	function ENT:SetAmount( count )
		if not self.HasData then return end

		-- Models don't exist yet - create table from scratch
		local previous
		if not self._RoundModels then
			self._RoundModels = {}
			previous = 0
		else
			previous = self.DisplayAmmo or 0
		end
		self.DisplayAmmo = count

		-- No change
		if count == previous then return end

		-- Decrease: remove excess models (includes going to 0)
		if count < previous then
			local models = self._RoundModels
			for i = previous, count + 1, -1 do
				local m = models[i]
				models[i] = nil
				if IsValid( m ) then m:Remove() end
			end

			return
		end

		-- Increase: add new models from previous+1 to count
		local modelPath     = self.CachedModelPath
		local localAngle    = self.CachedLocalAngle
		local roundSize     = self.RoundSize
		local fits          = self.ProjectileCounts
		local scaleMatrix   = self.CachedScaleMatrix
		local modelOffset   = self.CachedModelOffset
		local localStartPos = self.CachedLocalStartPos

		-- WorldAngle must be recalculated as entity orientation can change
		local worldAngle = self:LocalToWorldAngles( localAngle )

		local models = self._RoundModels
		local index = 1

		for x = 1, fits.x do
			for y = 1, fits.y do
				for z = 1, fits.z do
					-- Only create models we don't have yet
					if index > previous and index <= count then
						local localGridPos  = getRoundOffset( x, y, z, roundSize, fits )
						local localModelPos = localStartPos + localGridPos + modelOffset

						local model = ClientsideModel( modelPath, RENDERGROUP_OPAQUE )
						if IsValid( model ) then
							model:SetParent( self )
							model:SetPos( self:LocalToWorld( localModelPos ) )
							model:SetAngles( worldAngle )
							model:SetNoDraw( true )
							model:DrawShadow( false )
							model:EnableMatrix( "RenderMultiply", scaleMatrix )
							models[index] = model
						end
					end

					index = index + 1
					if index > count then return end
				end
			end
		end
	end

	function ENT:Draw()
		local ply = LocalPlayer()
		if not IsValid( ply ) then return end

		local looking          = ply:GetEyeTrace().Entity == self
		local canShowInternals = looking and drawBoxes:GetBool() and self.HasData

		-- Not looking at the crate or ammo drawing is disabled
		if not canShowInternals then
			cleanupRoundModels( self )

			if self.BaseClass and self.BaseClass.Draw then
				self.BaseClass.Draw( self )
			else
				self:DrawModel()
			end

			return
		end

		-- Optional wireframe outline
		if wireOutline and wireOutline:GetBool() then
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

		render.CullMode( MATERIAL_CULLMODE_CW )
		self:DrawModel()
		render.CullMode( MATERIAL_CULLMODE_CCW )

		if Wire_Render then
			Wire_Render( self )
		end
	end

	function ENT:OnResized( _ )
		self.HasData = nil
		self.DisplayAmmo = nil
		self.TargetDisplayAmmo = nil

		cleanupRoundModels(self)
	end

	function ENT:OnRemove()
		cleanupRoundModels( self )
		cvars.RemoveChangeCallback( "acf_maxroundsdisplay", "Ammo Crate " .. self:EntIndex() )
	end

	function ENT:CanDrawOverlay()
		return drawBoxes:GetBool()
	end
end

do -- Ammo stage drawing
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