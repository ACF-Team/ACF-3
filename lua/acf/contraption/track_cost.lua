hook.Add("cfw.contraption.created", "ACF_CFW_CostTrack", function(Contraption)
	-- print("cfw.contraption.created", Contraption)
	Contraption.Cost = 0
	Contraption.AmmoTypes = {}
	Contraption.MaxPen = 0
	Contraption.MaxNominal = 0
end)

hook.Add("cfw.contraption.entityAdded", "ACF_CFW_CostTrack", function(Contraption, Entity)
	-- print("cfw.contraption.entityAdded", Contraption, Entity)
	local PhysObj = Entity:GetPhysicsObject()
	Contraption.Cost = Contraption.Cost + 0.1 + (IsValid(PhysObj) and math.max(0.01, PhysObj:GetMass() / 500) or 0)

	if Entity.IsACFEntity then
		if Entity.IsACFAmmoCrate then
			Contraption.AmmoTypes[Entity.AmmoType] = true
		elseif Entity.IsACFEngine then
			Contraption.HorsePower = (Contraption.HorsePower or 0) + Entity.PeakPower
		end
	else
		if Entity.ACF then
			Contraption.MaxNominal = math.max(Contraption.MaxNominal or 0, math.Round(Entity.ACF.Armour or 0))
		end
	end
end)

hook.Add("cfw.contraption.entityRemoved", "ACF_CFW_CostTrack", function(Contraption, Entity)
	-- print("cfw.contraption.entityRemoved", Contraption, Entity)
end)

hook.Add("cfw.contraption.merged", "ACF_CFW_CostTrack", function(Contraption, MergedInto)
	-- print("cfw.contraption.merged", Contraption, MergedInto)
end)

hook.Add("cfw.contraption.removed", "ACF_CFW_CostTrack", function(Contraption)
	-- print("cfw.contraption.removed", Contraption)
end)