
AddCSLuaFile()

ACF.AmmoBlacklist.SM = { "MG", "C", "GL", "HMG", "AL", "AC", "RAC", "SA", "SC" }

local Round = {}

Round.type = "Ammo" --Tells the spawn menu what entity to spawn
Round.name = "Smoke (SM)" --Human readable name
Round.model = "models/munitions/round_100mm_shot.mdl" --Shell flight model
Round.desc = "A shell filled white phosporous, detonating on impact. Smoke filler produces a long lasting cloud but takes a while to be effective, whereas WP filler quickly creates a cloud that also dissipates quickly. \n\n Can only be used in the 40mm Smoke Launcher"
Round.netid = 6 --Unique ammotype ID for network transmission

function Round.create( Gun, BulletData )
	
	ACF_CreateBullet( BulletData )
	
end

-- Function to convert the player's slider data into the complete round data
function Round.convert( Crate, PlayerData )
	
	local Data = {}
	local ServerData = {}
	local GUIData = {}
	
	if not PlayerData.PropLength then PlayerData.PropLength = 0 end
	if not PlayerData.ProjLength then PlayerData.ProjLength = 0 end
	PlayerData.Data5 = math.max(PlayerData.Data5 or 0, 0)
	PlayerData.Data6 = math.max(PlayerData.Data6 or 0, 0)
	PlayerData.Data7 = tonumber(PlayerData.Data7) or 0  --catching some possible errors with string data in legacy dupes
	if not PlayerData.Data10 then PlayerData.Data10 = 0 end
	
	PlayerData, Data, ServerData, GUIData = ACF_RoundBaseGunpowder( PlayerData, Data, ServerData, GUIData )
	
	--Shell sturdiness calcs
	Data.ProjMass = math.max(GUIData.ProjVolume-PlayerData.Data5,0)*7.9/1000 + math.min(PlayerData.Data5,GUIData.ProjVolume)*ACF.HEDensity/2000--Volume of the projectile as a cylinder - Volume of the filler * density of steel + Volume of the filler * density of TNT
	Data.MuzzleVel = ACF_MuzzleVelocity( Data.PropMass, Data.ProjMass, Data.Caliber )
	local Energy = ACF_Kinetic( Data.MuzzleVel*39.37 , Data.ProjMass, Data.LimitVel )
		
	local MaxVol = ACF_RoundShellCapacity( Energy.Momentum, Data.FrAera, Data.Caliber, Data.ProjLength )
	GUIData.MinFillerVol = 0
	GUIData.MaxFillerVol = math.min(GUIData.ProjVolume,MaxVol)
	
	GUIData.MaxSmokeVol = math.max(GUIData.MaxFillerVol-PlayerData.Data6,GUIData.MinFillerVol)
	GUIData.MaxWPVol = math.max(GUIData.MaxFillerVol-PlayerData.Data5,GUIData.MinFillerVol)
	
	local Ratio = math.min( GUIData.MaxFillerVol/(PlayerData.Data5 + PlayerData.Data6), 1 )
	GUIData.FillerVol = math.min(PlayerData.Data5*Ratio,GUIData.MaxSmokeVol)
	GUIData.WPVol = math.min(PlayerData.Data6*Ratio,GUIData.MaxWPVol)
	
	Data.FillerMass = GUIData.FillerVol * ACF.HEDensity/2000
	Data.WPMass = GUIData.WPVol * ACF.HEDensity/2000
	
	Data.ProjMass = math.max(GUIData.ProjVolume-(GUIData.FillerVol+GUIData.WPVol),0)*7.9/1000 + Data.FillerMass + Data.WPMass
	Data.MuzzleVel = ACF_MuzzleVelocity( Data.PropMass, Data.ProjMass, Data.Caliber )
	
	--Random bullshit left
	Data.ShovePower = 0.1
	Data.PenAera = Data.FrAera^ACF.PenAreaMod
	Data.DragCoef = ((Data.FrAera/10000)/Data.ProjMass)
	Data.LimitVel = 100										--Most efficient penetration speed in m/s
	Data.KETransfert = 0.1									--Kinetic energy transfert to the target for movement purposes
	Data.Ricochet = 60										--Base ricochet angle
	Data.DetonatorAngle = 80
	
	if PlayerData.Data7 < 0.5 then
		PlayerData.Data7 = 0
		Data.FuseLength = PlayerData.Data7
	else
		PlayerData.Data7 = math.max(math.Round(PlayerData.Data7,1),0.5)
		Data.FuseLength = PlayerData.Data7
	end
	
	Data.BoomPower = Data.PropMass + Data.FillerMass + Data.WPMass
	
	if SERVER then --Only the crates need this part
		ServerData.Id = PlayerData.Id
		ServerData.Type = PlayerData.Type
		return table.Merge(Data,ServerData)
	end
	
	if CLIENT then --Only tthe GUI needs this part
		GUIData = table.Merge(GUIData, Round.getDisplayData(Data))
		return table.Merge(Data,GUIData)
	end
	
