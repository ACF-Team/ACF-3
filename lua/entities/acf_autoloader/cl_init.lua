include("shared.lua")

net.Receive("ACF_Autoloader_Links", function()
	local EntIndex1 = net.ReadUInt(16)
	local EntIndex2 = net.ReadUInt(16)
	local State = net.ReadBool()

	local Ent = Entity(EntIndex1)
	if not IsValid(Ent) then return end
	if State then Ent.Target = EntIndex2 else Ent.Target = nil end
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
end

ACF.Classes.Entities.AutoRegisterV1()