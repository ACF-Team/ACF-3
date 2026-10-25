local ACF     = ACF
local Effects = ACF.Utilities.Effects

Effects.MaterialColors = {
	Default        = Color(120, 110, 100),
	[MAT_GRATE]    = Color(170, 160, 144),
	[MAT_CLIP]     = Color(170, 160, 144),
	[MAT_METAL]    = Color(170, 160, 144),
	[MAT_COMPUTER] = Color(170, 160, 144),
	[MAT_VENT]     = Color(170, 160, 144),
	[MAT_CONCRETE] = Color(180, 172, 158),
	[MAT_DIRT]     = Color(95, 80, 63),
	[MAT_GRASS]    = Color(114, 100, 80),
	[MAT_SLOSH]    = Color(104, 90, 70),
	[MAT_FOLIAGE]  = Color(104, 90, 70),
	[MAT_SNOW]     = Color(154, 140, 110),
	[MAT_PLASTIC]  = Color(150, 146, 141),
	[MAT_TILE]     = Color(150, 146, 141),
	[MAT_SAND]     = Color(180, 155, 100),
	[MAT_FLESH]    = Color(114, 50, 50),
}

-- How much dust each surface throws up, anything missing barely makes any
Effects.DustAmount = {
	[MAT_DIRT]     = 1,
	[MAT_SAND]     = 1,
	[MAT_GRASS]    = 0.8,
	[MAT_SNOW]     = 0.9,
	[MAT_SLOSH]    = 0.9,
	[MAT_FOLIAGE]  = 0.7,
	[MAT_CONCRETE] = 0.45,
	[MAT_TILE]     = 0.35,
}

do -- Lighting for particle effects
	-- The light is linear, the world is drawn with overbright and gamma on top, so match that or smoke comes out far darker than the walls around it
	local function GetBrightness(Light)
		return math.Clamp((Light * 2) ^ (1 / 2.2), 0.05, 1)
	end

	--- Returns a tint as a 0-255 vector, darkened by the light at a position.
	-- Unlit sprites glow in the dark, so particle effects tint themselves with this.
	-- ComputeLighting picks up dynamic lights such as muzzle flashes and lights smoke for seconds after they're gone, so only static light is used.
	-- @param Tint The colour in full light.
	-- @param Pos The position to sample the light at.
	-- @return The lit colour, ready to be passed as a control point.
	function Effects.GetLitColor(Tint, Pos)
		local Light = render.GetLightColor(Pos) + render.GetAmbientLightColor()

		return Vector(
			Tint.r * GetBrightness(Light.x),
			Tint.g * GetBrightness(Light.y),
			Tint.b * GetBrightness(Light.z)
		)
	end
end

do -- Resupply effect
	local render   = render
	local Distance = ACF.SupplyDistance

	local Supplies = {}
	Effects.Supplies = Supplies

	local function DrawSpheres(bDrawingDepth, _, isDraw3DSkybox)
		if bDrawingDepth or isDraw3DSkybox then return end

		render.SetColorMaterial()

		for Entity, RefillStatuses in pairs(Supplies) do
			local Pos = Entity:GetPos()

			for RefillType, Refilled in pairs(RefillStatuses) do
				if not Refilled then continue end

				local SupplyColor = ACF[RefillType .. "SupplyColor"] or ACF.AmmoSupplyColor

				render.DrawSphere(Pos, Distance, 50, 50, SupplyColor)
				render.DrawSphere(Pos, -Distance, 50, 50, SupplyColor)
			end
		end
	end

	local function Remove(Entity)
		if not IsValid(Entity) then return end

		Supplies[Entity] = nil

		Entity:RemoveCallOnRemove("ACF_Supply")

		if not next(Supplies) then
			hook.Remove("PostDrawOpaqueRenderables", "ACF_Supply")
		end
	end

	local function Add(Entity, RefilledAmmo, RefilledFuel, RevivedCrew)
		if not IsValid(Entity) then return end

		if not next(Supplies) then
			hook.Add("PostDrawOpaqueRenderables", "ACF_Supply", DrawSpheres)
		end

		Supplies[Entity] = { Ammo = RefilledAmmo, Fuel = RefilledFuel, Crew = RevivedCrew }

		Entity:CallOnRemove("ACF_Supply", Remove)
	end

	net.Receive("ACF_SupplyEffect", function()
		local Entity = net.ReadEntity()
		local RefilledAmmo = net.ReadBool()
		local RefilledFuel = net.ReadBool()
		local RevivedCrew = net.ReadBool()

		Add(Entity, RefilledAmmo, RefilledFuel, RevivedCrew)
	end)

	net.Receive("ACF_StopSupplyEffect", function()
		local Entity = net.ReadEntity()

		Remove(Entity)
	end)
end