local ACF = ACF
local IsValid = IsValid

include("shared.lua")

killicon.Add("acf_torch", "HUD/killicons/acf_torch", ACF.KillIconColor)
SWEP.WepSelectIcon = surface.GetTextureID("vgui/acf_torch_wepselect")

-- Returns the entity under the crosshair if the local player is wielding the torch and it has a volumetric mesh.
local function GetTorchTraceTarget()
	local Player = LocalPlayer()
	local Weapon = Player:GetActiveWeapon()
	if not IsValid(Weapon) or Weapon:GetClass() ~= "acf_torch" then return end

	local TraceData = {start = Player:GetShootPos(), endpos = Player:GetShootPos() + Player:GetAimVector() * 64, mask = MASK_SOLID, filter = {Player}}
	local Trace = util.TraceLine(TraceData)
	local Entity = Trace.Entity
	if not IsValid(Entity) or not Entity.ACF_Volumetric_Mesh then return end

	return Weapon, Trace, Entity
end

hook.Add("PostDrawOpaqueRenderables", "ACF_Torch_WorldTip", function(bDrawingDepth, _, bDrawingSkybox)
	if bDrawingDepth or bDrawingSkybox then return end

	local Weapon, Trace, Entity = GetTorchTraceTarget()
	if not Weapon then return end

	local Dir       = (Trace.HitPos - Trace.StartPos):GetNormalized()
	local ConvexHit = ACF.GetConvexHit(Entity, Trace.HitPos, Dir, true)
	if not ConvexHit then return end
	if Weapon:GetNWInt("ConvexID", -1) ~= ConvexHit.ConvexID then return end

	local Health    = Weapon:GetNWFloat("ConvexHealth", 0)
	local MaxHealth = Weapon:GetNWFloat("ConvexMaxHealth", 0)

	AddWorldTip(Entity, string.format("HP: %.2f / %.2f", Health, MaxHealth), nil, Trace.HitPos)
end)
