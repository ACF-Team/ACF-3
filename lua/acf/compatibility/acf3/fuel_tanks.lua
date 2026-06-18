local Classes   = ACF.Classes
local Entities  = Classes.Entities
local Clamp     = math.Clamp

-- Pre-autoregister V2 data verification
Entities.RegisterCompatPatch("acf_fueltank", 2026061701, function(Data)
	local UD = Data.ACF_UserData
	if istable(UD) then return end -- Already V2

	UD = UD or {}

	-- Build size from FuelSizeX/Y/Z
	local Min, Max = ACF.ContainerMinSize, ACF.ContainerMaxSize

	local ConvertedFuelShape, ConvertedFuelType = "ACF.ContainerShapes.Box", "ACF.FuelTypes.Petrol"

	-- ACF-3/ACE backwards compatibility. Fuel size was saved as Size for a while in ACF-3, and ACE still saves it as SizeId.
	if (isvector(Data.Size) or isvector(Data.SizeId)) and (not Data.FuelSizeX or not Data.FuelSizeY or not Data.FuelSizeZ) then
		local SizeData = isvector(Data.SizeId) and "SizeId" or "Size"
		UD.FuelSizeX = Clamp(ACF.CheckNumber(Data[SizeData][1], 24), Min, Max)
		UD.FuelSizeY = Clamp(ACF.CheckNumber(Data[SizeData][2], 24), Min, Max)
		UD.FuelSizeZ = Clamp(ACF.CheckNumber(Data[SizeData][3], 24), Min, Max)

		UD.Size = Vector(Data.FuelSizeX, Data.FuelSizeY, Data.FuelSizeZ)
		Data[SizeData] = nil
		Data.FuelSizeX = nil
		Data.FuelSizeY = nil
		Data.FuelSizeZ = nil

		if isstring(Data.FuelTank) then
			ConvertedFuelShape = Data.FuelTank == "Drum" and "ACF.ContainerShapes.Cylinder" or "ACF.ContainerShapes.Box"
			Data.FuelTank = nil
		end
	-- Pre-scalable ACF-3 backwards compatibility for boxes. The X and Y values are swapped on purpose to match old tank models.
	elseif isstring(Data.FuelTank) and string.StartsWith(Data.FuelTank, "Tank_") then
		local TankSize = string.Split(string.TrimLeft(Data.FuelTank, "Tank_"), "x")
		local X = Clamp(ACF.CheckNumber(tonumber(TankSize[2]) * 10, 24), Min, Max)
		local Y = Clamp(ACF.CheckNumber(tonumber(TankSize[1]) * 10, 24), Min, Max)
		local Z = Clamp(ACF.CheckNumber(tonumber(TankSize[3]) * 10, 24), Min, Max)

		UD.Size = Vector(X, Y, Z)
		Data.FuelTank = nil
	-- Pre-scalable ACF-3 backwards compatibility for fuel drums.
	elseif isstring(Data.FuelTank) and Data.FuelTank == "Fuel_Drum" then
		ConvertedFuelShape = "ACF.ContainerShapes.Cylinder"
		UD.Size = Vector(28, 28, 45)
		Data.FuelTank = nil
	else
		local X = Clamp(ACF.CheckNumber(Data.FuelSizeX, 24), Min, Max)
		local Y = Clamp(ACF.CheckNumber(Data.FuelSizeY, 24), Min, Max)
		local Z = Clamp(ACF.CheckNumber(Data.FuelSizeZ, 24), Min, Max)

		UD.Size = Vector(X, Y, Z)
		Data.FuelSizeX = nil
		Data.FuelSizeY = nil
		Data.FuelSizeZ = nil
	end

	-- Making sure to provide a valid fuel type
	ConvertedFuelType = "ACF.FuelTypes." .. tostring(Data.FuelType)

	UD.FuelType  = {Type = ConvertedFuelType, Data = {}}
	UD.Shape = {Type = ConvertedFuelShape, Data = {}}
	Data.FuelType = nil

	Data.ACF_UserData = UD
end)