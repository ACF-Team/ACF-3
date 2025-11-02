local ACF       = ACF
local MaxRounds = GetConVar("acf_maxroundsdisplay")
local Refills   = ACF.Utilities.Effects.Refills
local Queued    = {}

include("shared.lua")

killicon.Add("acf_ammo", "HUD/killicons/acf_ammo", ACF.KillIconColor)

local function UpdateAmmoCount(Entity, Ammo)
	if not IsValid(Entity) then return end
	if not Entity.HasData then
		if Entity.HasData == nil then
			Entity:RequestAmmoData()
		end

		return
	end

	local MaxDisplayRounds = math.max(0, MaxRounds:GetInt())

	Entity.Ammo = Ammo or Entity:GetNWInt("Ammo", 0)
	Entity.FinalAmmo = math.min(Entity.Ammo, MaxDisplayRounds)
	Entity.BulkDisplay = false
end

net.Receive("ACF_RequestAmmoData", function()
	local Entity = net.ReadEntity()
	if not IsValid(Entity) then return end

	Entity.HasData = net.ReadBool()

	if Entity.HasData then
		Entity.Capacity = net.ReadUInt(25)
		Entity.IsRound = net.ReadBool()
		Entity.RoundSize = net.ReadVector()
		Entity.LocalAng = net.ReadAngle()
		Entity.ProjectileCounts = net.ReadVector()
		Entity.Spacing = net.ReadFloat()
		Entity.MagSize = net.ReadUInt(10)

		Entity.AmmoStage = net.ReadUInt(5)
		Entity.IsBelted = net.ReadBool() or false

		local HasModel = net.ReadBool()

		if HasModel then
			Entity.RoundModel  = net.ReadString()
			Entity.RoundOffset = net.ReadVector()
		else
			Entity.RoundModel  = nil
			Entity.RoundOffset = nil
		end
	end

	if Queued[Entity] then
		Queued[Entity] = nil
	end

	UpdateAmmoCount(Entity)
end)

function ENT:Initialize()
	self:SetNWVarProxy("Ammo", function(_, _, _, Ammo)
		UpdateAmmoCount(self, Ammo)
	end)

	cvars.AddChangeCallback("acf_maxroundsdisplay", function()
		UpdateAmmoCount(self)
	end, "Ammo Crate " .. self:EntIndex())

	self.BaseClass.Initialize(self)
end

function ENT:RequestAmmoData()
	if Queued[self] then return end

	Queued[self] = true

	net.Start("ACF_RequestAmmoData")
		net.WriteEntity(self)
	net.SendToServer()
end

function ENT:OnResized(Size)
	self.HitBoxes = {
		Main = {
			Pos = self:OBBCenter(),
			Scale = Size,
			Angle = Angle(),
			Sensitive = false
		}
	}

	self.HasData = nil
end

function ENT:OnFullUpdate()
	net.Start("ACF_RequestAmmoData")
		net.WriteEntity(self)
	net.SendToServer()
end

function ENT:OnRemove()
	Refills[self] = nil

	-- Cleanup pooled clientside models for this crate
	if self._RoundModels then
		for _, M in ipairs(self._RoundModels) do
			if IsValid(M) then M:Remove() end
		end
		self._RoundModels = nil
	end

	cvars.RemoveChangeCallback("acf_maxroundsdisplay", "Ammo Crate " .. self:EntIndex())
end
		-- Debug: draw computed internal bounds (enable via cl cvar acf_debug_ammo_bounds 1)
		CreateClientConVar("acf_debug_ammo_bounds", "0", false, false, "Draw wireframe of computed internal bounds for ACF ammo crates")



