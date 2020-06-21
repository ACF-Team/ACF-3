include("shared.lua")
local RoundsDisplayCVar = GetConVar("ACF_MaxRoundsDisplay")

local function UpdateBulkDisplay(ent)
	local MaxDisplayRounds = RoundsDisplayCVar:GetInt()
	local FinalAmmo = 0
	if (ent.HasBoxedAmmo or false) then FinalAmmo = math.floor((ent.Ammo or 0) / ent.MagSize) else FinalAmmo = (ent.Ammo or 0) end

	if FinalAmmo > MaxDisplayRounds then
		ent.BulkDisplay = true
	else ent.BulkDisplay = false end
end

local function UpdateClAmmo(ent)
	ent.Ammo = ent:GetNWInt("Ammo",0)
	if ent.Ammo > (ent.MaxAmmo or 0) then ent.MaxAmmo = ent.Ammo end
	UpdateBulkDisplay(ent)
end

local HideInfo = ACF.HideInfoBubble
local Refills = {}

function ENT:Initialize()
	self.Crates = {}
	self.Refills = {}
	self.HitBoxes = {
		Main = {
			Pos = self:OBBCenter(),
			Scale = (self:OBBMaxs() - self:OBBMins()) - Vector(2, 2, 2),
			Angle = Angle(0, 0, 0),
			Sensitive = false
		}
	}

	self:SetNWVarProxy("Ammo",function()
		UpdateClAmmo(self)
	end)

	cvars.AddChangeCallback("ACF_MaxRoundsDisplay",function()
		UpdateBulkDisplay(self)
	end)

	self.DrawAmmoHookIndex = "draw_ammo_" .. self:EntIndex()
	self.BaseClass.Initialize(self)
end

net.Receive("ACF_UpdateAmmoBox",function()
	local SVAmmoBox = net.ReadEntity()
	local SVAmmoTable = net.ReadTable()
	local ent = ents.GetByIndex(SVAmmoBox:EntIndex())
	ent.Capacity = SVAmmoTable.Capacity
	ent.IsRound = SVAmmoTable.IsRound
	ent.RoundSize = SVAmmoTable.RoundSize
	ent.LocalAng = SVAmmoTable.LocalAng
	ent.FitPerAxis = SVAmmoTable.FitPerAxis
	ent.Spacing = SVAmmoTable.Spacing
	ent.MagSize = SVAmmoTable.MGS
	ent.HasBoxedAmmo = ent.MagSize > 0

	UpdateClAmmo(ent)
	ent.MaxAmmo = ent.Ammo
	UpdateBulkDisplay(ent)

	ent.HasData = true
end)

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
	self:SetNoDraw(false)
	hook.Remove("PostDrawOpaqueRenderables",self.DrawAmmoHookIndex)
end

do -- Resupply effect
	local ModelData = { model = true, pos = true, angle = true }
	local Unused = {}
	local Used = {}

	local function GetClientsideModel()
		local Entity = next(Unused) or ClientsideModel("models/props_junk/PopCan01a.mdl", RENDERGROUP_OPAQUE)

		Unused[Entity] = nil
		Used[Entity] = true

		return Entity
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
	end)
end
