local Round = table.Copy(ACF.RoundTypes.AP) -- inherit from AP

ACF.AmmoBlacklist.HP = ACF.AmmoBlacklist.AP
Round.type = "Ammo" --Tells the spawn menu what entity to spawn
Round.name = "Hollow Point (HP)" --Human readable name
Round.model = "models/munitions/round_100mm_shot.mdl" --Shell flight model
Round.desc = "A solid shell with a soft point, meant to flatten against armour"

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

	PlayerData.Data5 = math.max(PlayerData.Data5 or 0, 0)

	if not PlayerData.Data10 then
		PlayerData.Data10 = 0
	end

	PlayerData, Data, ServerData, GUIData = ACF_RoundBaseGunpowder(PlayerData, Data, ServerData, GUIData)
	--if GUIData.MaxCavVol != nil then PlayerData.Data5 = math.min(PlayerData.Data5, GUIData.MaxCavVol) end
	--Shell sturdiness calcs
	Data.ProjMass = Data.FrArea * (Data.ProjLength * 7.9 / 1000) --Volume of the projectile as a cylinder * density of steel
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)
	local Energy = ACF_Kinetic(Data.MuzzleVel * 39.37, Data.ProjMass, Data.LimitVel)
	local MaxVol = ACF_RoundShellCapacity(Energy.Momentum, Data.FrArea, Data.Caliber, Data.ProjLength)
	GUIData.MinCavVol = 0
	GUIData.MaxCavVol = math.min(GUIData.ProjVolume, MaxVol)
	Data.CavVol = math.Clamp(PlayerData.Data5, GUIData.MinCavVol, GUIData.MaxCavVol)
	Data.ProjMass = ((Data.FrArea * Data.ProjLength) - Data.CavVol) * 7.9 / 1000 --Volume of the projectile as a cylinder * fraction missing due to hollow point (Data5) * density of steel
	Data.MuzzleVel = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Caliber)
	local ExpRatio = (Data.CavVol / GUIData.ProjVolume)
	Data.ShovePower = 0.2 + ExpRatio / 2
	Data.ExpCaliber = Data.Caliber + ExpRatio * Data.ProjLength
	Data.PenArea = 3.1416 * ((Data.ExpCaliber / 2) ^ 2 ) ^ ACF.PenAreaMod
	Data.DragCoef = ((Data.FrArea / 10000) / Data.ProjMass)
	Data.LimitVel = 800 --Most efficient penetration speed in m/s
	Data.KETransfert = 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet = 60 --Base ricochet angle
	Data.CartMass = Data.PropMass + Data.ProjMass

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
	GUIData.MaxKETransfert = Energy.Kinetic * Data.ShovePower
	GUIData.MaxPen = (Energy.Penetration / Data.PenArea) * ACF.KEtoRHA

	return GUIData
end