end

function Round.network( Crate, BulletData )

	Crate:SetNWString( "AmmoType", "SM" )
	Crate:SetNWString( "AmmoID", BulletData.Id )
	Crate:SetNWFloat( "Caliber", BulletData.Caliber )
	Crate:SetNWFloat( "ProjMass", BulletData.ProjMass )
	Crate:SetNWFloat( "FillerMass", BulletData.FillerMass )
	Crate:SetNWFloat( "WPMass", BulletData.WPMass )
	Crate:SetNWFloat( "PropMass", BulletData.PropMass )
	Crate:SetNWFloat( "DragCoef", BulletData.DragCoef )
	Crate:SetNWFloat( "MuzzleVel", BulletData.MuzzleVel )
	Crate:SetNWFloat( "Tracer", BulletData.Tracer )

end

function Round.getDisplayData(Data)

	local GUIData = {}
	
	GUIData.SMFiller = math.min(math.log(1+Data.FillerMass*8*39.37)/0.02303,350) --smoke filler
	GUIData.SMLife = math.Round(20+GUIData.SMFiller/4,1)
	GUIData.SMRadiusMin = math.Round(GUIData.SMFiller*1.25*0.15*0.0254,1)
	GUIData.SMRadiusMax = math.Round(GUIData.SMFiller*1.25*2*0.0254,1)
	
	GUIData.WPFiller = math.min(math.log(1+Data.WPMass*8*39.37)/0.02303,350) --wp filler
	GUIData.WPLife = math.Round(6+GUIData.WPFiller/10,1)
	GUIData.WPRadiusMin = math.Round(GUIData.WPFiller*1.25*0.0254,1)
	GUIData.WPRadiusMax = math.Round(GUIData.WPFiller*1.25*2*0.0254,1)
	
	return GUIData
	
end

