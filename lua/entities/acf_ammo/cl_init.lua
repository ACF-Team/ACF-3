local ACF       = ACF
local MaxRounds = GetConVar( "acf_maxroundsdisplay" )
local Queued    = {}

include( "shared.lua" )

killicon.Add( "acf_ammo", "HUD/killicons/acf_ammo", ACF.KillIconColor )


local function updateAmmoCount( entity, ammo )
	if not IsValid( entity ) then return end
	if not entity.HasData then
		if entity.HasData == nil then
			entity:RequestAmmoData()
		end

		return
	end

	local maxDisplayRounds = math.max( 0, MaxRounds:GetInt() )

	entity.Ammo = ammo or entity:GetNWInt( "Ammo", 0 )
	entity.DisplayAmmo = math.min( entity.Ammo, maxDisplayRounds )
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
	entity.IsBelted         = net.ReadBool() or false

	local hasCustomModel = net.ReadBool()

	if hasCustomModel then
		entity.RoundModel  = net.ReadString()
		entity.RoundOffset = net.ReadVector()
	else
		entity.RoundModel  = nil
		entity.RoundOffset = nil
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
	entity.CachedModelScale    = modelScale
	entity.CachedLocalAngle    = localAngle
	entity.CachedHasCustom     = hasCustomModel
	entity.CachedDefaultOffset = not hasCustomModel and Vector( entity.RoundSize.x * 0.5, 0, 0 ) or nil

	-- Clear existing models since data changed
	if entity._RoundModels then
		for _, model in ipairs( entity._RoundModels ) do
			if IsValid( model ) then
				model:Remove()
			end
		end

		entity._RoundModels = nil
	end

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

function ENT:OnResized( size )
	self.HitBoxes = {
		Main = {
			Pos = self:OBBCenter(),
			Scale = size,
			Angle = Angle(),
			Sensitive = false
		}
	}

	self.HasData = nil
end

function ENT:OnFullUpdate()
	net.Start( "ACF_RequestAmmoData" )
		net.WriteEntity( self )
	net.SendToServer()
end


local function cleanupRoundModels( entity )
	if not entity._RoundModels then return end

	for _, model in ipairs( entity._RoundModels ) do
		if IsValid( model ) then
			model:Remove()
		end
	end

	entity._RoundModels = nil
end

function ENT:OnRemove()
	cleanupRoundModels( self )
	cvars.RemoveChangeCallback( "acf_maxroundsdisplay", "Ammo Crate " .. self:EntIndex() )
end

do -- Ammo overlay rendering
	local drawBoxes   = GetConVar( "acf_drawboxes" )
	local wireOutline = GetConVar( "wire_drawoutline" )

	local HEX_SPACING_FACTOR = 0.866 -- sqrt(3)/2 for hexagonal packing
	local HEX_OFFSET_FACTOR  = 0.5

	local function getLocalPosition( x, y, z, roundSize, fits )
		local useLinearPacking = ( fits.y == 1 or fits.z == 1 )
		local localX           = ( x - 1 ) * roundSize.x
		local localY, localZ

		if useLinearPacking then
			localY = ( y - 1 ) * roundSize.y
			localZ = ( z - 1 ) * roundSize.z
		else
			localY = ( y - 1 ) * roundSize.y * HEX_SPACING_FACTOR

			local zOffset = ( ( y - 1 ) % 2 ) * roundSize.z * HEX_OFFSET_FACTOR
			localZ        = ( z - 1 ) * roundSize.z + zOffset
		end

		return Vector( localX, localY, localZ )
	end

	local function createRoundModels( entity )
		-- Use pre-calculated cached data
		local modelPath      = entity.CachedModelPath
		local modelScale     = entity.CachedModelScale
		local localAngle     = entity.CachedLocalAngle
		local hasCustomModel = entity.CachedHasCustom
		local roundSize      = entity.RoundSize
		local fits           = entity.ProjectileCounts
		local total          = entity.DisplayAmmo

		-- Create scale matrix once for all models
		local scaleMatrix = Matrix()
		scaleMatrix:SetScale( modelScale )

		-- Calculate world angle once for all models
		local worldAngle = entity:LocalToWorldAngles( localAngle )

		-- Calculate offset once for all models
		local modelOffset = Vector( 0, 0, 0 )
		if hasCustomModel and entity.RoundOffset then
			modelOffset = entity.RoundOffset
		elseif entity.CachedDefaultOffset then
			modelOffset = -entity.CachedDefaultOffset
		end

		-- Calculate crate dimensions and starting position
		local crateDimensions = ACF.GetCrateDimensions( fits, roundSize )
		local localStartPos = Vector(
			-crateDimensions.x * 0.5 + roundSize.x * 0.5,
			-crateDimensions.y * 0.5 + roundSize.y * 0.5,
			-crateDimensions.z * 0.5 + roundSize.z * 0.5
		)

		-- Create all models
		local models = {}
		local count  = 0

		for x = 1, fits.x do
			for y = 1, fits.y do
				for z = 1, fits.z do
					local localGridPos  = getLocalPosition( x, y, z, roundSize, fits )
					local localModelPos = localStartPos + localGridPos + modelOffset

					-- Create and configure model
					local model = ClientsideModel( modelPath, RENDERGROUP_OPAQUE )
					if IsValid( model ) then
						model:SetParent( entity )
						model:SetPos( entity:LocalToWorld( localModelPos ) )
						model:SetAngles( worldAngle )
						model:SetNoDraw( true )
						model:DrawShadow( false )
						model:EnableMatrix( "RenderMultiply", scaleMatrix )
						models[#models + 1] = model
					end

					count = count + 1
					if count == total then break end
				end
				if count == total then break end
			end
			if count == total then break end
		end

		return models
	end

	function ENT:CanDrawOverlay()
		return drawBoxes:GetBool()
	end

	function ENT:Draw()
		local ply = LocalPlayer()
		if not IsValid( ply ) then return end

		local looking          = ply:GetEyeTrace().Entity == self
		local canShowInternals = looking and drawBoxes:GetBool() and self.HasData and self.DisplayAmmo > 0

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

		-- This crate hasn't been looked at before: Request information about it
		if not self.HasData then
			self:RequestAmmoData()
			return
		end

		-- Optional info bubble hiding
		local hideInfo = ACF and ACF.HideInfoBubble
		if not ( hideInfo and hideInfo() ) then
			self:AddWorldTip()
		end

		-- Optional wireframe outline
		if wireOutline and wireOutline:GetBool() then
			self:DrawEntityOutline()
		end

		-- Draw ammo inside contianer
		-- Create models if needed (only once)
		if not self._RoundModels then
			self._RoundModels = createRoundModels( self )
			return -- Skip first frame to avoid rendering before models are ready
		end

		-- Draw models
		for _, model in ipairs( self._RoundModels ) do
			if IsValid( model ) then
				model:DrawModel()
			end
		end

		render.CullMode( MATERIAL_CULLMODE_CW )
		self:DrawModel()
		render.CullMode( MATERIAL_CULLMODE_CCW )

		if Wire_Render then
			Wire_Render( self )
		end
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