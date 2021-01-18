local Ammo = ACF.RegisterAmmoType("HP", "AP")

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
	local Energy  = ACF_Kinetic(Data.MuzzleVel * 39.37, Data.ProjMass, Data.LimitVel)

	Display.MaxKETransfert = Energy.Kinetic * Data.ShovePower

	hook.Run("ACF_GetDisplayData", self, Data, Display)

	return Display
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local ProjMass	   = math.max(GUIData.ProjVolume * 0.5, 0) * 0.0079 --(Volume of the projectile as a cylinder - Volume of the cavity) * density of steel 
	local MuzzleVel	   = ACF_MuzzleVelocity(Data.PropMass, ProjMass)
	local Energy	   = ACF_Kinetic(MuzzleVel * 39.37, ProjMass, Data.LimitVel)
	local MaxVol	   = ACF.RoundShellCapacity(Energy.Momentum, Data.FrArea, Data.Caliber, Data.ProjLength)
	local MaxCavity	   = math.min(GUIData.ProjVolume, MaxVol)
	local HollowCavity = math.Clamp(ToolData.HollowCavity, GUIData.MinCavVol, MaxCavity)
	local ExpRatio	   = HollowCavity / GUIData.ProjVolume

	GUIData.MaxCavVol = MaxCavity

	Data.CavVol		= HollowCavity
	Data.ProjMass	= (Data.FrArea * Data.ProjLength - HollowCavity) * 0.0079 --Volume of the projectile as a cylinder * fraction missing due to hollow point (Data5) * density of steel
	Data.MuzzleVel	= ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass)
	Data.ShovePower	= 0.2 + ExpRatio * 0.5
	Data.ExpCaliber	= Data.Caliber + ExpRatio * Data.ProjLength
	Data.PenArea	= (3.1416 * Data.ExpCaliber * 0.5) ^ 2 ^ ACF.PenAreaMod
	Data.DragCoef	= Data.FrArea * 0.0001 / Data.ProjMass
	Data.CartMass	= Data.PropMass + Data.ProjMass

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	GUIData.MinCavVol = 0

	Data.LimitVel	 = 400 --Most efficient penetration speed in m/s
	Data.KETransfert = 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet	 = 90 --Base ricochet angle

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:VerifyData(ToolData)
	Ammo.BaseClass.VerifyData(self, ToolData)

	if not ToolData.HollowCavity then
		local Data5 = ToolData.RoundData5

		ToolData.HollowCavity = Data5 and tonumber(Data5) or 0
	end
end

if SERVER then
	ACF.AddEntityArguments("acf_ammo", "HollowCavity") -- Adding extra info to ammo crates

	function Ammo:OnLast(Entity)
		Ammo.BaseClass.OnLast(self, Entity)

		Entity.HollowCavity = nil

		-- Cleanup the leftovers aswell
		Entity.RoundData5 = nil
	end

	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "HP")
	end

	function Ammo:GetCrateText(BulletData)
		local BaseText = Ammo.BaseClass.GetCrateText(self, BulletData)
		local Data	   = self:GetDisplayData(BulletData)
		local Text	   = BaseText .. "\nExpanded Caliber: %s mm\nImparted Energy: %s KJ"

		return Text:format(math.Round(BulletData.ExpCaliber * 10, 2), math.Round(Data.MaxKETransfert, 2))
	end
else
	ACF.RegisterAmmoDecal("HP", "damage/ap_pen", "damage/ap_rico")

	function Ammo:AddAmmoControls(Base, ToolData, BulletData)
		local HollowCavity = Base:AddSlider("Cavity Volume", BulletData.MinCavVol, BulletData.MaxCavVol, 2)
		HollowCavity:SetClientData("HollowCavity", "OnValueChanged")
		HollowCavity:TrackClientData("Projectile")
		HollowCavity:DefineSetter(function(Panel, _, Key, Value)
			if Key == "HollowCavity" then
				ToolData.HollowCavity = math.Round(Value, 2)
			end

			self:UpdateRoundData(ToolData, BulletData)

			Panel:SetMax(BulletData.MaxCavVol)
			Panel:SetValue(BulletData.CavVol)

			return BulletData.CavVol
		end)
	end

	function Ammo:AddCrateDataTrackers(Trackers, ...)
		Ammo.BaseClass.AddCrateDataTrackers(self, Trackers, ...)

		Trackers.HollowCavity = true
	end

	function Ammo:AddAmmoInformation(Base, ToolData, BulletData)
		local RoundStats = Base:AddLabel()
		RoundStats:TrackClientData("Projectile", "SetText")
		RoundStats:TrackClientData("Propellant")
		RoundStats:TrackClientData("HollowCavity")
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
		HollowStats:TrackClientData("HollowCavity")
		HollowStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text	  = "Expanded Caliber : %s mm\nTransfered Energy : %s KJ"
			local Caliber = math.Round(BulletData.ExpCaliber * 10, 2)
			local Energy  = math.Round(BulletData.MaxKETransfert, 2)

			return Text:format(Caliber, Energy)
		end)

		local PenStats = Base:AddLabel()
		PenStats:TrackClientData("Projectile", "SetText")
		PenStats:TrackClientData("Propellant")
		PenStats:TrackClientData("HollowCavity")
		PenStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text	   = "Penetration : %s mm RHA\nAt 300m : %s mm RHA @ %s m/s\nAt 800m : %s mm RHA @ %s m/s"
			local MaxPen   = math.Round(BulletData.MaxPen, 2)
			local R1V, R1P = ACF.PenRanging(BulletData.MuzzleVel, BulletData.DragCoef, BulletData.ProjMass, BulletData.PenArea, BulletData.LimitVel, 300)
			local R2V, R2P = ACF.PenRanging(BulletData.MuzzleVel, BulletData.DragCoef, BulletData.ProjMass, BulletData.PenArea, BulletData.LimitVel, 800)

			return Text:format(MaxPen, R1P, R1V, R2P, R2V)
		end)

		Base:AddLabel("Note: The penetration range data is an approximation and may not be entirely accurate.")
	end
end