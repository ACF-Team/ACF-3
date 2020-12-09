include("shared.lua")

language.Add("Cleanup_acf_ammo", "ACF Ammo Crates")
language.Add("Undone_acf_ammo", "Undone ACF Ammo Crate")
language.Add("Cleaned_acf_ammo", "Cleaned up all ACF Ammo Crates")
language.Add("SBoxLimit__acf_ammo", "You've reached the ACF Ammo Crates limit!")

local MaxRounds = GetConVar("acf_maxroundsdisplay")
local HideInfo = ACF.HideInfoBubble
local Refills = {}
local Queued = {}

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
		Entity.HasBoxedAmmo = Data.MagSize > 0
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

function ENT:Draw()
	self:DoNormalDraw(false, HideInfo())

	Wire_Render(self)

	if self.GetBeamLength and (not self.GetShowBeam or self:GetShowBeam()) then
		-- Every SENT that has GetBeamLength should draw a tracer. Some of them have the GetShowBeam boolean
		Wire_DrawTracerBeam(self, 1, self.GetBeamHighlight and self:GetBeamHighlight() or false)
	end
end

function ENT:OnRemove()
	Refills[self] = nil

	cvars.RemoveChangeCallback("acf_maxroundsdisplay", "Ammo Crate " .. self:EntIndex())
end

-- TODO: Resupply effect library, should apply for both ammo and fuel
do -- Resupply effect
	local Yellow = Color(255, 255, 0, 10)
	local Distance = ACF.RefillDistance

	net.Receive("ACF_RefillEffect", function()
		local Refill = net.ReadEntity()

		if not IsValid(Refill) then return end

		Refills[Refill] = true
	end)

	net.Receive("ACF_StopRefillEffect", function()
		local Refill = net.ReadEntity()

		if not IsValid(Refill) then return end

		Refills[Refill] = nil
	end)

	hook.Add("PostDrawTranslucentRenderables", "ACF Draw Refill", function()
		render.SetColorMaterial()

		for Refill in pairs(Refills) do
			local Pos = Refill:GetPos()

			render.DrawSphere(Pos, Distance, 50, 50, Yellow)
			render.DrawSphere(Pos, -Distance, 50, 50, Yellow)
		end
	end)
end

do -- Ammo overlay
	-- Ammo overlay colors
	local Blue   = Color(0, 127, 255, 65)
	local Orange = Color(255, 127, 0, 65)
	local Green  = Color(0, 255, 0, 65)
	local Red    = Color(255, 0, 0, 65)

	local function GetPosition(X, Y, Z, RoundSize, Spacing, RoundAngle, Direction)
		local SizeX = (X - 1) * (RoundSize.x + Spacing) * RoundAngle:Forward() * Direction
		local SizeY = (Y - 1) * (RoundSize.y + Spacing) * RoundAngle:Right() * Direction
		local SizeZ = (Z - 1) * (RoundSize.z + Spacing) * RoundAngle:Up() * Direction

		return SizeX + SizeY + SizeZ
	end

	local function DrawRounds(Entity, Center, Spacing, Fits, RoundSize, RoundAngle, Total)
		local Count = 0

		local StartPos = GetPosition(Fits.x, Fits.y, Fits.z, RoundSize, Spacing, RoundAngle, 1) * 0.5

		for X = 1, Fits.x do
			for Y = 1, Fits.y do
				for Z = 1, Fits.z do
					local LocalPos = GetPosition(X, Y, Z, RoundSize, Spacing, RoundAngle, -1)
					local C = Entity.IsRound and Blue or Entity.HasBoxedAmmo and Green or Orange

					render.DrawWireframeBox(Center + StartPos + LocalPos, RoundAngle, -RoundSize * 0.5, RoundSize * 0.5, C)

					Count = Count + 1

					if Count == Total then return end
				end
			end
		end
	end

	hook.Add("ACF_DrawBoxes", "ACF Draw Ammo", function(Entity)
		if not Entity.IsScalable then return end
		if not Entity.HasData then
			if Entity.HasData == nil and Entity.RequestAmmoData then
				Entity:RequestAmmoData()
			end

			return
		end
		if Entity.FinalAmmo <= 0 then return end

		local RoundAngle = Entity:LocalToWorldAngles(Entity.LocalAng)
		local Center = Entity:LocalToWorld(Entity:OBBCenter())
		local RoundSize = Entity.RoundSize
		local Spacing = Entity.Spacing
		local Fits = Entity.FitPerAxis

		if not Entity.BulkDisplay then
			DrawRounds(Entity, Center, Spacing, Fits, RoundSize, RoundAngle, Entity.FinalAmmo)
		else -- Basic bitch box that scales according to ammo, only for bulk display
			local AmmoPerc = Entity.Ammo / Entity.Capacity
			local SizeAdd = Vector(Spacing, Spacing, Spacing) * Fits
			local BulkSize = ((Fits * RoundSize * Vector(1, AmmoPerc, 1)) + SizeAdd) * 0.5
			local Offset = RoundAngle:Right() * (Fits.y * RoundSize.y) * 0.5 * (1 - AmmoPerc)

			render.DrawWireframeBox(Center + Offset, RoundAngle, -BulkSize, BulkSize, Red)
		end
	end)
end
