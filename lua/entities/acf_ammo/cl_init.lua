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

	local MaxDisplayRounds = MaxRounds:GetInt()

	Entity.Ammo = Ammo or Entity:GetNWInt("Ammo", 0)
	Entity.FinalAmmo = Entity.HasBoxedAmmo and math.floor(Entity.Ammo / Entity.MagSize) or Entity.Ammo
	Entity.BulkDisplay = Entity.FinalAmmo > MaxDisplayRounds
end

net.Receive("ACF_RequestAmmoData", function()
	local Entity = net.ReadEntity()
	local Data = util.JSONToTable(net.ReadString())

	if not IsValid(Entity) then return end

	Entity.HasData = Data.Enabled

	if Data.Enabled then
		Entity.Capacity = Data.Capacity
		Entity.IsRound = Data.IsRound
		Entity.RoundSize = Data.RoundSize
		Entity.LocalAng = Data.LocalAng
		Entity.FitPerAxis = Data.FitPerAxis
		Entity.Spacing = Data.Spacing
		Entity.MagSize = Data.MagSize
		Entity.HasBoxedAmmo = Data.IsBoxed
		Entity.AmmoStage = Data.AmmoStage
		Entity.IsBelted = Data.IsBelted or false
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

	cvars.RemoveChangeCallback("acf_maxroundsdisplay", "Ammo Crate " .. self:EntIndex())
end

do -- Ammo overlay
	local DrawBoxes = GetConVar("acf_drawboxes")

	-- Ammo overlay colors
	local Blue   = Color(0, 127, 255, 65)
	local Orange = Color(255, 127, 0, 65)
	local Green  = Color(0, 255, 0, 65)
	local Red    = Color(255, 0, 0, 65)
	local Yellow = Color(255, 255, 0, 65)

	local function GetPosition(X, Y, Z, RoundSize, Spacing, RoundAngle, Direction, IsBelted)
		local AlteredSpacing = IsBelted and 0 or Spacing
		local SizeX = (X - 1) * (RoundSize.x + AlteredSpacing) * RoundAngle:Forward() * Direction
		local SizeY = (Y - 1) * (RoundSize.y + AlteredSpacing) * RoundAngle:Right() * Direction
		local SizeZ = (Z - 1) * (RoundSize.z + AlteredSpacing) * RoundAngle:Up() * Direction

		return SizeX + SizeY + SizeZ
	end

	local function DrawRounds(Entity, Center, Spacing, Fits, RoundSize, RoundAngle, Total)
		local StartPos = GetPosition(Fits.x, Fits.y, Fits.z, RoundSize, Spacing, RoundAngle, 1, Entity.IsBelted) * 0.5
		local Count    = 0

		for X = 1, Fits.x do
			for Y = 1, Fits.y do
				for Z = 1, Fits.z do
					local LocalPos = GetPosition(X, Y, Z, RoundSize, Spacing, RoundAngle, -1, Entity.IsBelted)
					local C = Entity.IsRound and Blue or Entity.HasBoxedAmmo and Green or Entity.IsBelted and Yellow or Orange

					render.DrawWireframeBox(Center + StartPos + LocalPos, RoundAngle, -RoundSize * 0.5, RoundSize * 0.5, C)

					Count = Count + 1

					if Count == Total then return end
				end
			end
		end
	end

	function ENT:CanDrawOverlay() -- This is called to see if DrawOverlay can be called
		return DrawBoxes:GetBool()
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

	function ENT:DrawOverlay() -- Trace is passed as first argument, but not needed
		if not self.HasData then
			if self.HasData == nil and self.RequestAmmoData then
				self:RequestAmmoData()
			end

			return
		end
		if self.FinalAmmo <= 0 then return end
		if not self.LocalAng then return end

		local RoundAngle = self:LocalToWorldAngles(self.LocalAng)
		local Center = self:LocalToWorld(self:OBBCenter())
		local RoundSize = self.RoundSize
		local Spacing = self.Spacing
		local Fits = self.FitPerAxis
		local BorderShift = Vector(0.5, 0.5, 0.5)

		if not self.BulkDisplay then
			DrawRounds(self, Center, Spacing, Fits, RoundSize, RoundAngle, self.FinalAmmo)
		else -- Basic bitch box that scales according to ammo, only for bulk display
			local AmmoPerc = self.Ammo / self.Capacity
			render.DrawWireframeBox(Center, self:GetAngles(), self:OBBMins() + BorderShift, (self:OBBMaxs() - BorderShift) * Vector(1, 1, (2 * AmmoPerc) - 1), Red)
		end
		self:DrawStage()
	end
end
