include("shared.lua")

local RoundsDisplayCVar = GetConVar("ACF_MaxRoundsDisplay")
local HideInfo = ACF.HideInfoBubble
local Refills = {}
local Queued = {}

local function UpdateClAmmo(Entity)
	if not IsValid(Entity) then return end
	if not Entity.HasData then
		return Entity:RequestAmmoData()
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

	Entity.Capacity = Data.Capacity
	Entity.IsRound = Data.IsRound
	Entity.RoundSize = Data.RoundSize
	Entity.LocalAng = Data.LocalAng
	Entity.FitPerAxis = Data.FitPerAxis
	Entity.Spacing = Data.Spacing
	Entity.MagSize = Data.MGS
	Entity.HasBoxedAmmo = Data.MGS > 0
	Entity.HasData = true

	if Queued[Entity] then
		Queued[Entity] = nil
	end

	UpdateClAmmo(Entity)
end)

function ENT:Initialize()
	self.Crates = {}
	self.Refills = {}

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

function ENT:OnResized()
	self.HitBoxes = {
		Main = {
			Pos = self:OBBCenter(),
			Scale = self:GetSize(),
			Angle = Angle(0, 0, 0),
			Sensitive = false
		}
	}

	self.HasData = nil
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

	for Refill in pairs(self.Refills) do
		if not IsValid(Refill) then continue end

		Refill.Crates[self] = nil

		if not next(Refill.Crates) then
			Refills[Refill] = nil
		end
	end

	hook.Remove("PostDrawOpaqueRenderables",self.DrawAmmoHookIndex)
end

-- TODO: Resupply effect library, should apply for both ammo and fuel
do -- Resupply effect
	local ModelData = { model = true, pos = true, angle = true }
	local Unused = {}
	local Used = {}

	local function GetClientsideModel()
		local Model

		if next(Unused) then
			Model = next(Unused)

			Unused[Model] = nil
		else
			Model = ClientsideModel("models/props_junk/PopCan01a.mdl", RENDERGROUP_OPAQUE)
		end

		Used[Model] = true

		return Model
	end

	--Shamefully stolen from lua rollercoaster. I'M SO SORRY. I HAD TO.
	local function Bezier(a, b, c, d, t)
		local ab, bc, cd, abbc, bccd
		ab = LerpVector(t, a, b)
		bc = LerpVector(t, b, c)
		cd = LerpVector(t, c, d)
		abbc = LerpVector(t, ab, bc)
		bccd = LerpVector(t, bc, cd)
		dest = LerpVector(t, abbc, bccd)

		return dest
	end

	local function DrawRefillEffect(Entity)
		for Crate, Data in pairs(Entity.Crates) do
			local Start = Entity:LocalToWorld(Data.RefillCenter)
			local End = Crate:LocalToWorld(Data.CrateCenter)
			local Delta = End - Start
			local Amount = math.Clamp(Delta:Length() * 0.02, 2, 25)
			local Time = ACF.CurTime - Data.Init
			local En2, St2 = End + Vector(0, 0, 100), Start + (Delta:GetNormalized() * 10)
			local Center = (Start + End) * 0.5

			for I = 1, Amount do
				local Point = Bezier(Start, St2, En2, End, (I + Time) % Amount / Amount)
				local Model = GetClientsideModel()

				ModelData.model = Data.Model
				ModelData.pos = Point
				ModelData.angle = (Point - Center):Angle()

				render.Model(ModelData, Model)
			end
		end
	end

	net.Receive("ACF_RefillEffect", function()
		local Refill = net.ReadEntity()
		local Target = net.ReadEntity()

		if not IsValid(Refill) then return end
		if not IsValid(Target) then return end

		Refills[Refill] = true
		Target.Refills[Refill] = true
		Refill.Crates[Target] = {
			Model = "models/munitions/round_100mm_shot.mdl",
			Init = ACF.CurTime,
			RefillCenter = Refill:OBBCenter(),
			CrateCenter = Target:OBBCenter()
		}
	end)

	net.Receive("ACF_StopRefillEffect", function()
		local Refill = net.ReadEntity()
		local Target = net.ReadEntity()

		if not IsValid(Refill) then return end
		if not IsValid(Target) then return end

		Refills[Refill] = nil
		Refill.Crates[Target] = nil
		Target.Refills[Refill] = nil

		Target:RemoveCallOnRemove("ACF Refill Effect " .. Refill:EntIndex())
	end)

	hook.Add("PostDrawOpaqueRenderables", "ACF Draw Refill", function()
		for Refill in pairs(Refills) do
			DrawRefillEffect(Refill)
		end

		-- Cleanup unused clientside models
		for Model in pairs(Unused) do
			Unused[Model] = nil

			Model:Remove()
		end

		-- Move all the used models to the unused table
		for Model in pairs(Used) do
			Unused[Model] = true
			Used[Model] = nil
		end
	end)
end
