ACF.Classes.DefineClass("ACF.Baseplates.Aircraft", "ACF.Baseplates.BaseplateType", function()
	CLASS.Name        = "Aircraft"
	CLASS.Icon        = "icon16/weather_clouds.png"
	CLASS.Description = "A baseplate designed for aircraft."

	MENU_FIELD("Number", "GForceTicks", {Min = 1, Max = 7, Default = 1, Decimals = 0})

	function CLASS.CreateMenu(SubMenu, NestedData, PushData)
		local Opts  = ACF.Classes.GetTypeFieldByName(CLASS, "GForceTicks").Options
		local Ticks = SubMenu:AddSlider("G-Force Sample Rate", Opts.Min, Opts.Max, Opts.Decimals)
		Ticks:SetValue(NestedData.GForceTicks or Opts.Default or 1)
		function Ticks:OnValueChanged(Value)
			NestedData.GForceTicks = math.Round(Value, Opts.Decimals or 0)
			PushData()
		end
	end

	function CLASS:OnInitialize(Entity)
		Entity:SetCollisionGroup(COLLISION_GROUP_WORLD)
	end

	function CLASS:PhysicsCollide(Entity, Data)
		BASE.BP_PhysicsCollideExplosion(Entity, Data)
	end
end)