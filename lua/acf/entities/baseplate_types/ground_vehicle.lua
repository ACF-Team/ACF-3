local Types     = ACF.Classes.BaseplateTypes
local Baseplate = Types.Register("GroundVehicle")

function Baseplate:OnLoaded()
    self.Name		 = "Ground Vehicle"
    self.Description = "A baseplate designed for a ground vehicle."
end