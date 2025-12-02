
hook.Add("cfw.contraption.created", "ACF_CFW_CostTrack", function(Contraption)
	print("cfw.contraption.created", Contraption)
	Contraption.Cost = 0
	Contraption.AmmoTypes = {}
	Contraption.MaxPen = 0
	Contraption.MaxNominal = 0
end)

hook.Add("cfw.contraption.entityAdded", "ACF_CFW_CostTrack", function(Contraption, Entity)
	-- print("cfw.contraption.entityAdded", Contraption, Entity)
	local PhysObj = Entity:GetPhysicsObject()
	Contraption.Cost = Contraption.Cost + 0.1 + (IsValid(PhysObj) and math.max(0.01, PhysObj:GetMass() / 500) or 0)

	if Entity.IsACFEntity and Entity.IsACFAmmoCrate then
		Contraption.AmmoTypes[Entity.AmmoType] = true

		local Bullet  = Entity.BulletData
		local Display = Entity.RoundData:GetDisplayData(Bullet)
		local MaxPen  = math.Round(Display.MaxPen)
		Contraption.MaxPen = math.max(Contraption.MaxPen or 0, MaxPen)
	end

	if Entity.ACF then
		Contraption.MaxNominal = math.max(Contraption.MaxNominal or 0, math.Round(Entity.ACF.Armour or 0))
	end
end)

hook.Add("cfw.contraption.entityRemoved", "ACF_CFW_CostTrack", function(Contraption, Entity)
	print("cfw.contraption.entityRemoved", Contraption, Entity)
end)

hook.Add("cfw.contraption.merged", "ACF_CFW_CostTrack", function(Contraption, MergedInto)
	print("cfw.contraption.merged", Contraption, MergedInto)
end)

hook.Add("cfw.contraption.removed", "ACF_CFW_CostTrack", function(Contraption)
	print("cfw.contraption.removed", Contraption)
end)

if CLIENT then
	net.Receive("ReqContraption", function()
		local Entity = net.ReadEntity()
		Entity.Name = net.ReadString()
		Entity.BaseplateType = net.ReadString()
		Entity.Cost = math.Round(net.ReadFloat(), 2)
		Entity.Count = net.ReadUInt(9)
		Entity.TotalMass = net.ReadUInt(24)
		Entity.MaxPen = net.ReadUInt(10)
		Entity.MaxNominal = net.ReadUInt(10)
		-- print("Received Data", Entity)
	end)
elseif SERVER then
	util.AddNetworkString( "ReqContraption" )

	net.Receive("ReqContraption", function(Len, Player)
		local Entity = net.ReadEntity()

		if not IsValid(Entity) then return end
		if not Entity.GetContraption then return end

		local Contraption = Entity:GetContraption()

		if not Contraption then return end

		net.Start("ReqContraption")
		net.WriteEntity(Entity)
		net.WriteString(Contraption.ACF_Baseplate and Contraption.ACF_Baseplate:ACF_GetUserVar("Name") or "Unknown")
		net.WriteString(Contraption.ACF_Baseplate and Contraption.ACF_Baseplate:ACF_GetUserVar("BaseplateType").ID or "Unknown")
		net.WriteFloat(Contraption.Cost or 0)
		net.WriteUInt(Contraption.count or 0, 9)
		net.WriteUInt(Contraption.totalMass or 0, 24)
		net.WriteUInt(Contraption.MaxPen or 0, 10)
		net.WriteUInt(Contraption.MaxNominal or 0, 10)
		net.Send(Player)
	end)
end