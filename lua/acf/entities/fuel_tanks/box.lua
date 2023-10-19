local FuelTanks = ACF.Classes.FuelTanks

FuelTanks.Register("FTS_B", {
	Name		= "Fuel Box",
	Description	= "Scalable fuel box; required for engines to work.",
	IsScalable	= true,
	Model		= "models/fueltank/fueltank_4x4x4.mdl",
	Shape		= "Box",
	NameType	= "Tank",
	IsExplosive	= true,
	Unlinkable	= false,
	Preview = {
		FOV = 120,
	},
	CalcVolume = function(Size, Wall)
		local InteriorVolume = (Size.x - Wall) * (Size.y - Wall) * (Size.z - Wall) -- Math degree

		local Area = (2 * Size.x * Size.y) + (2 * Size.y * Size.z) + (2 * Size.x * Size.z)
		local Volume = InteriorVolume - (Area * Wall)

		return Volume, Area
	end,
	CalcOverlaySize = function(Entity)
		local X, Y, Z = Entity:GetSize():Unpack()
		X = math.Round(X, 2)
		Y = math.Round(Y, 2)
		Z = math.Round(Z, 2)

		return "Size: " .. X .. "x" .. Y .. "x" .. Z .. "\n\n"
	end
})

do
	FuelTanks.RegisterItem("Box", "FTS_B", {
		Name		= "Fuel Box",
		Description	= "", -- Blank to allow for dynamic descriptions better
	})
end

-- NOTE: The X and Y values for older containers are swapped on purpose to match old model shapes

do -- Size 1 container compatibility
	FuelTanks.AddAlias("FTS_B", "FTS_1")

	FuelTanks.RegisterItem("Tank_1x1x1", "FTS_B", {
		Size	= Vector(10, 10, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_1x1x2", "FTS_B", {
		Size	= Vector(10, 10, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_1x1x4", "FTS_B", {
		Size	= Vector(10, 10, 40),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_1x2x1", "FTS_B", {
		Size	= Vector(20, 10, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_1x2x2", "FTS_B", {
		Size	= Vector(20, 10, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_1x2x4", "FTS_B", {
		Size	= Vector(20, 10, 40),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_1x4x1", "FTS_B", {
		Size	= Vector(40, 10, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_1x4x2", "FTS_B", {
		Size	= Vector(40, 10, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_1x4x4", "FTS_B", {
		Size	= Vector(40, 10, 40),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_1x6x1", "FTS_B", {
		Size	= Vector(60, 10, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_1x6x2", "FTS_B", {
		Size	= Vector(60, 10, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_1x6x4", "FTS_B", {
		Size	= Vector(60, 10, 40),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_1x8x1", "FTS_B", {
		Size	= Vector(80, 10, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_1x8x2", "FTS_B", {
		Size	= Vector(80, 10, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_1x8x4", "FTS_B", {
		Size	= Vector(80, 10, 40),
		Shape	= "Box"
	})
end

do -- Size 2 container compatibility
	FuelTanks.AddAlias("FTS_B", "FTS_2")

	FuelTanks.RegisterItem("Tank_2x2x1", "FTS_B", {
		Size	= Vector(20, 20, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_2x2x2", "FTS_B", {
		Size	= Vector(20, 20, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_2x2x4", "FTS_B", {
		Size	= Vector(20, 20, 40),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_2x4x1", "FTS_B", {
		Size	= Vector(40, 20, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_2x4x2", "FTS_B", {
		Size	= Vector(40, 20, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_2x4x4", "FTS_B", {
		Size	= Vector(40, 20, 40),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_2x6x1", "FTS_B", {
		Size	= Vector(60, 20, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_2x6x2", "FTS_B", {
		Size	= Vector(60, 20, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_2x6x4", "FTS_B", {
		Size	= Vector(60, 20, 40),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_2x8x1", "FTS_B", {
		Size	= Vector(80, 20, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_2x8x2", "FTS_B", {
		Size	= Vector(80, 20, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_2x8x4", "FTS_B", {
		Size	= Vector(80, 20, 40),
		Shape	= "Box"
	})
end

do -- Size 4 container compatibility
	FuelTanks.AddAlias("FTS_B", "FTS_4")

	FuelTanks.RegisterItem("Tank_4x4x1", "FTS_B", {
		Size	= Vector(40, 40, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_4x4x2", "FTS_B", {
		Size	= Vector(40, 40, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_4x4x4", "FTS_B", {
		Size	= Vector(40, 40, 40),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_4x6x1", "FTS_B", {
		Size	= Vector(60, 40, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_4x6x2", "FTS_B", {
		Size	= Vector(60, 40, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_4x6x4", "FTS_B", {
		Size	= Vector(60, 40, 40),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_4x8x1", "FTS_B", {
		Size	= Vector(80, 40, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_4x8x2", "FTS_B", {
		Size	= Vector(80, 40, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_4x8x4", "FTS_B", {
		Size	= Vector(80, 40, 40),
		Shape	= "Box"
	})
end

do -- Size 6 container compatibility
	FuelTanks.AddAlias("FTS_B", "FTS_6")

	FuelTanks.RegisterItem("Tank_6x6x1", "FTS_B", {
		Size	= Vector(60, 60, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_6x6x2", "FTS_B", {
		Size	= Vector(60, 60, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_6x6x4", "FTS_B", {
		Size	= Vector(60, 60, 40),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_6x8x1", "FTS_B", {
		Size	= Vector(80, 60, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_6x8x2", "FTS_B", {
		Size	= Vector(80, 60, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_6x8x4", "FTS_B", {
		Size	= Vector(80, 60, 40),
		Shape	= "Box"
	})
end

do -- Size 8 container compatibility
	FuelTanks.AddAlias("FTS_B", "FTS_8")

	FuelTanks.RegisterItem("Tank_8x8x1", "FTS_B", {
		Size	= Vector(80, 80, 10),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_8x8x2", "FTS_B", {
		Size	= Vector(80, 80, 20),
		Shape	= "Box"
	})

	FuelTanks.RegisterItem("Tank_8x8x4", "FTS_B", {
		Size	= Vector(80, 80, 40),
		Shape	= "Box"
	})
end