do -- Ammo overlay
	local DrawBoxes = GetConVar("acf_drawboxes")

	-- Ammo overlay colors
	local Blue   = Color(0, 127, 255, 65)
	local Orange = Color(255, 127, 0, 65)
	local Green  = Color(0, 255, 0, 65)
	local Red    = Color(255, 0, 0, 65)
	local Yellow = Color(255, 255, 0, 65)

	-- Hexagonal packing constant
	local HEX_SPACING = 0.866 -- sqrt(3)/2 for hexagonal packing

	local function GetPosition(X, Y, Z, RoundSize, Spacing, RoundAngle, Direction, IsBelted, Fits)
		-- Use actual round size (no padding) for visual spacing
		local useLinearPacking = (Fits.y == 1 or Fits.z == 1)

		-- X dimension: Always linear
		local SizeX = (X - 1) * RoundSize.x * RoundAngle:Forward() * Direction

		-- Y and Z dimensions: Linear or hexagonal based on arrangement
		local SizeY, SizeZ
		if useLinearPacking then
			-- Linear packing - simple spacing
			SizeY = (Y - 1) * RoundSize.y * RoundAngle:Right() * Direction
			SizeZ = (Z - 1) * RoundSize.z * RoundAngle:Up() * Direction
		else
			-- Hexagonal packing - offset alternating rows
			SizeY = (Y - 1) * RoundSize.y * HEX_SPACING * RoundAngle:Right() * Direction

			-- Z dimension with hexagonal offset for alternating Y rows
			local ZOffset = ((Y - 1) % 2) * RoundSize.z * 0.5 -- Offset every other row
			SizeZ = ((Z - 1) * RoundSize.z + ZOffset) * RoundAngle:Up() * Direction
		end

		return SizeX + SizeY + SizeZ
	end

	-- Cache for clientside models to avoid creating/destroying them every frame
	local ModelCache = {}

	-- Cleanup function for cached models
	local function CleanupModelCache()
		for ModelPath, Model in pairs(ModelCache) do
			if IsValid(Model) then
				Model:Remove()
			end
		end
		ModelCache = {}
		ModelBoundsCache = {}
	end

	-- Clean up models when the game shuts down
	hook.Add("ShutDown", "ACF_AmmoDisplay_Cleanup", CleanupModelCache)

	-- Helper function to get the appropriate model for an ammo type
	local function GetAmmoModel(Entity)
		-- Use missile model if available (sent from server)
		if Entity.RoundModel then
			return Entity.RoundModel
		end

		-- Default model for all rounds (no more box logic)
		local Model = "models/munitions/round_100mm.mdl"

		-- Try to get the model from the ammo type
		if Entity.BulletData and Entity.BulletData.Type then
			local AmmoType = ACF.Classes.AmmoTypes.Get(Entity.BulletData.Type)
			if AmmoType and AmmoType.Model then
				Model = AmmoType.Model
			end
		end

		return Model
	end



	-- Helper function to get or create a cached clientside model (without scaling)
	local function GetCachedModel(ModelPath)
		if not ModelCache[ModelPath] then
			ModelCache[ModelPath] = ClientsideModel(ModelPath, RENDERGROUP_OPAQUE)
			if IsValid(ModelCache[ModelPath]) then
				ModelCache[ModelPath]:SetNoDraw(true) -- Don't draw automatically
			end
		end
		return ModelCache[ModelPath]
	end

	local ModelBoundsCache = {}

	local function GetModelBounds(ModelPath)
		if ModelBoundsCache[ModelPath] then
			return ModelBoundsCache[ModelPath]
		end

		local Model = GetCachedModel(ModelPath)
		if not IsValid(Model) then return nil end

		local Mins, Maxs = Model:GetModelBounds()
		local Size = Maxs - Mins

		ModelBoundsCache[ModelPath] = Size

		return Size
	end

	local function GetModelScale(RoundSize, ModelPath, HasCustomModel)
		local ModelSize = GetModelBounds(ModelPath)
		if not ModelSize then return Vector(1, 1, 1) end

		if HasCustomModel then
			return Vector(
				RoundSize.x / ModelSize.x,
				RoundSize.y / ModelSize.y,
				RoundSize.z / ModelSize.z
			)
		end

		return Vector(
			RoundSize.y / ModelSize.x,
			RoundSize.z / ModelSize.y,
			RoundSize.x / ModelSize.z
		)
	end

	local function ScaleChanged(Old, New)
		return not Old or Old.x ~= New.x or Old.y ~= New.y or Old.z ~= New.z
	end

	local function EnsureModelPool(Entity, Count, ModelPath, ModelScale)
		if not Entity._RoundModels then
			Entity._RoundModels = {}
			Entity._RoundModelPath = ModelPath
			Entity._ScaleVec = ModelScale
			Entity._ScaleMatrix = Matrix()
			Entity._ScaleMatrix:SetScale(ModelScale)
		end

		if Entity._RoundModelPath ~= ModelPath then
			for _, Mdl in ipairs(Entity._RoundModels) do
				if IsValid(Mdl) then Mdl:Remove() end
			end
			Entity._RoundModels = {}
			Entity._RoundModelPath = ModelPath
		end

		if ScaleChanged(Entity._ScaleVec, ModelScale) then
			Entity._ScaleVec = ModelScale
			Entity._ScaleMatrix:SetScale(ModelScale)
			for _, Mdl in ipairs(Entity._RoundModels) do
				if IsValid(Mdl) then
					Mdl:EnableMatrix("RenderMultiply", Entity._ScaleMatrix)
				end
			end
		end

		for i = #Entity._RoundModels + 1, Count do
			local Mdl = ClientsideModel(ModelPath, RENDERGROUP_OPAQUE)
			if IsValid(Mdl) then
				Mdl:SetNoDraw(true)
				Mdl:DrawShadow(false)
				Mdl:EnableMatrix("RenderMultiply", Entity._ScaleMatrix)
				Entity._RoundModels[i] = Mdl
			end
		end
	end

	local function DrawRounds(Entity, Center, Spacing, Fits, RoundSize, RoundAngle, Total)
		local arrangement = Vector(Fits.x, Fits.y, Fits.z)
		local crateDimensions = ACF.GetCrateDimensions(arrangement, RoundSize)
		local StartPosX = -crateDimensions.x * 0.5 + RoundSize.x * 0.5
		local StartPosY = -crateDimensions.y * 0.5 + RoundSize.y * 0.5
		local StartPosZ = -crateDimensions.z * 0.5 + RoundSize.z * 0.5
		local StartPos = StartPosX * RoundAngle:Forward() + StartPosY * RoundAngle:Right() + StartPosZ * RoundAngle:Up()
		local Count = 0
		local ModelPath = GetAmmoModel(Entity)
		local HasCustomModel = Entity.RoundModel ~= nil
		local NeedRecalc = not Entity._ModelScale
			or Entity._CachedModelPath ~= ModelPath
			or ScaleChanged(Entity._CachedRoundSize, RoundSize)

		if NeedRecalc then
			Entity._ModelScale = GetModelScale(RoundSize, ModelPath, HasCustomModel)
			Entity._CachedModelPath = ModelPath
			Entity._CachedRoundSize = Vector(RoundSize.x, RoundSize.y, RoundSize.z)
		end

		EnsureModelPool(Entity, Total, ModelPath, Entity._ModelScale)

		local ProjectileAngle = Angle(RoundAngle.p, RoundAngle.y, RoundAngle.r)
		if not HasCustomModel then
			ProjectileAngle:RotateAroundAxis(RoundAngle:Right(), -90)
		end

		for X = 1, Fits.x do
			for Y = 1, Fits.y do
				for Z = 1, Fits.z do
					local LocalPos = GetPosition(X, Y, Z, RoundSize, Spacing, RoundAngle, 1, Entity.IsBelted, Fits)
					local RoundPos = Center + StartPos + LocalPos

					if Entity.IsRound then
						local ModelPos = RoundPos

						if HasCustomModel and Entity.RoundOffset then
							local Offset = Entity.RoundOffset
							ModelPos = ModelPos + RoundAngle:Forward() * Offset.x
								+ RoundAngle:Right() * Offset.y
								+ RoundAngle:Up() * Offset.z
						elseif not HasCustomModel then
							ModelPos = RoundPos - RoundAngle:Forward() * (RoundSize.x * 0.5)
						end

						local idx = Count + 1
						local M = Entity._RoundModels and Entity._RoundModels[idx]
						if IsValid(M) then
							M:SetPos(ModelPos)
							M:SetAngles(ProjectileAngle)
							M:DrawModel()
						end
					else
						local C = Entity.IsBelted and Yellow or Orange
						render.DrawWireframeBox(RoundPos, RoundAngle, -RoundSize * 0.5, RoundSize * 0.5, C)
					end

					Count = Count + 1

					if Count == Total then return end
				end
			end
		end
	end

	function ENT:CanDrawOverlay() -- This is called to see if DrawOverlay can be called
		return DrawBoxes:GetBool()
	end


		local function IsCrateTargeted(self)
			local ply = LocalPlayer()
			if not IsValid(ply) then return false end
			local tr = ply:GetEyeTrace()
			return tr and tr.Entity == self
		end

	local orange = Color(255, 127, 0)
	function ENT:DrawStage()
		local CratePos = self:GetPos():ToScreen()
		cam.Start2D()
			-- TODO: REMOVE AMMO COUNT WHEN DONE DEVELOPMENT
			draw.SimpleTextOutlined("S: " .. (self.AmmoStage or -1), "ACF_Title", CratePos.x, CratePos.y, orange, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			draw.SimpleTextOutlined("A: " .. (self.Ammo or -1), "ACF_Title", CratePos.x, CratePos.y + 15, orange, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
		cam.End2D()
	end

	-- Draw in opaque pass. When looking at the crate, hide the exterior and show internals
	function ENT:Draw()
		local looking = IsCrateTargeted(self)
		local canShowInternals = looking and DrawBoxes:GetBool() and self.HasData and self.FinalAmmo > 0 and self.LocalAng ~= nil

		if not canShowInternals then
			-- Default rendering path (preserves Wire overlay/outline)
			if self.BaseClass and self.BaseClass.Draw then
				self.BaseClass.Draw(self)
			else
				self:DrawModel()
			end
			return
		end

		-- We are showing internals: do NOT draw the normal exterior model so it doesn't block the view
		-- Still render Wire overlay/halo by calling Wire_Render after

		-- Ensure we have data
		if self.HasData == nil and self.RequestAmmoData then
			self:RequestAmmoData()
			return
		end

		local RoundAngle = self:LocalToWorldAngles(self.LocalAng)
		local Center = self:LocalToWorld(self:OBBCenter())
		local RoundSize = self.RoundSize
		local Spacing = self.Spacing
		local Fits = self.ProjectileCounts

		-- Keep Wire overlay alive while we bypass the base draw
		local HideInfo = ACF and ACF.HideInfoBubble
		if not (HideInfo and HideInfo()) then
			self:AddWorldTip()
		end
		local cvarOutline = GetConVar("wire_drawoutline")
		if cvarOutline and cvarOutline:GetBool() then
			self:DrawEntityOutline()
		end

		-- Draw the interior rounds with normal depth testing
		DrawRounds(self, Center, Spacing, Fits, RoundSize, RoundAngle, self.FinalAmmo)

		-- Optional: debug the computed internal bounds to verify Y/Z extents match what we draw
		local debugCvar = GetConVar("acf_debug_ammo_bounds")
		if debugCvar and debugCvar:GetBool() then
			local crateDims = ACF.GetCrateDimensions(Vector(Fits.x, Fits.y, Fits.z), RoundSize)
			local mins = -crateDims * 0.5
			local maxs = crateDims * 0.5
			-- Draw a thin wireframe of our computed interior volume at the same orientation used for rounds (green)
			render.DrawWireframeBox(Center, RoundAngle, mins, maxs, Color(0, 255, 0, 200), true)
			-- If cvar >= 2, also draw the actual entity OBB (red) to compare with the model shell
			if debugCvar:GetInt() >= 2 then
				local obbMins, obbMaxs = self:OBBMins(), self:OBBMaxs()
				local obbCenter = self:LocalToWorld(self:OBBCenter())
				render.DrawWireframeBox(obbCenter, self:GetAngles(), obbMins, obbMaxs, Color(255, 0, 0, 200), true)
			end
		end

		-- Draw only the interior faces of the model for the cutaway view
		render.CullMode(MATERIAL_CULLMODE_CW)
		self:DrawModel()
		render.CullMode(MATERIAL_CULLMODE_CCW)

		-- Make sure Wire overlay/wires render even though we skipped BaseClass.Draw
		if Wire_Render then Wire_Render(self) end
	end

	function ENT:DrawTranslucent()
		return
	end


	function ENT:DrawOverlay() -- Only 2D overlay text/debug should be here
		self:DrawStage()
	end
end
