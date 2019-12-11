--Chad provided a fix for multicore rendering.
include('shared.lua')

surface.CreateFont("torchfont", {size=40, weight=1000, antialias=true, additive=false, font="arial"})

-- moved these to the top, you don't want to be calling this every frame
local RT = GetRenderTarget( "GModToolgunScreen", 256, 256 )
local ToolGunMaterial = Material( "models/weapons/v_toolgun/screen" )
local tex = surface.GetTextureID( "models/props_combine/combine_interface_disp" )

function SWEP:ViewModelDrawn()

	local Health = math.floor(self.Weapon:GetNWFloat("HP", 0) *10)/10 
	local MaxHealth = math.floor(self.Weapon:GetNWFloat("MaxHP", 0) * 10)/10
	local Armour = math.floor(self.Weapon:GetNWFloat("Armour", 0) *100)/100
	local MaxArmour = math.floor(self.Weapon:GetNWFloat("MaxArmour", 0) *100)/100
	
	local HealthTxt = Health.."/"..MaxHealth.."\n"
	local ArmourTxt = Armour.."/"..MaxArmour.."\n"
	
	local HealthPercent = Health/MaxHealth
	local ArmourPercent = Armour/MaxArmour

	ToolGunMaterial:SetTexture("$basetexture", RT)
	
	local OldRT = render.GetRenderTarget();

	render.SetRenderTarget(RT)
	render.SetViewPort(0, 0, 256, 256)
	
		cam.Start2D()

			local Flicker = math.random(100,200)
			surface.SetDrawColor(255,255,255,Flicker)
			
			surface.SetTexture(tex) 
			surface.DrawTexturedRect(0, 0, 256, 256)
			surface.SetDrawColor(255,255,255,255)

			--surface.SetFont("TorchFont")			-- this was unused, no reason to call it
			--local w, h = surface.GetTextSize(" ")	-- this was unused, no reason to call it
			
			draw.SimpleTextOutlined("ACF Stats", "torchfont", 128, 30, Color(224, 224, 255, Flicker), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, Flicker))
			
			draw.RoundedBox( 5, 10, 83, 236, 64, Color(200, 200, 200, Flicker))
			draw.RoundedBox( 5, 15, 88, ArmourPercent*226, 54, Color(0, 0, 200, Flicker))
			
			draw.RoundedBox( 5, 10, 183, 236, 64, Color(200, 200, 200, Flicker))
			draw.RoundedBox( 5, 15, 188, HealthPercent*226, 54, Color(200, 0, 0, Flicker))
			
			draw.SimpleTextOutlined("Armour", "torchfont", 128, 100, Color(224, 224, 255, Flicker), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, Flicker))
			draw.SimpleTextOutlined(ArmourTxt, "torchfont", 128, 150, Color(224, 224, 255, Flicker), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, Flicker))
			
			draw.SimpleTextOutlined("Health", "torchfont", 128, 200, Color(224, 224, 255, Flicker), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, Flicker))
			draw.SimpleTextOutlined(HealthTxt, "torchfont", 128, 250, Color(224, 224, 255, Flicker), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, Flicker))

		cam.End2D()
		
	render.SetRenderTarget(OldRT)
	
end