local FuelTanks = ACF.Classes.FuelTanks

FuelTanks.Register("FTS_D", {
	Name		= "Fuel Drum",
	Description	= "Scalable fuel drum; required for engines to work.",
	IsScalable	= true,
	Model		= "models/props_c17/oildrum001_explosive.mdl",
	Shape		= "Drum",
	NameType	= "Drum",
	IsExplosive	= true,
	Unlinkable	= false,
	Preview = {
		FOV = 120,
	},
	CalcVolume = function(Size, Wall)
		local Radius = Size.x / 2
		local InteriorVolume = math.pi * ((Radius - Wall) ^ 2) * (Size.z - Wall)

		local Area = 2 * math.pi * Radius * (Radius + Size.z)
		local Volume = InteriorVolume - (Area * Wall)

		return Volume, Area
	end,
	CalcOverlaySize = function(Entity)
		local D, _, H = Entity:GetSize():Unpack()
		D = math.Round(D, 2)
		H = math.Round(H, 2)

		return "Diameter: " .. D .. "\nHeight: " .. H .. "\n\n"
	end,
	VerifyData = function(Data, _) -- Diameter needs to be made equal for the X and Y dimensions
		Data.Size.y = Data.Size.x
	end,
	MenuSettings = function(SizeX, SizeY, SizeZ, FuelList)
		SizeX:SetVisible(true)
		SizeY:SetVisible(false)
		-- Purposely hide height slider before showing to prevent a minor visual bug when switching from box to drum
		SizeZ:SetVisible(false)
		SizeZ:SetVisible(true)
		FuelList:SetVisible(false)

		SizeX:SetText("Drum Diameter")
		SizeZ:SetText("Drum Height")
	end
})

do
	FuelTanks.RegisterItem("Drum", "FTS_D", {
		Name		= "Fuel Drum",
		Description	= "Tends to explode when shot.",
	})
end

do -- Old drum tank compatibility
	FuelTanks.RegisterItem("Fuel_Drum", "FTS_D", {
		Name	= "Fuel Drum",
		Size	= Vector(28, 28, 45),
		Model	= "models/props_c17/oildrum001_explosive.mdl",
		Shape	= "Drum"
	})
end