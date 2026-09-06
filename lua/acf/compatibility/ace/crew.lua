local ACEConversionLUT = {}
ACEConversionLUT.ace_crewseat_driver = {
    CrewType = "Driver"
}

ACEConversionLUT.ace_crewseat_gunner = {
    CrewType = "Gunner"
}

ACEConversionLUT.ace_crewseat_loader = {
    CrewType = "Loader"
}

local ACEModelConversion = {}
ACEModelConversion.Sitting = "SittingLarge"
ACEModelConversion["Sitting Alt"] = "SittingLarge"
ACEModelConversion.Standing = "StandingLarge"
-- todo
ACEModelConversion.Jeep = "StandingLarge"
ACEModelConversion.Airboat = "StandingLarge"

local function ConvertACEData(Data, ConvData)
    Data.Class = "acf_crew"
    Data.CrewTypeID = ConvData.CrewType
    Data.CrewModelID = ACEModelConversion[Data.ModelType]

    Data.ModelType = nil
end

for Class, ConvData in pairs(ACEConversionLUT) do
    ACF.Entities.RegisterCompatPatch(Class, -100000, function(Data) return ConvertACEData(Data, ConvData) end)
end