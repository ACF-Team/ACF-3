local ACF       = ACF
local Classes   = ACF.Classes
local AmmoTypes = Classes.AmmoTypes
local Ammo      = AmmoTypes.Register("HP", "AP")


function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Hollow Point"
	self.Description = "A round with a hollow cavity, meant to flatten against surfaces on impact."
	self.Blacklist = ACF.GetWeaponBlacklist({
		MG = true,
	})
end

function Ammo:GetDisplayData(Data)
	local Display = Ammo.BaseClass.GetDisplayData(self, Data)
	local Energy  = ACF.Kinetic(Data.MuzzleVel * 39.37, Data.ProjMass)

	Display.MaxKETransfert = Energy.Kinetic * Data.ShovePower

	hook.Run("ACF_GetDisplayData", self, Data, Display)

	return Display
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local FreeVol      = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, Data.ProjLength)
	local HollowCavity = FreeVol * math.Clamp(ToolData.HollowRatio, 0, 1)
	local ExpRatio     = HollowCavity / GUIData.ProjVolume

	Data.CavVol     = HollowCavity
	Data.ProjMass   = (Data.ProjArea * Data.ProjLength - HollowCavity) * ACF.SteelDensity --Volume of the projectile as a cylinder * fraction missing due to hollow point (Data5) * density of steel
	Data.MuzzleVel  = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
	Data.ShovePower = 0.2 + ExpRatio * 0.5
	Data.Diameter   = Data.Caliber + ExpRatio * Data.ProjLength
	Data.DragCoef   = Data.ProjArea * 0.0001 / Data.ProjMass
	Data.CartMass   = Data.PropMass + Data.ProjMass

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	Data.LimitVel = 400 --Most efficient penetration speed in m/s
	Data.Ricochet = 90 --Base ricochet angle

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:VerifyData(ToolData)
	Ammo.BaseClass.VerifyData(self, ToolData)

	if not isnumber(ToolData.HollowRatio) then
		ToolData.HollowRatio = 0.5
	end
end

if SERVER then
	local Entities = Classes.Entities

	Entities.AddArguments("acf_ammo", "HollowRatio") -- Adding extra info to ammo crates

	function Ammo:OnLast(Entity)
		Ammo.BaseClass.OnLast(self, Entity)

		Entity.HollowRatio = nil

		-- Cleanup the leftovers aswell
		Entity.HollowCavity = nil
		Entity.RoundData5   = nil
	end

	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "HP")
	end

	function Ammo:GetCrateText(BulletData)
		local BaseText = Ammo.BaseClass.GetCrateText(self, BulletData)
		local Data	   = self:GetDisplayData(BulletData)
		local Text	   = BaseText .. "\nExpanded Caliber: %s mm\nImparted Energy: %s KJ"

		return Text:format(math.Round(BulletData.Diameter * 10, 2), math.Round(Data.MaxKETransfert, 2))
	end
else
	ACF.RegisterAmmoDecal("HP", "damage/ap_pen", "damage/ap_rico")

	function Ammo:AddAmmoControls(Base, ToolData, BulletData)
		local HollowRatio = Base:AddSlider("Cavity Ratio", 0, 1, 2)
		HollowRatio:SetClientData("HollowRatio", "OnValueChanged")
		HollowRatio:DefineSetter(function(_, _, _, Value)
			ToolData.HollowRatio = math.Round(Value, 2)

			self:UpdateRoundData(ToolData, BulletData)

			return BulletData.CavVol
		end)
	end

	function Ammo:AddCrateDataTrackers(Trackers, ...)
		Ammo.BaseClass.AddCrateDataTrackers(self, Trackers, ...)

		Trackers.HollowRatio = true
	end

	function Ammo:AddAmmoInformation(Base, ToolData, BulletData)
		local RoundStats = Base:AddLabel()
		RoundStats:TrackClientData("Projectile", "SetText")
		RoundStats:TrackClientData("Propellant")
		RoundStats:TrackClientData("HollowRatio")
		RoundStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text		= "Muzzle Velocity : %s m/s\nProjectile Mass : %s\nPropellant Mass : %s"
			local MuzzleVel	= math.Round(BulletData.MuzzleVel * ACF.Scale, 2)
			local ProjMass	= ACF.GetProperMass(BulletData.ProjMass)
			local PropMass	= ACF.GetProperMass(BulletData.PropMass)

			return Text:format(MuzzleVel, ProjMass, PropMass)
		end)

		local HollowStats = Base:AddLabel()
		HollowStats:TrackClientData("Projectile", "SetText")
		HollowStats:TrackClientData("Propellant")
		HollowStats:TrackClientData("HollowRatio")
		HollowStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text	  = "Expanded Caliber : %s mm\nTransfered Energy : %s KJ"
			local Caliber = math.Round(BulletData.Diameter * 10, 2)
			local Energy  = math.Round(BulletData.MaxKETransfert, 2)

			return Text:format(Caliber, Energy)
		end)

		local PenStats = Base:AddLabel()
		PenStats:TrackClientData("Projectile", "SetText")
		PenStats:TrackClientData("Propellant")
		PenStats:TrackClientData("HollowRatio")
		PenStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text     = "Penetration : %s mm RHA\nAt 300m : %s mm RHA @ %s m/s\nAt 800m : %s mm RHA @ %s m/s"
			local MaxPen   = math.Round(BulletData.MaxPen, 2)
			local R1P, R1V = self:GetRangedPenetration(BulletData, 300)
			local R2V, R2P = self:GetRangedPenetration(BulletData, 800)

			return Text:format(MaxPen, R1P, R1V, R2P, R2V)
		end)

		Base:AddLabel("Note: The penetration range data is an approximation and may not be entirely accurate.")
	end
end