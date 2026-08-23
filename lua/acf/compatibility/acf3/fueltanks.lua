local GetType = ACF.Classes.GetTypeByName

-- Translates a legacy shape short ID ("Box"/"Sphere"/"Cylinder") into a ContainerShapes class FQN.
local function ShapeFQN(ID)
	local FQN = "ACF.ContainerShapes." .. tostring(ID)

	return GetType(FQN) and FQN or "ACF.ContainerShapes.Box"
end

-- Migrates legacy ACF-3 / ACE fuel tanks onto the AutoRegisterV2 serialized field set. This is where
-- all the historical size/shape encodings are normalised into FuelSizeX/Y/Z + the Shape class field;
-- FuelType is left as-is (the entity's ACF_OnVerifyClientData resolves the short id into a class).
ACF.Entities.RegisterCompatPatch("acf_fueltank", 2026062101, function(Data)
	if Data.ACF_UserData then return end

	local FuelTank = Data.FuelTank
	local Size     = Data.Size
	local SizeId   = Data.SizeId
	local ShapeID  = Data.FuelShape
	local SX       = Data.FuelSizeX
	local SY       = Data.FuelSizeY
	local SZ       = Data.FuelSizeZ

	-- Only derive size when it wasn't already saved per-axis (FuelSizeX/Y/Z).
	if not (SX and SY and SZ) then
		if isvector(SizeId) or isvector(Size) then
			-- Size saved as a Size/SizeId vector; shape encoded in the FuelTank group id.
			local S = isvector(SizeId) and SizeId or Size
			SX, SY, SZ = S[1], S[2], S[3]

			if isstring(FuelTank) then
				ShapeID = FuelTank == "Drum" and "Cylinder" or "Box"
			end
		elseif isstring(FuelTank) and string.StartsWith(FuelTank, "Tank_") then
			-- Pre-scalable boxes. X and Y are swapped on purpose to match old tank models.
			local TankSize = string.Split(string.TrimLeft(FuelTank, "Tank_"), "x")
			SX = (tonumber(TankSize[2]) or 2.4) * 10
			SY = (tonumber(TankSize[1]) or 2.4) * 10
			SZ = (tonumber(TankSize[3]) or 2.4) * 10
		elseif FuelTank == "Fuel_Drum" then
			-- Pre-scalable fuel drums.
			ShapeID = "Cylinder"
			SX, SY, SZ = 28, 28, 45
		end
	end

	if isstring(Data.FuelType) then
		Data.FuelType = {
			Type = "ACF.FuelTypes." .. Data.FuelType,
			Data = {}
		}
	end

	Data.ACF_UserData = {
		FuelType  = Data.FuelType,
		Shape     = ShapeFQN(ShapeID or "Box"),
		FuelSizeX = SX,
		FuelSizeY = SY,
		FuelSizeZ = SZ,
	}
end)
