include("shared.lua")

local RoundsDisplayCVar = GetConVar("ACF_MaxRoundsDisplay")
local HideInfo = ACF.HideInfoBubble
local Distance = ACF.RefillDistance
local Refills = {}
local Queued = {}

local function UpdateClAmmo(Entity)
	if not IsValid(Entity) then return end
	if not Entity.HasData then
		if Entity.HasData == nil then
			Entity:RequestAmmoData()
		end

		return
	end

	local MaxDisplayRounds = RoundsDisplayCVar:GetInt()

	Entity.Ammo = math.Clamp(Entity:GetNWInt("Ammo", 0), 0, Entity.Capacity)

	local FinalAmmo = Entity.HasBoxedAmmo and math.floor(Entity.Ammo / Entity.MagSize) or Entity.Ammo

	Entity.BulkDisplay = FinalAmmo > MaxDisplayRounds
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
		Entity.MagSize = Data.MGS
		Entity.HasBoxedAmmo = Data.MGS > 0
	end

	if Queued[Entity] then
		Queued[Entity] = nil
	end

	UpdateClAmmo(Entity)
end)

function ENT:Initialize()
	self:SetNWVarProxy("Ammo", function()
		UpdateClAmmo(self)
	end)

	cvars.AddChangeCallback("ACF_MaxRoundsDisplay", function()
		UpdateClAmmo(self)
	end)

	self.DrawAmmoHookIndex = "draw_ammo_" .. self:EntIndex()
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

	hook.Remove("PostDrawOpaqueRenderables",self.DrawAmmoHookIndex)
end

-- TODO: Resupply effect library, should apply for both ammo and fuel
do -- Resupply effect
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
			render.DrawSphere(Refill:GetPos(), Distance, 50, 50, Color(255, 255, 0, 10))
			render.DrawSphere(Refill:GetPos(), -Distance, 50, 50, Color(255, 255, 0, 10))
		end
	end)
end