function Round.cratetxt( BulletData )
	
	local GUIData = Round.getDisplayData(BulletData)
	
	local str = {
		"Muzzle Velocity: ", math.Round(BulletData.MuzzleVel, 1), " m/s"
	}
	
	if GUIData.WPFiller > 0 then
		local temp = {
			"\nWP Radius: ", GUIData.WPRadiusMin, " m to ", GUIData.WPRadiusMax, " m\n",
			"WP Lifetime: ", GUIData.WPLife, " s"
		}
		
		for i=1,#temp do
			str[#str+1] = temp[i]
		end
	end

	if GUIData.SMFiller > 0 then
		local temp = {
			"\nSM Radius: ", GUIData.SMRadiusMin, " m to ", GUIData.SMRadiusMax, " m\n",
			"SM Lifetime: ", GUIData.SMLife, " s"
		}
		
		for i=1,#temp do
			str[#str+1] = temp[i]
		end
	end
	
	if BulletData.FuseLength > 0 then
		local temp = {
			"\nFuse time: ", BulletData.FuseLength, " s"
		}
		
		for i=1,#temp do
			str[#str+1] = temp[i]
		end
	end

	return table.concat(str)
	
end

function Round.propimpact( Index, Bullet, Target, HitNormal, HitPos, Bone )
	
	if ACF_Check( Target ) then
		local Speed = Bullet.Flight:Length() / ACF.VelScale
		local Energy = ACF_Kinetic( Speed , Bullet.ProjMass - (Bullet.FillerMass + Bullet.WPMass), Bullet.LimitVel )
		local HitRes = ACF_RoundImpact( Bullet, Speed, Energy, Target, HitPos, HitNormal , Bone )
		if HitRes.Ricochet then
			return "Ricochet"
		end
	end
	return false
	
end

function Round.worldimpact( Index, Bullet, HitPos, HitNormal )
	
	return false
	
end

function Round.endflight( Index, Bullet, HitPos, HitNormal )
	
	--ACF_HE( HitPos - Bullet.Flight:GetNormalized()*3 , HitNormal, Bullet.FillerMass, Bullet.ProjMass - Bullet.FillerMass, Bullet.Owner )
	ACF_RemoveBullet( Index )
	
end

function Round.endeffect( Effect, Bullet )
	
	local Flash = EffectData()
		Flash:SetOrigin( Bullet.SimPos )
		Flash:SetNormal( Bullet.SimFlight:GetNormalized() )
		Flash:SetRadius( math.max( Bullet.FillerMass*8*39.37, 0 ) ) --(Bullet.FillerMass)^0.33*8*39.37
		Flash:SetMagnitude( math.max( Bullet.WPMass*8*39.37, 0 ) )
		
		local vec = Vector(255,255,255)
		if IsValid(Bullet.Crate) then vec = Bullet.Crate:GetNWVector( "TracerColour", Bullet.Crate:GetColor() ) end
		Flash:SetStart(vec)
	util.Effect( "ACF_Smoke", Flash )

end

function Round.pierceeffect( Effect, Bullet )

	local BulletEffect = {}
		BulletEffect.Num = 1
		BulletEffect.Src = Bullet.SimPos - Bullet.SimFlight:GetNormalized()
		BulletEffect.Dir = Bullet.SimFlight:GetNormalized()
		BulletEffect.Spread = Vector(0,0,0)
		BulletEffect.Tracer = 0
		BulletEffect.Force = 0
		BulletEffect.Damage = 0	 
	LocalPlayer():FireBullets(BulletEffect) 	
	
	util.Decal("ExplosiveGunshot", Bullet.SimPos + Bullet.SimFlight*10, Bullet.SimPos - Bullet.SimFlight*10)
	
	local Spall = EffectData()
		Spall:SetOrigin( Bullet.SimPos )
		Spall:SetNormal( (Bullet.SimFlight):GetNormalized() )
		Spall:SetScale( math.max(((Bullet.RoundMass * (Bullet.SimFlight:Length()/39.37)^2)/2000)/10000,1) )
	util.Effect( "AP_Hit", Spall )

end

function Round.ricocheteffect( Effect, Bullet )

	local Spall = EffectData()
		Spall:SetEntity( Bullet.Gun )
		Spall:SetOrigin( Bullet.SimPos )
		Spall:SetNormal( (Bullet.SimFlight):GetNormalized() )
		Spall:SetScale( Bullet.SimFlight:Length() )
		Spall:SetMagnitude( Bullet.RoundMass )
	util.Effect( "ACF_AP_Ricochet", Spall )

end

function Round.guicreate( Panel, Table )

	acfmenupanel:AmmoSelect( ACF.AmmoBlacklist.SM )
	
	acfmenupanel:CPanelText("BonusDisplay", "")

	acfmenupanel:CPanelText("Desc", "")	--Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "")	--Total round length (Name, Desc)
	
	acfmenupanel:AmmoSlider("PropLength",0,0,1000,3, "Propellant Length", "")	--Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength",0,0,1000,3, "Projectile Length", "")	--Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FillerVol",0,0,1000,3, "Smoke Filler", "")			--Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("WPVol",0,0,1000,3, "WP Filler", "")			--Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FuseLength",0,0,1000,3, "Timed Fuse", "")
	
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer", "")			--Tracer checkbox (Name, Title, Desc)
	
	acfmenupanel:CPanelText("VelocityDisplay", "")	--Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("BlastDisplay", "")	--HE Blast data (Name, Desc)
	acfmenupanel:CPanelText("FragDisplay", "")	--HE Fragmentation data (Name, Desc)
	
	Round.guiupdate( Panel, Table )
	
end

function Round.guiupdate( Panel, Table )

	local PlayerData = {}
		PlayerData.Id = acfmenupanel.AmmoData.Data.id			--AmmoSelect GUI
		PlayerData.Type = "SM"										--Hardcoded, match ACFRoundTypes table index
		PlayerData.PropLength = acfmenupanel.AmmoData.PropLength	--PropLength slider
		PlayerData.ProjLength = acfmenupanel.AmmoData.ProjLength	--ProjLength slider
		PlayerData.Data5 = acfmenupanel.AmmoData.FillerVol
		PlayerData.Data6 = acfmenupanel.AmmoData.WPVol
		PlayerData.Data7 = acfmenupanel.AmmoData.FuseLength
		local Tracer = 0
		if acfmenupanel.AmmoData.Tracer then Tracer = 1 end
		PlayerData.Data10 = Tracer				--Tracer
	
	local Data = Round.convert( Panel, PlayerData )
	
	RunConsoleCommand( "acfmenu_data1", acfmenupanel.AmmoData.Data.id )
	RunConsoleCommand( "acfmenu_data2", PlayerData.Type )
	RunConsoleCommand( "acfmenu_data3", Data.PropLength )		--For Gun ammo, Data3 should always be Propellant
	RunConsoleCommand( "acfmenu_data4", Data.ProjLength )		--And Data4 total round mass
	RunConsoleCommand( "acfmenu_data5", Data.FillerVol )
	RunConsoleCommand( "acfmenu_data6", Data.WPVol )
	RunConsoleCommand( "acfmenu_data7", Data.FuseLength )
	RunConsoleCommand( "acfmenu_data10", Data.Tracer )
	
	local vol = ACF.Weapons.Ammo[acfmenupanel.AmmoData["Id"]].volume
	local Cap, CapMul, RoFMul = ACF_CalcCrateStats( vol, Data.RoundVolume )
	
	acfmenupanel:CPanelText("BonusDisplay", "Crate info: +"..(math.Round((CapMul-1)*100,1)).."% capacity, +"..(math.Round((RoFMul-1)*-100,1)).."% RoF\nContains "..Cap.." rounds")
	
	acfmenupanel:AmmoSlider("PropLength",Data.PropLength,Data.MinPropLength,Data.MaxTotalLength,3, "Propellant Length", "Propellant Mass : "..(math.floor(Data.PropMass*1000)).." g" )	--Propellant Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength",Data.ProjLength,Data.MinProjLength,Data.MaxTotalLength,3, "Projectile Length", "Projectile Mass : "..(math.floor(Data.ProjMass*1000)).." g")	--Projectile Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FillerVol",Data.FillerVol,Data.MinFillerVol,Data.MaxFillerVol,3, "Smoke Filler Volume", "Smoke Filler Mass : "..(math.floor(Data.FillerMass*1000)).." g")	--HE Filler Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("WPVol",Data.WPVol,Data.MinFillerVol,Data.MaxFillerVol,3, "WP Filler Volume", "WP Filler Mass : "..(math.floor(Data.WPMass*1000)).." g")	--HE Filler Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FuseLength",Data.FuseLength,0,10,1, "Fuse Time", (Data.FuseLength).." s")
	
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer : "..(math.floor(Data.Tracer*10)/10).."cm\n", "" )			--Tracer checkbox (Name, Title, Desc)

	acfmenupanel:CPanelText("Desc", ACF.RoundTypes[PlayerData.Type].desc)	--Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "Round Length : "..(math.floor((Data.PropLength+Data.ProjLength+Data.Tracer)*100)/100).."/"..(Data.MaxTotalLength).." cm")	--Total round length (Name, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "Muzzle Velocity : "..math.floor(Data.MuzzleVel*ACF.VelScale).." m/s")	--Proj muzzle velocity (Name, Desc)	
	---acfmenupanel:CPanelText("BlastDisplay", "Blast Radius : "..(math.floor(Data.BlastRadius*100)/1000).." m\n")	--Proj muzzle velocity (Name, Desc)
	---acfmenupanel:CPanelText("FragDisplay", "Fragments : "..(Data.Fragments).."\n Average Fragment Weight : "..(math.floor(Data.FragMass*10000)/10).." ---g \n Average Fragment Velocity : "..math.floor(Data.FragVel).." m/s")	--Proj muzzle penetration (Name, Desc)
	
end

list.Set( "ACFRoundTypes", "SM", Round )  --Set the round properties
list.Set( "ACFIdRounds", Round.netid, "SM" ) --Index must equal the ID entry in the table above, Data must equal the index of the table above
