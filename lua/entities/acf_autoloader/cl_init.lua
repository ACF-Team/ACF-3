include("shared.lua")

net.Receive("ACF_Autoloader_Links", function()
	local EntIndex1 = net.ReadUInt(16)
	local EntIndex2 = net.ReadUInt(16)
	local State = net.ReadBool()

	local Ent = Entity(EntIndex1)
	if not IsValid(Ent) then return end
	if State then Ent.Target = EntIndex2 else Ent.Target = nil end
end)

net.Receive("ACF_Autoloader_AmmoLinks", function()
	local EntIndex1 = net.ReadUInt(16)
	local EntIndex2 = net.ReadUInt(16)
	local State = net.ReadBool()

	local Ent = Entity(EntIndex1)
	if not IsValid(Ent) then return end
	if State then Ent.AmmoTarget = EntIndex2 else Ent.AmmoTarget = nil end
end)

local Purple = Color(255, 0, 255, 100)
function ENT:DrawOverlay()
	render.SetColorMaterial()
	local Gun = self.Target and Entity(self.Target)
	if IsValid(Gun) then
		-- Visualize autoloader position and breech position
		local Pos1 = self:GetPos()
		local Pos2 = Gun.BreechPos or Gun:GetPos()
		render.DrawBeam(Pos1, Pos2, 2, 0, 1, Purple)
		render.DrawWireframeSphere(Pos1, 2, 10, 10, Purple, true)
		render.DrawWireframeSphere(Pos2, 2, 10, 10, Purple, true)
	end

	local Ammo = self.AmmoTarget and Entity(self.AmmoTarget)
	if IsValid(Ammo) then
		if Ammo.HasData == nil then Ammo:RequestAmmoData() end

		if Ammo.LocalAng then
			-- Visualize the orientation the ammo would feed towards
			local AmmoPos = Ammo:GetPos()
			local AmmoAng = Ammo:LocalToWorldAngles(Ammo.LocalAng)
			debugoverlay.Line(AmmoPos, AmmoPos + AmmoAng:Forward() * 20, 0.1, Color(255, 0, 0), true)
			debugoverlay.Line(AmmoPos, AmmoPos + AmmoAng:Right() * 20, 0.1, Color(0, 255, 0), true)
			debugoverlay.Line(AmmoPos, AmmoPos + AmmoAng:Up() * 20, 0.1, Color(0, 0, 255), true)
		end
	end
end

ACF.Classes.Entities.Register()