local TraceLine = util.TraceLine
local RecacheBindOutput = ENT.RecacheBindOutput
-- Camera related
do
	net.Receive("ACF_Controller_CamInfo", function(_, ply)
		local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
		local CamMode = net.ReadUInt(2)
		local Entity = Entity(EntIndex)
		if not IsValid(Entity) then return end
		if Entity.Driver ~= ply then return end
		if Entity:GetDisableAIOCam() then return end
		Entity.CamMode = math.Clamp(CamMode, 1, Entity:GetCamCount())
		Entity.CamOffset = Entity["GetCam" .. CamMode .. "Offset"]()
		Entity.CamOrbit = Entity["GetCam" .. CamMode .. "Orbit"]()
		Entity.CamParent = Entity["GetCam" .. CamMode .. "Parent"]()
		if not IsValid(Entity.CamParent) then Entity.CamParent = Entity end
	end)

	net.Receive("ACF_Controller_CamData", function(_, ply)
		local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
		local CamAng = net.ReadAngle()
		local Entity = Entity(EntIndex)
		if not IsValid(Entity) then return end
		if Entity.Driver ~= ply then return end
		if Entity:GetDisableAIOCam() then return end
		Entity.CamAng = CamAng
	end)

	net.Receive("ACF_Controller_Zoom", function(_, ply)
		local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
		local FOV = net.ReadFloat()
		local Entity = Entity(EntIndex)
		if not IsValid(Entity) then return end
		if Entity.Driver ~= ply then return end
		if Entity:GetDisableAIOCam() then return end
		Entity.FOV = FOV
		ply:SetFOV(FOV, 0, nil)
	end)

	local CamTraceConfig = {}
	function ENT:ProcessCameras(SelfTbl)
		if self:GetDisableAIOCam() then return end
		local CamAng = SelfTbl.CamAng or angle_zero
		RecacheBindOutput(self, SelfTbl, "CamAng", CamAng)

		local CamDir = CamAng:Forward()
		local CamOffset = SelfTbl.CamOffset or vector_origin
		local CamPos = self.CamParent:LocalToWorld(CamOffset)

		-- debugoverlay.Line(CamPos, CamPos + CamDir * 100, 0.1, Color(255, 0, 0), true)

		CamTraceConfig.start = CamPos
		CamTraceConfig.endpos = CamPos + CamDir * 99999
		CamTraceConfig.filter = SelfTbl.Filter or {self}
		local Tr = TraceLine(CamTraceConfig)

		local HitPos = Tr.HitPos or vector_origin
		self.HitPos = HitPos
		RecacheBindOutput(self, SelfTbl, "HitPos", HitPos)

		return CamPos, CamAng, HitPos
	end

	-- Cam related
	function ENT:AnalyzeCams()
		if self.UsesWireFilter then return end -- So we don't override the wire based filter

		-- Just get it from the contraption lol...
		local Filter = {self} -- Atleast filter the controller itself
		local Contraption = self:GetContraption()
		if Contraption ~= nil then
			-- And the contraption too if it's valid
			local LUT = Contraption.ents
			Filter = {}
			for v, _ in pairs(LUT) do
				if IsValid(v) then Filter[#Filter + 1] = v end
			end
		end
		self.Filter = Filter
		if not IsValid(self.CamParent) then self.CamParent = self end
	end
end