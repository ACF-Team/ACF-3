local Types     = ACF.Classes.BaseplateTypes
local Baseplate = Types.Register("Aircraft")

function Baseplate:OnLoaded()
    self.Name		 = "Aircraft"
    self.Description = "A baseplate designed for aircraft."
end