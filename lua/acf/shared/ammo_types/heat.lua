local Ammo = ACF.RegisterAmmoType("HEAT", "AP")
local DecalIndex = ACF.GetAmmoDecalIndex

function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name = "High Explosive Anti-Tank"
	self.Description = "A shell with a shaped charge. When the round detonates, the explosive energy is focused into driving a small molten metal penetrator into the victim with extreme force, though this results in reduced damage from the explosion itself. Multiple layers of armor will dissipate the penetrator quickly."
	self.Blacklist = {
		MG = true,
		HMG = true,
		RAC = true,
		AC = true,
		SL = true,
		SB = true,
	}
end

function Ammo.ConeCalc(ConeAngle, Radius)
	local ConeLength = math.tan(math.rad(ConeAngle)) * Radius
	local ConeArea = 3.1416 * Radius * (Radius ^ 2 + ConeLength ^ 2) ^ 0.5
	local ConeVol = (3.1416 * Radius ^ 2 * ConeLength) / 3

	return ConeLength, ConeArea, ConeVol
end

-- calculates conversion of filler from powering HEAT jet to raw HE based on crush vel
-- above a threshold vel, HEAT jet doesn't have time to form properly, converting to raw HE proportionally
-- Vel needs to be in m/s (gmu*0.0254)
function Ammo.CrushCalc(Vel, FillerMass)
	local Crushed = math.Clamp((Vel - ACF.HEATMinCrush) / (ACF.HEATMaxCrush - ACF.HEATMinCrush), 0, 1)
	local HE_Filler = Lerp(Crushed, FillerMass * ACF.HEATBoomConvert, FillerMass)
	local HEAT_Filler = Lerp(Crushed, FillerMass, 0)

	return Crushed, HEAT_Filler, HE_Filler
end

-- coneang now required for slug recalculation at detonation, defaults to 55 if not present
function Ammo.CalcSlugMV(Data, HEATFillerMass)
	--keep fillermass/2 so that penetrator stays the same.
	return (HEATFillerMass / 2 * ACF.HEPower * math.sin(math.rad(10 + (Data.ConeAng or 55)) / 2) / Data.SlugMass) ^ ACF.HEATMVScale
end

