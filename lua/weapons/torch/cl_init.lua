--Chad provided a fix for multicore rendering.
include("shared.lua")

surface.CreateFont("torchfont", {
	size = 40,
	weight = 1000,
	antialias = true,
	additive = false,
	font = "arial"
})

-- moved these to the top, you don't want to be calling this every frame
local RT = GetRenderTarget("GModToolgunScreen", 256, 256)
local ToolGunMaterial = Material("models/weapons/v_toolgun/screen")
local Texture = surface.GetTextureID("models/props_combine/combine_interface_disp")
local Center = TEXT_ALIGN_CENTER
local Text = "%s/%s\n"

function SWEP:ViewModelDrawn()
	local Health = math.Round(self:GetNWFloat("HP", 0), 1)
	local MaxHealth = math.Round(self:GetNWFloat("MaxHP", 0), 1)
	local Armor = math.Round(self:GetNWFloat("Armour", 0), 2)
	local MaxArmor = math.Round(self:GetNWFloat("MaxArmour", 0), 2)

	local Flicker = math.random(100, 150)
	local TextColor = Color(224, 224, 255, Flicker)
	local OutColor = Color(0, 0, 0, Flicker)

	local ArmorText = Text:format(Armor, MaxArmor)
	local HealthText = Text:format(Health, MaxHealth)
	local ArmorRatio = math.Clamp(Armor / MaxArmor, 0, 1)
	local HealthRatio = math.Clamp(Health / MaxHealth, 0, 1)

	ToolGunMaterial:SetTexture("$basetexture", RT)

	local OldRT = render.GetRenderTarget()

	render.SetRenderTarget(RT)
	render.SetViewPort(0, 0, 256, 256)

	cam.Start2D()
		surface.SetTexture(Texture)
		surface.DrawTexturedRect(0, 0, 256, 256)
		surface.SetDrawColor(255, 255, 255, Flicker)
		draw.SimpleTextOutlined("ACF Stats", "torchfont", 128, 30, TextColor, Center, Center, 4, OutColor)
		draw.RoundedBox(5, 10, 83, 236, 64, Color(200, 200, 200, Flicker))
		draw.RoundedBox(5, 15, 88, ArmorRatio * 226, 54, Color(0, 0, 200, Flicker))
		draw.RoundedBox(5, 10, 183, 236, 64, Color(200, 200, 200, Flicker))
		draw.RoundedBox(5, 15, 188, HealthRatio * 226, 54, Color(200, 0, 0, Flicker))
		draw.SimpleTextOutlined("Armor", "torchfont", 128, 100, TextColor, Center, Center, 4, OutColor)
		draw.SimpleTextOutlined(ArmorText, "torchfont", 128, 150, TextColor, Center, Center, 4, OutColor)
		draw.SimpleTextOutlined("Health", "torchfont", 128, 200, TextColor, Center, Center, 4, OutColor)
		draw.SimpleTextOutlined(HealthText, "torchfont", 128, 250, TextColor, Center, Center, 4, OutColor)
	cam.End2D()

	render.SetRenderTarget(OldRT)
end
