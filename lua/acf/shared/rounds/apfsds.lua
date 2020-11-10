ACF.AmmoBlacklist.APFSDS = { "MO", "SL", "C", "HW", "AC", "SC", "SA", "MG", "AL", "RAC", "GL", "HMG", "AAM", "ARTY", "ASM", "BOMB", "GBU", "POD", "SAM", "UAR", "FFAR", "FGL" }

local Round = {}

Round.type = "Ammo" --Tells the spawn menu what entity to spawn
Round.name = "AP Fin Stabilized, Discarding Sabot (APFSDS)" --Human readable name
Round.model = "models/munitions/dart_100mm.mdl" --Shell flight model
Round.desc = "A fin stabilized sabot munition designed to trade damage for superior penetration and long range effectiveness."

function Round.create(_, BulletData)
	ACF_CreateBullet(BulletData)
end

-- Function to convert the player's slider data into the complete round data
function Round.convert(_, PlayerData)
	local Data = {}
	local ServerData = {}
	local GUIData = {}

	if not PlayerData.PropLength then
		PlayerData.PropLength = 0
	end

	if not PlayerData.ProjLength then
		PlayerData.ProjLength = 0
	end

	if not PlayerData.Data10 then
		PlayerData.Data10 = 0
	end

	PlayerData, Data, ServerData, GUIData = ACF_RoundBaseGunpowder(PlayerData, Data, ServerData, GUIData)

	local SubCaliberRatio = 0.29 -- Ratio of projectile to gun caliber
	local Area = 3.1416 * (Data.Caliber * 0.5 * SubCaliberRatio) ^ 2

	local DartMass  = (Area / 1.5) * (Data.ProjLength * 7.9 / 1000) -- Volume of the projectile as a cylinder * density of steel

	local Cylinder  = (3.1416 * (Data.Caliber * 0.5) ^ 2) * Data.ProjLength * 0.25 -- A cylinder 1/4 the length of the projectile
	local Hole		= Area * Data.ProjLength * 0.25 -- Volume removed by the hole the dart passes through
	local SabotMass = (Cylinder - Hole) * 2.7 * 0.25 * 0.001 -- A cylinder with a hole the size of the dart in it and im no math wizard so we're just going to take off 3/4 of the mass for the cutout since sabots are shaped like this: ][

	Data.ProjMass 	 = DartMass
	Data.ShovePower  = 0.2
	Data.PenArea 	 = Area ^ ACF.PenAreaMod
	Data.DragCoef 	 = (Area / 10000) / Data.ProjMass
	Data.LimitVel 	 = 1000 --Most efficient penetration speed in m/s
	Data.KETransfert = 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet 	 = 80 --Base ricochet angle
	Data.MuzzleVel 	 = ACF_MuzzleVelocity(Data.PropMass, DartMass + SabotMass)
	Data.CartMass 	 = Data.PropMass + DartMass + SabotMass

	--Only the crates need this part
	if SERVER then
		ServerData.Id = PlayerData.Id
		ServerData.Type = PlayerData.Type
		return table.Merge(Data, ServerData)
	end

	--Only the GUI needs this part
	if CLIENT then
		GUIData = table.Merge(GUIData, Round.getDisplayData(Data))
		return table.Merge(Data, GUIData)
	end
end

function Round.getDisplayData(Data)
	local GUIData = {}
	local Energy = ACF_Kinetic(Data.MuzzleVel * 39.37, Data.ProjMass, Data.LimitVel)
	GUIData.MaxPen = (Energy.Penetration / Data.PenArea) * ACF.KEtoRHA
	return GUIData
end

