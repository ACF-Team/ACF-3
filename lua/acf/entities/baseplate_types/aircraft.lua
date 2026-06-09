ACF.Classes.DefineClass("ACF.Baseplates.Aircraft", "ACF.Baseplates.BaseplateType", function()
	CLASS.Name        = "Aircraft"
	CLASS.Icon        = "icon16/weather_clouds.png"
	CLASS.Description = "A baseplate designed for aircraft."

	function CLASS:OnInitialize()
		self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	end

	function CLASS:PhysicsCollide(Data)
		BASE.BP_PhysicsCollideExplosion(self, Data)
	end
end)