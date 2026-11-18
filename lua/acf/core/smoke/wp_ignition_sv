local ACF = ACF
--burnpeoplealive
timer.Create("ACF WP Player Ignition", 0.1, 0, function()
	local Time = CurTime()

	for _, Cloud in pairs(ACF.SmokeClouds) do
		if Cloud.Type ~= "WP" or Time > Cloud.Start + Cloud.Life then continue end

		local Center, Radius = ACF.GetSmokeCloudState(Cloud, Time)
		local RadiusSqr = Radius * Radius

		for _, Player in ipairs(player.GetAll()) do
			if not Player:Alive() or Player:IsOnFire() then continue end

			local Target = Player:GetPos()

			if Center:DistToSqr(Target) > RadiusSqr then continue end

			local LOS = util.TraceLine({
				start  = Center + Cloud.Normal * 4,
				endpos = Target,
				filter = Player,
				mask   = MASK_SOLID,
			})

			if LOS.Hit then continue end

			Player:Ignite(5)
		end
	end
end)
