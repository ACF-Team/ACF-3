local ACF   = ACF
local Clock = ACF.Utilities.Clock

local Overrides =
{
	FLR = function(Effect, Bullet)
		local Position = Bullet.SimPos

		if math.abs(Position.x) > 16000 or math.abs(Position.y) > 16000 or Position.z < -16000 then
			Effect.Kill = true

			return
		end

		if Position.z < 16000 then
			Effect:SetPos(Position) --Moving the effect to the calculated position
			Effect:SetAngles(Bullet.SimFlight:Angle())
		end

		if IsValid(Bullet.Tracer) then
			Bullet.Tracer:Finish()
		end

		local Time = Clock.CurTime
		local CutoutTime = Time - 1

		if not Effect.FlareCutout then
			local FlareArea = math.pi * (Bullet.Caliber * 0.5) * (Bullet.Caliber * 0.5)
			local BurnRate = FlareArea * ACF.FlareBurnMultiplier
			local Duration = Bullet.FillerMass / BurnRate
			local Jitter = util.SharedRandom("FlareJitter", 0, 0.4, Effect.CreateTime * 10000)

			CutoutTime = Effect.CreateTime + Duration + Jitter

			if Effect.FlareEffect then
				ACF.RenderLight(Effect.Index, 1024, nil, Position)
			end
		end

		if not Effect.FlareEffect and Time < CutoutTime then
			if not Effect.FlareCutout then
				ParticleEffectAttach( "acfm_flare", PATTACH_ABSORIGIN_FOLLOW, Effect, 0 )
				Effect.FlareEffect = true
			end
		elseif not Effect.FlareCutout and Time >= CutoutTime then
			Effect:StopParticles()
			Effect.FlareCutout = true
		end
	end
}

hook.Add("ACF_OnCreateBulletEffect", "ACF Missiles Custom Effects", function(Effect, BulletData)
	local Custom = Overrides[BulletData.AmmoType]

	if Custom then
		Effect.ApplyMovement = Custom
	end
end)
