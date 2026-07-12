local ACF   = ACF
local Types = ACF.Classes.AmmoTypes
local Ammo  = Types.Register("APCR", "AP")


function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Armor Piercing Composite Rigid"
	self.SpawnIcon   = "acf/icons/shell_apcr.png"
	self.Bodygroup   = 2 -- APCR bodygroup index
	self.Description = "#acf.descs.ammo.apcr"
	self.Blacklist = ACF.GetWeaponBlacklist({
		C = true,
		AL = true,
		AC = true,
		SA = true,
		SC = true,
		LAC = true,
		RAC = true,
	})
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	Data.ProjMass  = Data.ProjArea * Data.ProjLength * ACF.SteelDensity --Volume of the projectile as a cylinder * density of steel (kg/in3)
	Data.MuzzleVel = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
	Data.DragCoef  = Data.ProjArea * 0.0001 / Data.ProjMass
	Data.CartMass  = Data.PropMass + Data.ProjMass

	hook.Run("ACF_OnUpdateRound", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, { ProjScale = 0.75 }) -- APCR has a smaller penetrator

	Data.ShovePower = 0.2
	Data.LimitVel   = 900 --Most efficient penetration speed in m/s
	Data.Ricochet   = 55 --Base ricochet angle

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

if SERVER then
	local Conversion	= ACF.PointConversion

	-- Since APCR
	function Ammo:GetCost(BulletData)
		return (BulletData.ProjMass * Conversion.Steel * 2.5) + (BulletData.PropMass * Conversion.Propellant)
	end

	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "APCR")
	end
else
	ACF.RegisterAmmoDecal("APCR", "damage/apcr_pen", "damage/apcr_rico")

	-- Ammo menu visual: a subcaliber steel core fused inside a full-bore body for the round's entire length (never discarded, unlike APDS's sabot).
	function Ammo:DrawAmmoVisual(Panel, w, h, _, BulletData)
		local GeoPrim = ACF.GeoPrim
		local Margin  = 10
		local DrawW   = w - Margin * 2

		local Length = BulletData.ProjLength + BulletData.PropLength

		if Length <= 0 then return end

		-- Cap Scale itself by the height budget so every shape shrinks uniformly, not just the radius.
		local Scale   = math.min(DrawW / Length, ((h - Margin * 2) * 0.6) / BulletData.Caliber)
		local BoreDia = BulletData.Caliber * Scale
		local CenterY = h * 0.5

		local Propellant = GeoPrim.New("Cylinder", { Radius = BulletData.Caliber * 0.5, Height = BulletData.PropLength })
		Propellant:SetMaterial("Propellant")

		-- Fused body, full bore diameter, wraps the core's entire length
		local Body = GeoPrim.New("Cylinder", { Radius = BulletData.Caliber * 0.5, Height = BulletData.ProjLength })
		Body:SetMaterial("Steel Body (Fused)")

		-- Steel core, drawn after the body at the same starting X so it's the on-top shape.
		local Core = GeoPrim.New("Cylinder", { Radius = BulletData.Diameter * 0.5, Height = BulletData.ProjLength })
		Core:SetMaterial("Steel Core")

		local X = Margin
		X = Propellant:Draw(Panel, X, CenterY, Scale, BoreDia, Color(180, 150, 60), Color(30, 30, 30))
		local CoreX = X
		Body:Draw(Panel, X, CenterY, Scale, BoreDia, Color(150, 150, 155), Color(30, 30, 30))
		Core:Draw(Panel, CoreX, CenterY, Scale, BoreDia, Color(120, 120, 130), Color(30, 30, 30))

		-- Tracer drawn last (not as a Core child) so it takes hover priority and renders red, not gray.
		if BulletData.Tracer and BulletData.Tracer > 0 then
			local Tracer = GeoPrim.New("Cylinder", { Radius = BulletData.Diameter * 0.5, Height = BulletData.Tracer })
			Tracer:SetMaterial("Tracer")
			Tracer:Draw(Panel, CoreX, CenterY, Scale, BoreDia, Color(220, 40, 30), Color(30, 30, 30))
		end
	end
end
