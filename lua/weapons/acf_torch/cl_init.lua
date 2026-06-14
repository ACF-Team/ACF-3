local ACF = ACF
local IsValid = IsValid

local RT              = GetRenderTarget("GModToolgunScreen", 256, 256)
local ToolGunMaterial = Material("models/weapons/v_toolgun/screen")
local Texture         = surface.GetTextureID("models/props_combine/combine_interface_disp")
local Center          = TEXT_ALIGN_CENTER

include("shared.lua")

surface.CreateFont("torchfont", {
	size = 40,
	weight = 1000,
	antialias = true,
	additive = false,
	font = "arial"
})

killicon.Add("acf_torch", "HUD/killicons/acf_torch", ACF.KillIconColor)
SWEP.WepSelectIcon = surface.GetTextureID("vgui/acf_torch_wepselect")

-- Draws the targeted entity's total health bar on the torch's screen. The per-convex armor and health stats are
-- shown on the world tip instead, so only the total health bar is drawn here.
function SWEP:PostDrawViewModel()
	local Health    = math.Round(self:GetNWFloat("EntHealth", 0), 1)
	local MaxHealth = math.Round(self:GetNWFloat("EntMaxHealth", 0), 1)

	local Flicker     = math.random(220, 240)
	local TextColor   = Color(224, 224, 255, Flicker)
	local OutColor    = Color(0, 0, 0, Flicker)
	local HealthText  = language.GetPhrase("acf.torch.stats"):format(Health, MaxHealth)
	local HealthRatio = MaxHealth > 0 and math.Clamp(Health / MaxHealth, 0, 1) or 0

	ToolGunMaterial:SetTexture("$basetexture", RT)

	local OldRT = render.GetRenderTarget()

	render.SetRenderTarget(RT)
	render.SetViewPort(0, 0, 256, 256)
	render.Clear(0, 0, 0, 255)

	cam.Start2D()
		surface.SetTexture(Texture)
		surface.SetDrawColor(255, 255, 255, Flicker)
		surface.DrawTexturedRect(0, 0, 256, 256)

		draw.SimpleTextOutlined("#acf.torch.stats_title", "torchfont", 128, 48, TextColor, Center, Center, 4, OutColor)

		if MaxHealth > 0 then
			draw.SimpleTextOutlined("#acf.menu.health", "torchfont", 128, 120, TextColor, Center, Center, 4, OutColor)
			draw.RoundedBox(5, 10, 145, 236, 64, Color(200, 200, 200, Flicker))
			draw.RoundedBox(5, 15, 150, HealthRatio * 226, 54, Color(200, 0, 0, Flicker))
			draw.SimpleTextOutlined(HealthText, "torchfont", 128, 177, TextColor, Center, Center, 4, OutColor)
		else
			draw.SimpleTextOutlined("#acf.torch.no_target", "torchfont", 128, 140, TextColor, Center, Center, 4, OutColor)
		end
	cam.End2D()

	render.SetRenderTarget(OldRT)
end

-- Returns the entity under the crosshair if the local player is wielding the torch and it has a volumetric mesh.
local function GetTorchTraceTarget()
	local Player = LocalPlayer()
	local Weapon = Player:GetActiveWeapon()
	if not IsValid(Weapon) or Weapon:GetClass() ~= "acf_torch" then return end

	local TraceData = {start = Player:GetShootPos(), endpos = Player:GetShootPos() + Player:GetAimVector() * Weapon.MaxDistance, mask = MASK_SOLID, filter = {Player}}
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

-- Draws the repair sphere's area of effect, and the damage point, at the trace's hit position.
local RepairSphereColor = Color(0, 200, 0, 50)
local RepairSphereFrame = Color(0, 200, 0, 100)
local DamagePointColor  = Color(200, 0, 0, 100)
local DamagePointRadius = 2

hook.Add("PostDrawOpaqueRenderables", "ACF_Torch_RepairSphere", function(bDrawingDepth, _, bDrawingSkybox)
	if bDrawingDepth or bDrawingSkybox then return end

	local Weapon, Trace = GetTorchTraceTarget()
	if not Weapon then return end

	local Radius = Weapon.RepairRadius

	render.SetColorMaterial()
	render.DrawSphere(Trace.HitPos, Radius, 20, 20, RepairSphereColor)
	render.DrawWireframeSphere(Trace.HitPos, Radius, 20, 20, RepairSphereFrame, true)
	render.DrawSphere(Trace.HitPos, DamagePointRadius, 12, 12, DamagePointColor)
end)