function Round.network(Crate, BulletData)
	Crate:SetNWString("AmmoType", "APFSDS")
	Crate:SetNWString("AmmoID", BulletData.Id)
	Crate:SetNWFloat("Caliber", BulletData.Caliber)
	Crate:SetNWFloat("ProjMass", BulletData.ProjMass)
	Crate:SetNWFloat("PropMass", BulletData.PropMass)
	Crate:SetNWFloat("DragCoef", BulletData.DragCoef)
	Crate:SetNWFloat("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNWFloat("Tracer", BulletData.Tracer)
end

function Round.cratetxt(BulletData)
	local DData = Round.getDisplayData(BulletData)

	local str =
	{
		"Muzzle Velocity: ", math.Round(BulletData.MuzzleVel, 1), " m/s\n",
		"Max Penetration: ", math.floor(DData.MaxPen), " mm"
	}

	return table.concat(str)
end

function Round.propimpact(_, Bullet, Target, HitNormal, HitPos, Bone)
	if ACF_Check(Target) then
		local Speed = Bullet.Flight:Length() / ACF.Scale
		local Energy = ACF_Kinetic(Speed, Bullet.ProjMass, Bullet.LimitVel)
		local HitRes = ACF_RoundImpact(Bullet, Speed, Energy, Target, HitPos, HitNormal, Bone)

		if HitRes.Overkill > 0 then
			table.insert(Bullet.Filter, Target) --"Penetrate" (Ingoring the prop for the retry trace)
			Bullet.Flight = Bullet.Flight:GetNormalized() * (Energy.Kinetic * (1 - HitRes.Loss) * 2000 / Bullet.ProjMass) ^ 0.5 * 39.37
			return "Penetrated"
		elseif HitRes.Ricochet then
			return "Ricochet"
		else
			return false
		end
	end

	table.insert(Bullet.Filter, Target)

	return "Penetrated"
end

function Round.worldimpact(_, Bullet, HitPos, HitNormal)
	local Energy = ACF_Kinetic(Bullet.Flight:Length() / ACF.Scale, Bullet.ProjMass, Bullet.LimitVel)
	local HitRes = ACF_PenetrateGround(Bullet, Energy, HitPos, HitNormal)

	if HitRes.Penetrated then
		return "Penetrated"
	elseif HitRes.Ricochet then
		return "Ricochet"
	else
		return false
	end
end

function Round.endflight(Index)
	ACF_RemoveBullet(Index)
end

local DecalIndex = ACF.GetAmmoDecalIndex

function Round.endeffect(_, Bullet)
	local Effect = EffectData()
	Effect:SetOrigin(Bullet.SimPos)
	Effect:SetNormal(Bullet.SimFlight:GetNormalized())
	Effect:SetRadius(Bullet.Caliber)
	Effect:SetDamageType(DecalIndex(Bullet.AmmoType))

	util.Effect("ACF_Impact", Effect)
end

function Round.pierceeffect(_, Bullet)
	local Effect = EffectData()
	Effect:SetOrigin(Bullet.SimPos)
	Effect:SetNormal(Bullet.SimFlight:GetNormalized())
	Effect:SetScale(Bullet.SimFlight:Length())
	Effect:SetMagnitude(Bullet.RoundMass)
	Effect:SetRadius(Bullet.Caliber)
	Effect:SetDamageType(DecalIndex(Bullet.AmmoType))

	util.Effect("ACF_Penetration", Effect)
end

function Round.ricocheteffect(_, Bullet)
	local Effect = EffectData()
	Effect:SetOrigin(Bullet.SimPos)
	Effect:SetNormal(Bullet.SimFlight:GetNormalized())
	Effect:SetScale(Bullet.SimFlight:Length())
	Effect:SetMagnitude(Bullet.RoundMass)
	Effect:SetRadius(Bullet.Caliber)
	Effect:SetDamageType(DecalIndex(Bullet.AmmoType))

	util.Effect("ACF_Ricochet", Effect)
end

function Round.guicreate(Panel, Table)
	acfmenupanel:AmmoSelect(ACF.AmmoBlacklist.APFSDS)

	acfmenupanel:CPanelText("Desc", "") --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "") --Total round length (Name, Desc)
	acfmenupanel:AmmoSlider("PropLength", 0, 0, 1000, 3, "Propellant Length", "") --Propellant Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", 0, 0, 1000, 3, "Penetrator Length", "") --Projectile Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "") --Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("PenetrationDisplay", "") --Proj muzzle penetration (Name, Desc)

	Round.guiupdate(Panel, Table)
end

function Round.guiupdate(Panel)
	local PlayerData = {}
	PlayerData.Id = acfmenupanel.AmmoData.Data.id --AmmoSelect GUI
	PlayerData.Type = "APFSDS" --Hardcoded, match ACFRoundTypes table index
	PlayerData.PropLength = acfmenupanel.AmmoData.PropLength --PropLength slider
	PlayerData.ProjLength = acfmenupanel.AmmoData.ProjLength --ProjLength slider
	local Tracer = 0

	if acfmenupanel.AmmoData.Tracer then
		Tracer = 1
	end

	PlayerData.Data10 = Tracer --Tracer

	local Data = Round.convert(Panel, PlayerData)
	RunConsoleCommand("acfmenu_data1", acfmenupanel.AmmoData.Data.id)
	RunConsoleCommand("acfmenu_data2", PlayerData.Type)
	RunConsoleCommand("acfmenu_data3", Data.PropLength) --For Gun ammo, Data3 should always be Propellant
	RunConsoleCommand("acfmenu_data4", Data.ProjLength) --And Data4 total round mass
	RunConsoleCommand("acfmenu_data10", Data.Tracer)

	acfmenupanel:AmmoUpdate()
	acfmenupanel:AmmoSlider("PropLength", Data.PropLength, Data.MinPropLength, Data.MaxTotalLength, 3, "Propellant Length", "Propellant Mass : " .. (math.floor(Data.PropMass * 1000)) .. " g") --Propellant Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", Data.ProjLength, Data.MinProjLength, Data.MaxTotalLength, 3, "Penetrator Length", "Projectile Mass : " .. (math.floor(Data.ProjMass * 1000)) .. " g") --Projectile Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer : " .. (math.floor(Data.Tracer * 10) / 10) .. "cm\n", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("Desc", ACF.RoundTypes[PlayerData.Type].desc) --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "Cartridge Length : " .. (math.floor((Data.PropLength + Data.ProjLength + Data.Tracer) * 100) / 100) .. "/" .. Data.MaxTotalLength .. " cm") --Total round length (Name, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "Muzzle Velocity : " .. math.floor(Data.MuzzleVel * ACF.Scale) .. " m\\s") --Proj muzzle velocity (Name, Desc)

	local R1V, R1P = ACF_PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 300)
	local R2V, R2P = ACF_PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 800)

	acfmenupanel:CPanelText("PenetrationDisplay", "Maximum Penetration : " .. math.floor(Data.MaxPen) .. " mm RHA\n\n300m pen: " .. math.Round(R1P,0) .. "mm @ " .. math.Round(R1V,0) .. " m\\s\n800m pen: " .. math.Round(R2P,0) .. "mm @ " .. math.Round(R2V,0) .. " m\\s\n\nThe range data is an approximation and may not be entirely accurate.") --Proj muzzle penetration (Name, Desc)
end

ACF.RoundTypes.APFSDS = Round -- DELETE

ACF.RegisterAmmoDecal("APFSDS", "damage/apcr_pen", "damage/apcr_rico")
