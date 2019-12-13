DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName     = "ACF Ammo Crate"
ENT.WireDebugName = "ACF Ammo Crate"

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
	local vec = Vector(0, 0, 0)
	vec = Bezier(Table[1], Table[2], Table[3], Table[4], perc)

	return vec
end

function ACF_DrawRefillAmmo(Table)
	for _, v in pairs(Table) do
		local St, En = v.EntFrom:LocalToWorld(v.EntFrom:OBBCenter()), v.EntTo:LocalToWorld(v.EntTo:OBBCenter())
		local Distance = (En - St):Length()
		local Amount = math.Clamp(Distance / 50, 2, 100)
		local Time = (SysTime() - v.StTime)
		local En2, St2 = En + Vector(0, 0, 100), St + ((En - St):GetNormalized() * 10)
		local vectab = {St, St2, En2, En}
		local center = (St + En) / 2

		for I = 1, Amount do
			local point = BezPoint((I + Time) % Amount / Amount, vectab)
			local ang = (point - center):Angle()

			local MdlTbl = {
				model = v.Model,
				pos = point,
				angle = ang
			}

			render.Model(MdlTbl)
		end
	end
end

function ACF_TrimInvalidRefillEffects(effectsTbl)
	local effect

	for i = 1, #effectsTbl do
		effect = effectsTbl[i]

		if not (IsValid(effect.EntFrom) and IsValid(effect.EntTo)) then
			effectsTbl[i] = nil
		end
	end
end

CreateClientConVar("ACF_AmmoInfoWhileSeated", 0, true, false)

function ENT:Draw()
	local lply = LocalPlayer()
	local hideBubble = not GetConVar("ACF_AmmoInfoWhileSeated"):GetBool() and IsValid(lply) and lply:InVehicle()
	self.BaseClass.DoNormalDraw(self, false, hideBubble)
	Wire_Render(self)

	if self.GetBeamLength and (not self.GetShowBeam or self:GetShowBeam()) then
		-- Every SENT that has GetBeamLength should draw a tracer. Some of them have the GetShowBeam boolean
		Wire_DrawTracerBeam(self, 1, self.GetBeamHighlight and self:GetBeamHighlight() or false)
	end

	--self.BaseClass.Draw( self )
	if self.RefillAmmoEffect then
		ACF_TrimInvalidRefillEffects(self.RefillAmmoEffect)
		ACF_DrawRefillAmmo(self.RefillAmmoEffect)
	end
end

net.Receive("ACF_RefillEffect", function()
	local EntFrom = ents.GetByIndex(net.ReadFloat())
	local EntTo   = ents.GetByIndex(net.ReadFloat())

	if not IsValid(EntFrom) or not IsValid(EntTo) then return end
	--local List = list.Get( "ACFRoundTypes")	
	-- local Mdl = ACF.Weapons.Guns[Weapon].round.model or "models/munitions/round_100mm_shot.mdl"
	local Mdl = "models/munitions/round_100mm_shot.mdl"
	EntFrom.RefillAmmoEffect = EntFrom.RefillAmmoEffect or {}

	table.insert(EntFrom.RefillAmmoEffect, {
		EntFrom = EntFrom,
		EntTo = EntTo,
		Model = Mdl,
		StTime = SysTime()
	})
end)

net.Receive("ACF_StopRefillEffect", function()
	local EntFrom = ents.GetByIndex(net.ReadFloat())
	local EntTo   = ents.GetByIndex(net.ReadFloat())

	--print("stop", EntFrom, EntTo)
	if not IsValid(EntFrom) or not IsValid(EntTo) or not EntFrom.RefillAmmoEffect then return end

	for k, v in pairs(EntFrom.RefillAmmoEffect) do
		if v.EntTo == EntTo then
			if #EntFrom.RefillAmmoEffect <= 1 then
				EntFrom.RefillAmmoEffect = nil

				return
			end

			table.remove(EntFrom.RefillAmmoEffect, k)
		end
	end
end)