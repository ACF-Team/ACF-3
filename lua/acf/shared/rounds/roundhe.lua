ACF.AmmoBlacklist.HE = {"MG", "RAC", "SL"}
local Round = {}
Round.type = "Ammo" --Tells the spawn menu what entity to spawn
Round.name = "High Explosive (HE)" --Human readable name
Round.model = "models/munitions/round_100mm_shot.mdl" --Shell flight model
Round.desc = "A shell filled with explosives, detonating on impact"
Round.netid = 2 --Unique ammotype ID for network transmission

function Round.create(Gun, BulletData)
	ACF_CreateBullet(BulletData)
end

-- Function to convert the player's slider data into the complete round data
function Round.convert(Crate, PlayerData)
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

	if not PlayerData.Data10 then
		PlayerData.Data10 = 0
	end

	PlayerData, Data, ServerData, GUIData = ACF_RoundBaseGunpowder(PlayerData, Data, ServerData, GUIData)
	--Shell sturdiness calcs
	Data.ProjMass = math.max(GUIData.ProjVolume - PlayerData.Data5, 0) * 7.9 / 1000 + math.min(PlayerData.Data5, GUIData.ProjVolume) * ACF.HEDensity / 1000 --Volume of the projectile as a cylinder - Volume of the filler * density of steel + Volume of the filler * density of TNT
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)
	local Energy = ACF_Kinetic(Data.MuzzleVel * 39.37, Data.ProjMass, Data.LimitVel)
	local MaxVol = ACF_RoundShellCapacity(Energy.Momentum, Data.FrArea, Data.Caliber, Data.ProjLength)
	GUIData.MinFillerVol = 0
	GUIData.MaxFillerVol = math.min(GUIData.ProjVolume, MaxVol)
	GUIData.FillerVol = math.min(PlayerData.Data5, GUIData.MaxFillerVol)
	Data.FillerMass = GUIData.FillerVol * ACF.HEDensity / 1000
	Data.ProjMass = math.max(GUIData.ProjVolume - GUIData.FillerVol, 0) * 7.9 / 1000 + Data.FillerMass
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)
	--Random bullshit left
	Data.ShovePower = 0.1
	Data.PenArea = Data.FrArea ^ ACF.PenAreaMod
	Data.DragCoef = ((Data.FrArea / 10000) / Data.ProjMass)
	Data.LimitVel = 100 --Most efficient penetration speed in m/s
	Data.KETransfert = 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet = 60 --Base ricochet angle
	Data.DetonatorAngle = 80
	Data.BoomPower = Data.PropMass + Data.FillerMass

	--Only the crates need this part
	if SERVER then
		ServerData.Id = PlayerData.Id
		ServerData.Type = PlayerData.Type

		return table.Merge(Data, ServerData)
	end

	--Only tthe GUI needs this part
	if CLIENT then
		GUIData = table.Merge(GUIData, Round.getDisplayData(Data))

		return table.Merge(Data, GUIData)
	end
end

function Round.getDisplayData(Data)
	local GUIData = {}
	GUIData.BlastRadius = Data.FillerMass ^ 0.33 * 8
	local FragMass = Data.ProjMass - Data.FillerMass
	GUIData.Fragments = math.max(math.floor((Data.FillerMass / FragMass) * ACF.HEFrag), 2)
	GUIData.FragMass = FragMass / GUIData.Fragments
	GUIData.FragVel = (Data.FillerMass * ACF.HEPower * 1000 / GUIData.FragMass / GUIData.Fragments) ^ 0.5

	return GUIData
end

