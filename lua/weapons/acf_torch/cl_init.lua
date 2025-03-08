local ACF             = ACF
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

function SWEP:PostDrawViewModel()
	local Health = math.Round(self:GetNWFloat("HP", 0), 1)
	local MaxHealth = math.Round(self:GetNWFloat("MaxHP", 0), 1)
	local Armor = math.Round(self:GetNWFloat("Armour", 0), 2)
	local MaxArmor = math.Round(self:GetNWFloat("MaxArmour", 0), 2)

	local Flicker = math.random(220, 240)
	local TextColor = Color(224, 224, 255, Flicker)
	local OutColor = Color(0, 0, 0, Flicker)

	local Text = language.GetPhrase("acf.torch.stats")
	local ArmorText = Text:format(Armor, MaxArmor)
	local HealthText = Text:format(Health, MaxHealth)
	local ArmorRatio = math.Clamp(Armor / MaxArmor, 0, 1)
	local HealthRatio = math.Clamp(Health / MaxHealth, 0, 1)

	ToolGunMaterial:SetTexture("$basetexture", RT)

	local OldRT = render.GetRenderTarget()

	render.SetRenderTarget(RT)
	render.SetViewPort(0, 0, 256, 256)
	render.Clear(0, 0, 0, 255)

	cam.Start2D()
		surface.SetTexture(Texture)
		surface.DrawTexturedRect(0, 0, 256, 256)
		surface.SetDrawColor(255, 255, 255, Flicker)
		draw.SimpleTextOutlined("#acf.torch.stats_title", "torchfont", 128, 48, TextColor, Center, Center, 4, OutColor)

		if MaxHealth > 0 then
			if MaxArmor > 0  then
				draw.RoundedBox(5, 10, 83, 236, 64, Color(200, 200, 200, Flicker))
				draw.RoundedBox(5, 15, 88, ArmorRatio * 226, 54, Color(0, 0, 200, Flicker))
				draw.SimpleTextOutlined("#acf.menu.armor", "torchfont", 128, 100, TextColor, Center, Center, 4, OutColor)
				draw.SimpleTextOutlined(ArmorText, "torchfont", 128, 150, TextColor, Center, Center, 4, OutColor)
			end

			draw.RoundedBox(5, 10, 183, 236, 64, Color(200, 200, 200, Flicker))
			draw.RoundedBox(5, 15, 188, HealthRatio * 226, 54, Color(200, 0, 0, Flicker))
			draw.SimpleTextOutlined("#acf.menu.health", "torchfont", 128, 200, TextColor, Center, Center, 4, OutColor)
			draw.SimpleTextOutlined(HealthText, "torchfont", 128, 250, TextColor, Center, Center, 4, OutColor)
		else
			draw.SimpleTextOutlined("#acf.torch.no_target", "torchfont", 128, 140, TextColor, Center, Center, 4, OutColor)
		end
	cam.End2D()

	render.SetRenderTarget(OldRT)
end