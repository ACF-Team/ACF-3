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
ACEModelConversion.Sitting = "Sitting_Large"
ACEModelConversion["Sitting Alt"] = "Sitting_Large"
ACEModelConversion.Standing = "Standing_Large"
-- todo
ACEModelConversion.Jeep = "Standing_Large"
ACEModelConversion.Airboat = "Standing_Large"

local function ConvertACEData(Data, ConvData)
    Data.Class = "acf_crew"
    Data.CrewTypeID = ConvData.CrewType
    Data.CrewModelID = ACEModelConversion[Data.ModelType]

    Data.ModelType = nil
end

for Class, ConvData in pairs(ACEConversionLUT) do
    ACF.Entities.RegisterCompatPatch(Class, -100000, function(Data) return ConvertACEData(Data, ConvData) end)
end