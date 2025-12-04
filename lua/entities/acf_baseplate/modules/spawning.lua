local ACF      		= ACF

function ENT.ACF_OnVerifyClientData(ClientData)
	ClientData.Size = Vector(ClientData.Length, ClientData.Width, ClientData.Thickness)
	if ClientData.BaseplateType ~= "Aircraft" then ClientData.GForceTicks = 1 end -- Only allow sample rates > 1 for aircraft baseplates
end

function ENT:ACF_PostUpdateEntityData(ClientData)
	self:SetSize(ClientData.Size)
	local Hook = self:ACF_GetUserVar("BaseplateType").OnInitialize
	if Hook then
		Hook(self)
	end
end

function ENT:ACF_PreSpawn(_, _, _, _)
	self:SetScaledModel("models/holograms/cube.mdl")
	self:SetMaterial("hunter/myplastic")
end

function ENT:ACF_PostSpawn(Owner, _, _, ClientData)
	local EntMods = ClientData.EntityMods
	if EntMods and EntMods.mass then
		ACF.Contraption.SetMass(self, self.ACF.Mass or 1)
	else
		ACF.Contraption.SetMass(self, 1000)
		duplicator.StoreEntityModifier(self, "mass", { Mass = 1000 })
	end

	-- Add seat support for baseplates
	if not self:ACF_GetUserVar "AlreadyHasSeat" then
		local Pod = ACF.GenerateLuaSeat(self, Owner, self:GetPos(), self:GetAngles(), self:GetModel(), true)
		if IsValid(Pod) then
			self:ConfigureLuaSeat(Pod, Owner)
		end
	end

	hook.Add("PhysgunPickup", "ACFBaseplatePickup" .. self:EntIndex(), function( _, ent )
		local Contraption = ent.GetContraption and ent:GetContraption()
		if Contraption ~= nil then
			Contraption.IsPickedUp = true
		end
	end)

	hook.Add("PhysgunDrop", "ACFBaseplateDrop" .. self:EntIndex(), function( _, ent )
		local Contraption = ent.GetContraption and ent:GetContraption()
		if Contraption ~= nil then
			Contraption.IsPickedUp = false
		end
	end)

	self:CallOnRemove("ACF_RemovePickupHooks", function()
		hook.Remove("PhysgunPickup", "ACFBaseplatePickup" .. self:EntIndex())
		hook.Remove("PhysgunDrop", "ACFBaseplateDrop" .. self:EntIndex())
	end)

	ACF.AugmentedTimer(function(cfg) self:UpdateAccuracyMod(cfg) end, function() return IsValid(self) end, nil, {MinTime = 0.1, MaxTime = 0.25})
	ACF.AugmentedTimer(function(cfg) self:UpdateFuelMod(cfg) end, function() return IsValid(self) end, nil, {MinTime = 0.1, MaxTime = 0.25})
	ACF.AugmentedTimer(function(cfg) self:EnforceLooped(cfg) end, function() return IsValid(self) end, nil, {MinTime = 0.1, MaxTime = 0.25})
	ACF.ActiveBaseplatesTable[self] = true
	table.insert(ACF.ActiveBaseplatesArray, self)

	self:CallOnRemove("ACF_RemoveBaseplateTableIndex", function(ent)
		ACF.ActiveBaseplatesTable[ent] = nil
		table.RemoveByValue(ACF.ActiveBaseplatesArray, ent)
	end)
end


function ENT:PreEntityCopy()
	if IsValid(self.Pod) then
		duplicator.StoreEntityModifier(self, "LuaSeatID", {self.Pod:EntIndex()})
	end
end

function ENT:PostEntityPaste(_, _, CreatedEntities)
	-- Pod should be valid since this runs after all entities are created
	local LuaSeatID = self.EntityMods
	LuaSeatID = LuaSeatID and LuaSeatID.LuaSeatID
	LuaSeatID = LuaSeatID and LuaSeatID[1]

	if LuaSeatID then
		self.Pod = CreatedEntities[LuaSeatID]
		if not IsValid(self.Pod) then
			ACF.SendNotify(self:CPPIGetOwner(), false, "The baseplate pod did not get duplicated correctly. You may have to relink pod controllers, etc.")
			local Pod = ACF.GenerateLuaSeat(self, self:CPPIGetOwner(), self:GetPos(), self:GetAngles(), self:GetModel(), true)
			if IsValid(Pod) then self.Pod = Pod end
		end
		self:ConfigureLuaSeat(self.Pod, self:CPPIGetOwner())
	end
end

function ENT:ACF_PostMenuSpawn()
	self:DropToFloor()
	self:SetAngles(self:GetAngles() + Angle(0, -90, 0))
end