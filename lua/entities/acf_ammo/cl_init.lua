include("shared.lua")

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

local function BezPoint(perc, Table)
	return Bezier(Table[1], Table[2], Table[3], Table[4], perc)
end

local function DrawRefillAmmo(Entity)
	for Crate, Data in pairs(Entity.Crates) do
		local St, En = Entity:LocalToWorld(Entity:OBBCenter()), Crate:LocalToWorld(Crate:OBBCenter())
		local Distance = (En - St):Length()
		local Amount = math.Clamp(Distance / 50, 2, 100)
		local Time = CurTime() - Data.Init
		local En2, St2 = En + Vector(0, 0, 100), St + ((En - St):GetNormalized() * 10)
		local vectab = {St, St2, En2, En}
		local center = (St + En) / 2

		for I = 1, Amount do
			local point = BezPoint((I + Time) % Amount / Amount, vectab)
			local ang = (point - center):Angle()

			local MdlTbl = {
				model = Data.Model,
				pos = point,
				angle = ang
			}

			render.Model(MdlTbl)
		end
	end
end

CreateClientConVar("ACF_AmmoInfoWhileSeated", 0, true, false)

function ENT:Initialize()
	self.Crates = {}
	self.HitBoxes = {
		Main = {
			Pos = self:OBBCenter(),
			Scale = (self:OBBMaxs() - self:OBBMins()) - Vector(2, 2, 2),
			Angle = Angle(0, 0, 0),
			Sensitive = false
		}
	}

	self.BaseClass.Initialize(self)
end

function ENT:Draw()
	local lply = LocalPlayer()
	local hideBubble = not GetConVar("ACF_AmmoInfoWhileSeated"):GetBool() and IsValid(lply) and lply:InVehicle()
	self.BaseClass.DoNormalDraw(self, false, hideBubble)
	Wire_Render(self)

	if self.GetBeamLength and (not self.GetShowBeam or self:GetShowBeam()) then
		-- Every SENT that has GetBeamLength should draw a tracer. Some of them have the GetShowBeam boolean
		Wire_DrawTracerBeam(self, 1, self.GetBeamHighlight and self:GetBeamHighlight() or false)
	end

	DrawRefillAmmo(self)
end

function ENT:OnRemove()
	for Crate in pairs(self.Crates) do
		Crate:RemoveCallOnRemove("ACF Refill Effect " .. self:EntIndex())
	end
end

net.Receive("ACF_RefillEffect", function()
	local Refill = net.ReadEntity()
	local Target = net.ReadEntity()

	if not IsValid(Refill) then return end
	if not IsValid(Target) then return end
	if Refill.Crates[Target] then return end

	Refill.Crates[Target] = {
		Model = "models/munitions/round_100mm_shot.mdl",
		Init = CurTime()
	}

	Target:CallOnRemove("ACF Refill Effect " .. Refill:EntIndex(), function()
		Refill.Crates[Target] = nil
	end)
end)

net.Receive("ACF_StopRefillEffect", function()
	local Refill = net.ReadEntity()
	local Target = net.ReadEntity()

	if not IsValid(Refill) then return end
	if not IsValid(Target) then return end
	if not Refill.Crates[Target] then return end

	Refill.Crates[Target] = nil

	Target:RemoveCallOnRemove("ACF Refill Effect " .. Refill:EntIndex())
end)