function Ammo.Convert(_, PlayerData)
	local Data = {}
	local ServerData = {}
	local GUIData = {}

	if not PlayerData.PropLength then
		PlayerData.PropLength = 0
	end

	if not PlayerData.ProjLength then
		PlayerData.ProjLength = 0
	end

	PlayerData.Data5 = math.max(PlayerData.Data5 or 0, 0)

	if not PlayerData.Data6 then
		PlayerData.Data6 = 0
	end

	if not PlayerData.Data7 then
		PlayerData.Data7 = 0
	end

	if not PlayerData.Data10 then
		PlayerData.Data10 = 0
	end

	PlayerData, Data, ServerData, GUIData = ACF_RoundBaseGunpowder(PlayerData, Data, ServerData, GUIData)

	local _, ConeArea, AirVol = Ammo.ConeCalc(PlayerData.Data6, Data.Caliber / 2, PlayerData.ProjLength)
	local ConeThick = Data.Caliber / 50

	Data.ProjMass = math.max(GUIData.ProjVolume - PlayerData.Data5, 0) * 7.9 / 1000 + math.min(PlayerData.Data5, GUIData.ProjVolume) * ACF.HEDensity / 1000 + ConeArea * ConeThick * 7.9 / 1000 --Volume of the projectile as a cylinder - Volume of the filler - Volume of the crush cone * density of steel + Volume of the filler * density of TNT + Area of the cone * thickness * density of steel
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)

	local Energy = ACF_Kinetic(Data.MuzzleVel * 39.37, Data.ProjMass, Data.LimitVel)
	local MaxVol = ACF_RoundShellCapacity(Energy.Momentum, Data.FrArea, Data.Caliber, Data.ProjLength)

	GUIData.MinConeAng = 0
	GUIData.MaxConeAng = math.deg(math.atan((Data.ProjLength - ConeThick) / (Data.Caliber * 0.5)))

	Data.ConeAng = math.Clamp(PlayerData.Data6 * 1, GUIData.MinConeAng, GUIData.MaxConeAng)

	_, ConeArea, AirVol = Ammo.ConeCalc(Data.ConeAng, Data.Caliber / 2, Data.ProjLength)

	local ConeVol = ConeArea * ConeThick

	GUIData.MinFillerVol = 0
	GUIData.MaxFillerVol = math.max(MaxVol - AirVol - ConeVol, GUIData.MinFillerVol)
	GUIData.FillerVol = math.Clamp(PlayerData.Data5 * 1, GUIData.MinFillerVol, GUIData.MaxFillerVol)

	-- fillermass used for shell mass calcs
	-- heatfillermass is how much fillermass is used to power heat jet
	-- boomfillermass is how much fillermass creates HE damage on detonation. technically get 1/3 extra fillermass free as HE with no crushing, but screw trying to rebalance heat pen to properly use 1/3 of filler for HE and 2/3 for jet
	-- distribution of heat and boom fillermass is calculated at detonation, or for GUI stuff
	Data.FillerMass = GUIData.FillerVol * ACF.HEDensity / 1450
	Data.ProjMass = math.max(GUIData.ProjVolume - GUIData.FillerVol - AirVol - ConeVol, 0) * 7.9 / 1000 + Data.FillerMass + ConeVol * 7.9 / 1000
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)

	--Let's calculate the actual HEAT slug
	local Rad = math.rad(Data.ConeAng / 2)

	Data.SlugMass = ConeVol * 7.9 / 1000
	Data.SlugCaliber = Data.Caliber - Data.Caliber * (math.sin(Rad) * 0.5 + math.cos(Rad) * 1.5) * 0.5

	local SlugFrArea = 3.1416 * (Data.SlugCaliber * 0.5) ^ 2

	Data.SlugPenArea = SlugFrArea ^ ACF.PenAreaMod
	Data.SlugDragCoef = ((SlugFrArea / 10000) / Data.SlugMass)
	Data.SlugRicochet = 500 --Base ricochet angle (The HEAT slug shouldn't ricochet at all)

	-- these are only for compatibility with other stuff. it's recalculated when the round is detonated
	local _, HEATFiller, BoomFiller = Ammo.CrushCalc(Data.MuzzleVel, Data.FillerMass)

	Data.BoomFillerMass = BoomFiller
	Data.SlugMV = Ammo.CalcSlugMV(Data, HEATFiller)
	Data.CasingMass = Data.ProjMass - Data.FillerMass - ConeVol * 7.9 / 1000
	Data.ShovePower = 0.1
	Data.PenArea = Data.FrArea ^ ACF.PenAreaMod
	Data.DragCoef = ((Data.FrArea / 10000) / Data.ProjMass)
	Data.LimitVel = 100 --Most efficient penetration speed in m/s
	Data.KETransfert = 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet = 60 --Base ricochet angle
	Data.DetonatorAngle = 75
	Data.Detonated = false
	Data.NotFirstPen = false
	Data.CanFuze = Data.Caliber > 2 -- Can fuze on calibers > 20mm

	--Only the crates need this part
	if SERVER then
		ServerData.Id = PlayerData.Id
		ServerData.Type = PlayerData.Type

		return table.Merge(Data, ServerData)
	end

	--Only the GUI needs this part	
	if CLIENT then
		GUIData = table.Merge(GUIData, Ammo.GetDisplayData(Data))

		return table.Merge(Data, GUIData)
	end
end

function Ammo.Network(Crate, BulletData)
	Crate:SetNWString("AmmoType", "HEAT")
	Crate:SetNWString("AmmoID", BulletData.Id)
	Crate:SetNWFloat("Caliber", BulletData.Caliber)
	Crate:SetNWFloat("ProjMass", BulletData.ProjMass)
	Crate:SetNWFloat("FillerMass", BulletData.FillerMass)
	Crate:SetNWFloat("PropMass", BulletData.PropMass)
	Crate:SetNWFloat("DragCoef", BulletData.DragCoef)
	Crate:SetNWFloat("SlugMass", BulletData.SlugMass)
	Crate:SetNWFloat("SlugCaliber", BulletData.SlugCaliber)
	Crate:SetNWFloat("SlugDragCoef", BulletData.SlugDragCoef)
	Crate:SetNWFloat("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNWFloat("Tracer", BulletData.Tracer)
end

function Ammo.GetDisplayData(Data)
	local Crushed, HEATFiller, BoomFiller = Ammo.CrushCalc(Data.MuzzleVel, Data.FillerMass)
	local SlugMV = Ammo.CalcSlugMV(Data, HEATFiller) * (Data.SlugPenMul or 1)
	local MassUsed = Data.SlugMass * (1 - Crushed)
	local Energy = ACF_Kinetic(Data.MuzzleVel * 39.37 + SlugMV * 39.37, MassUsed, 999999)
	local FragMass = Data.CasingMass + Data.SlugMass * Crushed
	local Fragments = math.max(math.floor((BoomFiller / FragMass) * ACF.HEFrag), 2)

	return {
		Crushed = Crushed,
		HEATFillerMass = HEATFiller,
		BoomFillerMass = BoomFiller,
		SlugMV = SlugMV,
		SlugMassUsed = MassUsed,
		MaxPen = (Energy.Penetration / Data.SlugPenArea) * ACF.KEtoRHA,
		TotalFragMass = FragMass,
		BlastRadius = BoomFiller ^ 0.33 * 8,
		Fragments = Fragments,
		FragMass = FragMass / Fragments,
		FragVel = (BoomFiller * ACF.HEPower * 1000 / FragMass) ^ 0.5,
	}
end

function Ammo.GetCrateText(BulletData)
	local Text = "Muzzle Velocity: %s m/s\nMax Penetration: %s mm\nBlast Radius: %s m\n", "Blast Energy: %s KJ"
	local Data = Ammo.GetDisplayData(BulletData)

	return Text:format(math.Round(BulletData.MuzzleVel, 2), math.floor(Data.MaxPen), math.Round(Data.BlastRadius, 2), math.floor(Data.BoomFillerMass * ACF.HEPower))
end

function Ammo.Detonate(_, Bullet, HitPos)
	local Crushed, HEATFillerMass, BoomFillerMass = Ammo.CrushCalc(Bullet.Flight:Length() * 0.0254, Bullet.FillerMass)

	ACF_HE(HitPos - Bullet.Flight:GetNormalized() * 3, BoomFillerMass, Bullet.CasingMass + Bullet.SlugMass * Crushed, Bullet.Owner, nil, Bullet.Gun)

	if Crushed == 1 then return false end -- no HEAT jet to fire off, it was all converted to HE

	Bullet.Detonated = true
	Bullet.InitTime = ACF.CurTime
	Bullet.Flight = Bullet.Flight + Bullet.Flight:GetNormalized() * Ammo.CalcSlugMV(Bullet, HEATFillerMass) * 39.37
	Bullet.FuseLength = 0.005 + 40 / (Bullet.Flight:Length() * 0.0254)
	Bullet.Pos = HitPos
	Bullet.DragCoef = Bullet.SlugDragCoef
	Bullet.ProjMass = Bullet.SlugMass * (1 - Crushed)
	Bullet.Caliber = Bullet.SlugCaliber
	Bullet.PenArea = Bullet.SlugPenArea
	Bullet.Ricochet = Bullet.SlugRicochet

	local DeltaTime = ACF.CurTime - Bullet.LastThink

	Bullet.StartTrace = Bullet.Pos - Bullet.Flight:GetNormalized() * math.min(ACF.PhysMaxVel * DeltaTime, Bullet.FlightTime * Bullet.Flight:Length())
	Bullet.NextPos = Bullet.Pos + (Bullet.Flight * ACF.Scale * DeltaTime) --Calculates the next shell position

	return true
end

function Ammo.PropImpact(Index, Bullet, Target, HitNormal, HitPos, Bone)
	if ACF_Check(Target) then
		if Bullet.Detonated then
			Bullet.NotFirstPen = true

			local Speed = Bullet.Flight:Length() / ACF.Scale
			local Energy = ACF_Kinetic(Speed, Bullet.ProjMass, 999999)
			local HitRes = ACF_RoundImpact(Bullet, Speed, Energy, Target, HitPos, HitNormal, Bone)

			if HitRes.Overkill > 0 then
				table.insert(Bullet.Filter, Target) --"Penetrate" (Ingoring the prop for the retry trace)

				Bullet.Flight = Bullet.Flight:GetNormalized() * math.sqrt(Energy.Kinetic * (1 - HitRes.Loss) * ((Bullet.NotFirstPen and ACF.HEATPenLayerMul) or 1) * 2000 / Bullet.ProjMass) * 39.37

				return "Penetrated"
			else
				return false
			end
		else
			local Speed = Bullet.Flight:Length() / ACF.Scale
			local Energy = ACF_Kinetic(Speed, Bullet.ProjMass - Bullet.FillerMass, Bullet.LimitVel)
			local HitRes = ACF_RoundImpact(Bullet, Speed, Energy, Target, HitPos, HitNormal, Bone)

			if HitRes.Ricochet then
				return "Ricochet"
			else
				if Ammo.Detonate(Index, Bullet, HitPos, HitNormal) then
					return "Penetrated"
				else
					return false
				end
			end
		end
	else
		table.insert(Bullet.Filter, Target)

		return "Penetrated"
	end

	return false
end

function Ammo.WorldImpact(Index, Bullet, HitPos, HitNormal)
	if not Bullet.Detonated then
		if Ammo.Detonate(Index, Bullet, HitPos, HitNormal) then
			return "Penetrated"
		else
			return false
		end
	end

	local Energy = ACF_Kinetic(Bullet.Flight:Length() / ACF.Scale, Bullet.ProjMass, 999999)
	local HitRes = ACF_PenetrateGround(Bullet, Energy, HitPos, HitNormal)

	if HitRes.Penetrated then
		return "Penetrated"
	else
		return false
	end
end

function Ammo.PenetrationEffect(Effect, Bullet)
	if Bullet.Detonated then
		local Data = EffectData()
		Data:SetOrigin(Bullet.SimPos)
		Data:SetNormal(Bullet.SimFlight:GetNormalized())
		Data:SetScale(Bullet.SimFlight:Length())
		Data:SetMagnitude(Bullet.RoundMass)
		Data:SetRadius(Bullet.Caliber)
		Data:SetDamageType(DecalIndex(Bullet.AmmoType))

		util.Effect("ACF_Penetration", Data)
	else
		local _, _, BoomFillerMass = Ammo.CrushCalc(Bullet.SimFlight:Length() * 0.0254, Bullet.FillerMass)
		local Data = EffectData()
		Data:SetOrigin(Bullet.SimPos)
		Data:SetNormal(Bullet.SimFlight:GetNormalized())
		Data:SetRadius(math.max(BoomFillerMass ^ 0.33 * 8 * 39.37, 1))

		util.Effect("ACF_HEAT_Explosion", Data)

		Bullet.Detonated = true

		Effect:SetModel("models/Gibs/wood_gib01e.mdl")
	end
end

function Ammo.RicochetEffect(_, Bullet)
	local Detonated = Bullet.Detonated
	local Effect = EffectData()
	Effect:SetOrigin(Bullet.SimPos)
	Effect:SetNormal(Bullet.SimFlight:GetNormalized())
	Effect:SetScale(Bullet.SimFlight:Length())
	Effect:SetMagnitude(Bullet.RoundMass)
	Effect:SetRadius(Bullet.Caliber)
	Effect:SetDamageType(DecalIndex(Detonated and Bullet.AmmoType or "AP"))

	util.Effect("ACF_Ricochet", Effect)
end

function Ammo.CreateMenu(Panel, Table)
	acfmenupanel:AmmoSelect(Ammo.Blacklist)

	acfmenupanel:CPanelText("Desc", "") --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "") --Total round length (Name, Desc)
	acfmenupanel:AmmoSlider("PropLength", 0, 0, 1000, 3, "Propellant Length", "")
	acfmenupanel:AmmoSlider("ProjLength", 0, 0, 1000, 3, "Projectile Length", "")
	acfmenupanel:AmmoSlider("ConeAng", 0, 0, 1000, 3, "HEAT Cone Angle", "")
	acfmenupanel:AmmoSlider("FillerVol", 0, 0, 1000, 3, "Total HEAT Warhead volume", "")
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "") --Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("BlastDisplay", "") --HE Blast data (Name, Desc)
	acfmenupanel:CPanelText("FragDisplay", "") --HE Fragmentation data (Name, Desc)
	acfmenupanel:CPanelText("SlugDisplay", "") --HEAT Slug data (Name, Desc)

	Ammo.UpdateMenu(Panel, Table)
