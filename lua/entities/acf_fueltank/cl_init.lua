include("shared.lua")

function ENT:Update()
	self.HitBoxes = {
		Main = {
			Pos = self:OBBCenter(),
			Scale = (self:OBBMaxs() - self:OBBMins()) - Vector(2, 2, 2),
			Angle = Angle(),
			Sensitive = false
		}
	}
end