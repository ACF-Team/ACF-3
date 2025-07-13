local Types     = ACF.Classes.BaseplateTypes
local Baseplate = Types.Register("Aircraft")

function Baseplate:OnLoaded()
    self.Name		 = "Aircraft"
    self.Icon        = "icon16/weather_clouds.png"
    self.Description = "A baseplate designed for aircraft."
end