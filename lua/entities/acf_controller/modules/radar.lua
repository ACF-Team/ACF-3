local function Init(Entity)
	Entity.Radar             = nil      -- Radar, if any
	Entity.RadarVertical     = nil      -- Radar vertical turret, if any
	Entity.RadarUpdateRate   = 7        -- How often to update the radar, in ticks.
	Entity.SelectedTargetID  = nil      -- Currently selected radar target ID
	Entity.SelectedTargetPos = Vector() -- Position of currently selected radar target
	Entity.SelectedTargetVel = Vector() -- Velocity of currently selected radar target
end

-- Radar related
do
	function ENT:AnalyzeRadars(Radar)
		self.RadarVertical = Radar:GetParent()
		self.RadarUpdateRate = math.ceil(Radar.Outputs["Think Delay"].Value / (1 / 66))
	end

	net.Receive("ACF_Controller_Radar", function()
		local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
		local SelectedID = net.ReadUInt(6)
		local Entity = Entity(EntIndex)
		if not IsValid(Entity) then return end
		Entity.SelectedTargetID = SelectedID ~= 0 and SelectedID or nil
	end)

	function ENT:ProcessRadars(SelfTbl)
		local Radar = SelfTbl.Radar
		if not IsValid(Radar) then return end
		local Count = math.min(#Radar.Outputs.IDs.Value, 15)

		net.Start("ACF_Controller_Radar")
		net.WriteEntity(self)
		net.WriteUInt(Count, 4)
		for i = 1, Count do
			local ID = Radar.Outputs.IDs.Value[i] or 0
			net.WriteUInt(ID, 6)
			net.WriteString(Radar.Outputs.Owner.Value[i] or "")
			net.WriteVector(Radar.Outputs.Position.Value[i] or vector_origin)

			if ID == SelfTbl.SelectedTargetID then
				SelfTbl.SelectedTargetPos = Radar.Outputs.Position.Value[i] or vector_origin
				SelfTbl.SelectedTargetVel = Radar.Outputs.Velocity.Value[i] or vector_origin
			end
		end
		net.WriteVector(SelfTbl.SelectedTargetVel)
		net.Send(self.Driver)
	end
end

ACF.RegisterControllerLink("acf_radar", {
	Field = "Radar",
	Single = true,
	OnLinked = function(Controller, Target)
		Controller:AnalyzeRadars(Target)
	end,
})

return Init
