local ACF   = ACF
local Types = ACF.Classes.AmmoTypes
local Ammo  = Types.Register("APDS", "AP")


function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Armor Piercing Discarding Sabot"
	self.SpawnIcon   = "acf/icons/shell_apds.png"
	self.Bodygroup   = 3 -- APDS bodygroup index
	self.Description = "#acf.descs.ammo.apds"
	self.Blacklist = ACF.GetWeaponBlacklist({
		C = true,
		AL = true,
		AC = true,
		SA = true,
		RAC = true,
	})
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local Cylinder  = (math.pi * (Data.Caliber * 0.5) ^ 2) * Data.ProjLength * 0.5 -- A cylinder 1/2 the length of the projectile
	local Hole		= Data.ProjArea * Data.ProjLength * 0.5 -- Volume removed by the hole the dart passes through
	local SabotMass = (Cylinder - Hole) * ACF.AluminumDensity -- Aluminum sabot

	Data.ProjMass  = Data.ProjArea * Data.ProjLength * ACF.SteelDensity -- Volume of the projectile as a cylinder * density of steel
	Data.MuzzleVel = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass + SabotMass, Data.Efficiency)
	Data.DragCoef  = Data.ProjArea * 0.000125 / Data.ProjMass -- Worse drag (Manually fudged to make a meaningful difference)
	Data.CartMass  = Data.PropMass + Data.ProjMass + SabotMass

	hook.Run("ACF_OnUpdateRound", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, { ProjScale = 0.45 }) -- Ratio of projectile to gun caliber

	Data.ShovePower = 0.2
	Data.LimitVel   = 950 --Most efficient penetration speed in m/s
	Data.Ricochet   = 80 --Base ricochet angle

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

-- Shared with the client so the spawn menu can price a crate without spawning it.
local Conversion = ACF.PointConversion

function Ammo:GetCost(BulletData)
	local SabotMass	= BulletData.CartMass - BulletData.PropMass - BulletData.ProjMass

	return (BulletData.ProjMass * Conversion.Steel * 6) + (BulletData.PropMass * Conversion.Propellant) + (SabotMass * Conversion.Aluminum)
end

if SERVER then

	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "APDS")
	end
else
	ACF.RegisterAmmoDecal("APDS", "damage/apcr_pen", "damage/apcr_rico")

	-- Ammo menu visual: a steel dart (BulletData.Diameter, scaled down to 45% of bore) riding inside
	-- a full-bore aluminum sabot that wraps half of the dart's length, matching UpdateRoundData's mass split.
	function Ammo:DrawAmmoVisual(Panel, w, h, _, BulletData)
		local GeoPrim = ACF.GeoPrim
		local Margin  = 10
		local DrawW   = w - Margin * 2

		local SabotLenCm = math.min(BulletData.ProjLength * 0.5, BulletData.ProjLength) -- matches the "1/2 of ProjLength" sabot volume assumed in UpdateRoundData
		local Length = BulletData.ProjLength + BulletData.PropLength

		if Length <= 0 then return end

		-- Cap Scale itself by the height budget so every shape shrinks uniformly, not just the radius.
		-- The case, not the bore, is the widest part of a necked round, so it sets the budget.
		local CaseDia = BulletData.CaseDiameter

		if CaseDia <= 0 then return end

		local Scale   = math.min(DrawW / Length, ((h - Margin * 2) * 0.6) / CaseDia)
		local MaxDia  = CaseDia * Scale
		local CenterY = h * 0.5

		local Propellant = GeoPrim.New("Cylinder", { Radius = CaseDia * 0.5, Height = BulletData.PropLength })
		Propellant:SetMaterial("Propellant")

		-- Discarding sabot, full bore diameter, only wraps the rear portion of the dart
		local Sabot = GeoPrim.New("Cylinder", { Radius = BulletData.Caliber * 0.5, Height = SabotLenCm })
		Sabot:SetMaterial("Aluminum Sabot (Discarding)")

		-- Steel dart, running the full length of the projectile. Drawn after the sabot at the same
		-- starting X so it's the on-top, narrower shape within the overlap.
		local Penetrator = GeoPrim.New("Cylinder", { Radius = BulletData.Diameter * 0.5, Height = BulletData.ProjLength })
		Penetrator:SetMaterial("Steel Penetrator")

		local X = Margin
		X = Propellant:Draw(Panel, X, CenterY, Scale, MaxDia, Color(180, 150, 60), Color(30, 30, 30))
		local DartX = X
		Sabot:Draw(Panel, X, CenterY, Scale, MaxDia, Color(150, 150, 155), Color(30, 30, 30))
		Penetrator:Draw(Panel, DartX, CenterY, Scale, MaxDia, Color(120, 120, 130), Color(30, 30, 30))

		-- Tracer, a colored segment at the base of the dart, drawn last (and not as a Dart child --
		-- Draw() paints an entire subtree in one Color, so a child never gets a color of its own) so it
		-- takes hover priority and actually renders red instead of inheriting the penetrator's gray.
		if BulletData.Tracer and BulletData.Tracer > 0 then
			local Tracer = GeoPrim.New("Cylinder", { Radius = BulletData.Diameter * 0.5, Height = BulletData.Tracer })
			Tracer:SetMaterial("Tracer")
			Tracer:Draw(Panel, DartX, CenterY, Scale, MaxDia, Color(220, 40, 30), Color(30, 30, 30))
		end
	end
end
