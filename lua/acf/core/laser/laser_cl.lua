local Sources = ACF.LaserSources

net.Receive("ACF_SetupLaserSource", function()
	local Entity = net.ReadEntity()
	local Data = net.ReadTable()

	ACF.AddLaserSource(Entity, Data)
end)

net.Receive("ACF_ClearLaserSource", function()
	local Entity = net.ReadEntity()

	ACF.RemoveLaserSource(Entity)
end)

net.Receive("ACF_SyncLaserSources", function()
	local Message = net.ReadTable()

	for Entity, Data in pairs(Message) do
		ACF.AddLaserSource(Entity, Data)
	end
end)

net.Receive("ACF_UpdateLaserFilter", function()
	local Entity = net.ReadEntity()

	timer.Simple(0.05, function()
		if not IsValid(Entity) then return end

		for Source, Data in pairs(Sources) do
			local Filter = Data.Filter

			Filter[#Filter + 1] = Entity

			if Source.UpdateFilter then
				Source:UpdateFilter(Filter)
			end
		end
	end)
end)

hook.Add("Initialize", "ACF Wire FLIR Compatibility", function()
	if FLIR then
		local FlareMat = Material("sprites/orangeflare1")
		local LaserMat = Material("cable/redlaser")
		local Lasers = ACF.ActiveLasers

		hook.Add("PostDrawOpaqueRenderables", "ACF Active Lasers", function()
			if not FLIR.enabled then return end

			for _, Data in pairs(Lasers) do
				render.SetMaterial(LaserMat)
				render.DrawBeam(Data.Origin, Data.HitPos, 10, 0, 0)

				render.SetMaterial(FlareMat)
				render.DrawSprite(Data.HitPos, 100, 100, Color(255, 255, 255))
			end
		end)
	end

	hook.Remove("Initialize", "ACF Wire FLIR Compatibility")
end)