function Round.network(Crate, BulletData)
	Crate:SetNWString("AmmoType", "HP")
	Crate:SetNWString("AmmoID", BulletData.Id)
	Crate:SetNWFloat("Caliber", BulletData.Caliber)
	Crate:SetNWFloat("ProjMass", BulletData.ProjMass)
	Crate:SetNWFloat("PropMass", BulletData.PropMass)
	Crate:SetNWFloat("ExpCaliber", BulletData.ExpCaliber)
	Crate:SetNWFloat("DragCoef", BulletData.DragCoef)
	Crate:SetNWFloat("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNWFloat("Tracer", BulletData.Tracer)
end

function Round.cratetxt(BulletData)
	local DData = Round.getDisplayData(BulletData)
	local str = {"Muzzle Velocity: ", math.Round(BulletData.MuzzleVel, 1), " m/s\n", "Max Penetration: ", math.floor(DData.MaxPen), " mm\n", "Expanded Caliber: ", math.floor(BulletData.ExpCaliber * 10), " mm\n", "Imparted Energy: ", math.floor(DData.MaxKETransfert), " KJ"}

	return table.concat(str)
end

function Round.guicreate(Panel)
	acfmenupanel:AmmoSelect(ACF.AmmoBlacklist.HP)

	acfmenupanel:CPanelText("Desc", "") --Description (Name, Desc)
	acfmenupanel:CPanelText("LengthDisplay", "") --Total round length (Name, Desc)
	acfmenupanel:AmmoSlider("PropLength", 0, 0, 1000, 3, "Propellant Length", "") --Propellant Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", 0, 0, 1000, 3, "Projectile Length", "") --Projectile Length Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("CavVol", 0, 0, 1000, 2, "Hollow Point Length", "") --Hollow Point Cavity Slider (Name, Value, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "") --Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("KEDisplay", "") --Proj muzzle KE (Name, Desc)
	--acfmenupanel:CPanelText("RicoDisplay", "")	--estimated rico chance
	acfmenupanel:CPanelText("PenetrationDisplay", "") --Proj muzzle penetration (Name, Desc)
	Round.guiupdate(Panel, nil)
end

function Round.guiupdate(Panel)
	local PlayerData = {}
	PlayerData.Id = acfmenupanel.AmmoData.Data.id --AmmoSelect GUI
	PlayerData.Type = "HP" --Hardcoded, match ACFRoundTypes table index
	PlayerData.PropLength = acfmenupanel.AmmoData.PropLength --PropLength slider
	PlayerData.ProjLength = acfmenupanel.AmmoData.ProjLength --ProjLength slider
	PlayerData.Data5 = acfmenupanel.AmmoData.CavVol
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
	RunConsoleCommand("acfmenu_data5", Data.CavVol)
	RunConsoleCommand("acfmenu_data10", Data.Tracer)

	acfmenupanel:AmmoUpdate()
	acfmenupanel:AmmoSlider("PropLength", Data.PropLength, Data.MinPropLength, Data.MaxTotalLength, 3, "Propellant Length", "Propellant Mass : " .. (math.floor(Data.PropMass * 1000)) .. " g") --Propellant Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("ProjLength", Data.ProjLength, Data.MinProjLength, Data.MaxTotalLength, 3, "Projectile Length", "Projectile Mass : " .. (math.floor(Data.ProjMass * 1000)) .. " g") --Projectile Length Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoSlider("CavVol", Data.CavVol, Data.MinCavVol, Data.MaxCavVol, 2, "Hollow Point cavity Volume", "Expanded caliber : " .. (math.floor(Data.ExpCaliber * 10)) .. " mm") --Hollow Point Cavity Slider (Name, Min, Max, Decimals, Title, Desc)
	acfmenupanel:AmmoCheckbox("Tracer", "Tracer : " .. (math.floor(Data.Tracer * 10) / 10) .. "cm\n", "") --Tracer checkbox (Name, Title, Desc)
	acfmenupanel:CPanelText("Desc", ACF.RoundTypes[PlayerData.Type].desc) --Description (Name, Desc)	
	acfmenupanel:CPanelText("LengthDisplay", "Round Length : " .. (math.floor((Data.PropLength + Data.ProjLength + Data.Tracer) * 100) / 100) .. "/" .. Data.MaxTotalLength .. " cm") --Total round length (Name, Desc)
	acfmenupanel:CPanelText("VelocityDisplay", "Muzzle Velocity : " .. math.floor(Data.MuzzleVel * ACF.Scale) .. " m/s") --Proj muzzle velocity (Name, Desc)
	acfmenupanel:CPanelText("KEDisplay", "Kinetic Energy Transfered : " .. math.floor(Data.MaxKETransfert) .. " KJ") --Proj muzzle KE (Name, Desc)	
	--local RicoAngs = ACF_RicoProbability( Data.Ricochet, Data.MuzzleVel*ACF.Scale )
	--acfmenupanel:CPanelText("RicoDisplay", "Ricochet probability vs impact angle:\n".."    0% @ "..RicoAngs.Min.." degrees\n  50% @ "..RicoAngs.Mean.." degrees\n100% @ "..RicoAngs.Max.." degrees")
	local R1V, R1P = ACF_PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 300)
	local R2V, R2P = ACF_PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 800)
	acfmenupanel:CPanelText("PenetrationDisplay", "Maximum Penetration : " .. math.floor(Data.MaxPen) .. " mm RHA\n\n300m pen: " .. math.Round(R1P, 0) .. "mm @ " .. math.Round(R1V, 0) .. " m\\s\n800m pen: " .. math.Round(R2P, 0) .. "mm @ " .. math.Round(R2V, 0) .. " m\\s\n\nThe range data is an approximation and may not be entirely accurate.") --Proj muzzle penetration (Name, Desc)
end

ACF.RoundTypes.HP = Round --Set the round properties

ACF.RegisterAmmoDecal("HP", "damage/ap_pen", "damage/ap_rico")