function Round.network(Crate, BulletData)
	Crate:SetNWString("AmmoType", "HE")
	Crate:SetNWString("AmmoID", BulletData.Id)
	Crate:SetNWFloat("Caliber", BulletData.Caliber)
	Crate:SetNWFloat("ProjMass", BulletData.ProjMass)
	Crate:SetNWFloat("FillerMass", BulletData.FillerMass)
	Crate:SetNWFloat("PropMass", BulletData.PropMass)
	Crate:SetNWFloat("DragCoef", BulletData.DragCoef)
	Crate:SetNWFloat("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNWFloat("Tracer", BulletData.Tracer)
end

function Round.cratetxt(BulletData)
	local DData = Round.getDisplayData(BulletData)
	local str = {"Muzzle Velocity: ", math.Round(BulletData.MuzzleVel, 1), " m/s\n", "Blast Radius: ", math.Round(DData.BlastRadius, 1), " m\n", "Blast Energy: ", math.floor(BulletData.FillerMass * ACF.HEPower), " KJ"}

	return table.concat(str)
end

function Round.propimpact(Index, Bullet, Target, HitNormal, HitPos, Bone)
	if ACF_Check(Target) then
		local Speed = Bullet.Flight:Length() / ACF.VelScale
		local Energy = ACF_Kinetic(Speed, Bullet.ProjMass - Bullet.FillerMass, Bullet.LimitVel)
		local HitRes = ACF_RoundImpact(Bullet, Speed, Energy, Target, HitPos, HitNormal, Bone)
		if HitRes.Ricochet then return "Ricochet" end
	end

	return false
end

function Round.worldimpact(Index, Bullet, HitPos, HitNormal)
	return false
end

function Round.endflight(Index, Bullet, HitPos, HitNormal)
	ACF_HE(HitPos - Bullet.Flight:GetNormalized() * 3, HitNormal, Bullet.FillerMass, Bullet.ProjMass - Bullet.FillerMass, Bullet.Owner, nil, Bullet.Gun)
	ACF_RemoveBullet(Index)
end

function Round.endeffect(Effect, Bullet)
	local Radius = Bullet.FillerMass ^ 0.33 * 8 * 39.37
	local Flash = EffectData()
	Flash:SetOrigin(Bullet.SimPos)
	Flash:SetNormal(Bullet.SimFlight:GetNormalized())
	Flash:SetRadius(math.max(Radius, 1))
	util.Effect("ACF_Scaled_Explosion", Flash)
end

function Round.pierceeffect(Effect, Bullet)
	local BulletEffect = {}
	BulletEffect.Num = 1
	BulletEffect.Src = Bullet.SimPos - Bullet.SimFlight:GetNormalized()
	BulletEffect.Dir = Bullet.SimFlight:GetNormalized()
	BulletEffect.Spread = Vector(0, 0, 0)
	BulletEffect.Tracer = 0
	BulletEffect.Force = 0
	BulletEffect.Damage = 0
	LocalPlayer():FireBullets(BulletEffect)
	util.Decal("ExplosiveGunshot", Bullet.SimPos + Bullet.SimFlight * 10, Bullet.SimPos - Bullet.SimFlight * 10)
	local Spall = EffectData()
	Spall:SetOrigin(Bullet.SimPos)
	Spall:SetNormal((Bullet.SimFlight):GetNormalized())
	Spall:SetScale(math.max(((Bullet.RoundMass * (Bullet.SimFlight:Length() / 39.37) ^ 2) / 2000) / 10000, 1))
	util.Effect("AP_Hit", Spall)
end

function Round.ricocheteffect(Effect, Bullet)
	local Spall = EffectData()
	Spall:SetEntity(Bullet.Crate)
	Spall:SetOrigin(Bullet.SimPos)
	Spall:SetNormal(Bullet.SimFlight:GetNormalized())
	Spall:SetScale(Bullet.SimFlight:Length())
	Spall:SetMagnitude(Bullet.RoundMass)
	util.Effect("ACF_AP_Ricochet", Spall)
end

function Round.guicreate(Panel, Table)
	acfmenupanel:AmmoSelect(ACF.AmmoBlacklist.HE)
	acfmenupanel:CPanelText("BonusDisplay", "")
	acfmenupanel:CPanelText("Desc", "") --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "") --Total round length (Name, Desc)
	acfmenupanel:AmmoSlider("PropLength", 0, 0, 1000, 3, "Propellant Length", "") --Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", 0, 0, 1000, 3, "Projectile Length", "") --Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FillerVol", 0, 0, 1000, 3, "HE Filler", "") --Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "") --Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("BlastDisplay", "") --HE Blast data (Name, Desc)
	acfmenupanel:CPanelText("FragDisplay", "") --HE Fragmentation data (Name, Desc)
	--acfmenupanel:CPanelText("RicoDisplay", "")	--estimated rico chance
	Round.guiupdate(Panel, Table)