end

function Ammo.UpdateMenu(Panel)
	local PlayerData = {
		Id = acfmenupanel.AmmoData.Data.id, --AmmoSelect GUI
		Type = "HEAT", --Hardcoded, match ACFRoundTypes table index
		PropLength = acfmenupanel.AmmoData.PropLength, --PropLength slider
		ProjLength = acfmenupanel.AmmoData.ProjLength, --ProjLength slider
		Data5 = acfmenupanel.AmmoData.FillerVol,
		Data6 = acfmenupanel.AmmoData.ConeAng,
		Data10 = acfmenupanel.AmmoData.Tracer and 1 or 0,
	}

	local Data = Ammo.Convert(Panel, PlayerData)

	RunConsoleCommand("acfmenu_data1", acfmenupanel.AmmoData.Data.id)
	RunConsoleCommand("acfmenu_data2", PlayerData.Type)
	RunConsoleCommand("acfmenu_data3", Data.PropLength) --For Gun ammo, Data3 should always be Propellant
	RunConsoleCommand("acfmenu_data4", Data.ProjLength)
	RunConsoleCommand("acfmenu_data5", Data.FillerVol)
	RunConsoleCommand("acfmenu_data6", Data.ConeAng)
	RunConsoleCommand("acfmenu_data10", Data.Tracer)

	acfmenupanel:AmmoSlider("PropLength", Data.PropLength, Data.MinPropLength, Data.MaxTotalLength, 3, "Propellant Length", "Propellant Mass : " .. (math.floor(Data.PropMass * 1000)) .. " g") --Propellant Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", Data.ProjLength, Data.MinProjLength, Data.MaxTotalLength, 3, "Projectile Length", "Projectile Mass : " .. (math.floor(Data.ProjMass * 1000)) .. " g") --Projectile Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ConeAng", Data.ConeAng, Data.MinConeAng, Data.MaxConeAng, 0, "Crush Cone Angle", "") --HE Filler Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FillerVol", Data.FillerVol, Data.MinFillerVol, Data.MaxFillerVol, 3, "HE Filler Volume", "HE Filler Mass : " .. (math.floor(Data.FillerMass * 1000)) .. " g") --HE Filler Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer : " .. (math.floor(Data.Tracer * 10) / 10) .. "cm\n", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("Desc", Ammo.Description) --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "Round Length : " .. (math.floor((Data.PropLength + Data.ProjLength + Data.Tracer) * 100) / 100) .. "/" .. Data.MaxTotalLength .. " cm") --Total round length (Name, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "Muzzle Velocity : " .. math.floor(Data.MuzzleVel * ACF.Scale) .. " m/s") --Proj muzzle velocity (Name, Desc)	
	acfmenupanel:CPanelText("BlastDisplay", "Blast Radius : " .. (math.floor(Data.BlastRadius * 100) / 100) .. " m") --Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("FragDisplay", "Fragments : " .. Data.Fragments .. "\n Average Fragment Weight : " .. (math.floor(Data.FragMass * 10000) / 10) .. " g \n Average Fragment Velocity : " .. math.floor(Data.FragVel) .. " m/s") --Proj muzzle penetration (Name, Desc)

	local R1V, R1P = ACF_PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 300)
	R1P = (ACF_Kinetic((R1V + Data.SlugMV) * 39.37, Data.SlugMassUsed, 999999).Penetration / Data.SlugPenArea) * ACF.KEtoRHA
	local R2V, R2P = ACF_PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 800)
	R2P = (ACF_Kinetic((R2V + Data.SlugMV) * 39.37, Data.SlugMassUsed, 999999).Penetration / Data.SlugPenArea) * ACF.KEtoRHA

	acfmenupanel:CPanelText("SlugDisplay", "Penetrator Mass : " .. (math.floor(Data.SlugMassUsed * 10000) / 10) .. " g \n Penetrator Caliber : " .. (math.floor(Data.SlugCaliber * 100) / 10) .. " mm \n Penetrator Velocity : " .. math.floor(Data.MuzzleVel + Data.SlugMV) .. " m/s \n Penetrator Maximum Penetration : " .. math.floor(Data.MaxPen) .. " mm RHA\n\n300m pen: " .. math.Round(R1P, 0) .. "mm @ " .. math.Round(R1V, 0) .. " m\\s\n800m pen: " .. math.Round(R2P, 0) .. "mm @ " .. math.Round(R2V, 0) .. " m\\s\n\nThe range data is an approximation and may not be entirely accurate.") --Proj muzzle penetration (Name, Desc)
end

function Ammo.MenuAction(Menu)
	Menu:AddParagraph("Testing HEAT menu.")
end

ACF.RegisterAmmoDecal("HEAT", "damage/heat_pen", "damage/heat_rico", function(Caliber) return Caliber * 0.1667 end)