end

function Round.guiupdate(Panel, Table)
	local PlayerData = {}
	PlayerData.Id = acfmenupanel.AmmoData.Data.id --AmmoSelect GUI
	PlayerData.Type = "HE" --Hardcoded, match ACFRoundTypes table index
	PlayerData.PropLength = acfmenupanel.AmmoData.PropLength --PropLength slider
	PlayerData.ProjLength = acfmenupanel.AmmoData.ProjLength --ProjLength slider
	PlayerData.Data5 = acfmenupanel.AmmoData.FillerVol
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
	RunConsoleCommand("acfmenu_data5", Data.FillerVol)
	RunConsoleCommand("acfmenu_data10", Data.Tracer)
	local vol = ACF.Weapons.Ammo[acfmenupanel.AmmoData["Id"]].volume
	local Cap, CapMul, RoFMul = ACF_CalcCrateStats(vol, Data.RoundVolume)
	acfmenupanel:CPanelText("BonusDisplay", "Crate info: +" .. (math.Round((CapMul - 1) * 100, 1)) .. "% capacity, +" .. (math.Round((RoFMul - 1) * -100, 1)) .. "% RoF\nContains " .. Cap .. " rounds")
	acfmenupanel:AmmoSlider("PropLength", Data.PropLength, Data.MinPropLength, Data.MaxTotalLength, 3, "Propellant Length", "Propellant Mass : " .. (math.floor(Data.PropMass * 1000)) .. " g") --Propellant Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", Data.ProjLength, Data.MinProjLength, Data.MaxTotalLength, 3, "Projectile Length", "Projectile Mass : " .. (math.floor(Data.ProjMass * 1000)) .. " g") --Projectile Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("FillerVol", Data.FillerVol, Data.MinFillerVol, Data.MaxFillerVol, 3, "HE Filler Volume", "HE Filler Mass : " .. (math.floor(Data.FillerMass * 1000)) .. " g") --HE Filler Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer : " .. (math.floor(Data.Tracer * 10) / 10) .. "cm\n", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("Desc", ACF.RoundTypes[PlayerData.Type].desc) --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "Round Length : " .. (math.floor((Data.PropLength + Data.ProjLength + Data.Tracer) * 100) / 100) .. "/" .. Data.MaxTotalLength .. " cm") --Total round length (Name, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "Muzzle Velocity : " .. math.floor(Data.MuzzleVel * ACF.VelScale) .. " m/s") --Proj muzzle velocity (Name, Desc)	
	acfmenupanel:CPanelText("BlastDisplay", "Blast Radius : " .. (math.floor(Data.BlastRadius * 100) / 100) .. " m") --Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("FragDisplay", "Fragments : " .. Data.Fragments .. "\n Average Fragment Weight : " .. (math.floor(Data.FragMass * 10000) / 10) .. " g \n Average Fragment Velocity : " .. math.floor(Data.FragVel) .. " m/s") --Proj muzzle penetration (Name, Desc)
	--local RicoAngs = ACF_RicoProbability( Data.Ricochet, Data.MuzzleVel*ACF.VelScale )
	--acfmenupanel:CPanelText("RicoDisplay", "Ricochet probability vs impact angle:\n".."    0% @ "..RicoAngs.Min.." degrees\n  50% @ "..RicoAngs.Mean.." degrees\n100% @ "..RicoAngs.Max.." degrees")
end

list.Set("ACFRoundTypes", "HE", Round) --Set the round properties
list.Set("ACFIdRounds", Round.netid, "HE") --Index must equal the ID entry in the table above, Data must equal the index of the table above