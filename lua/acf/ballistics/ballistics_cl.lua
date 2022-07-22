local ACF    = ACF
local Yellow = Color(255, 255, 0)

ACF.BulletEffect = ACF.BulletEffect or {}

local function BulletFlight(Bullet, DeltaTime)
	local Drag       = Bullet.SimFlight:GetNormalized() *  (Bullet.DragCoef * Bullet.SimFlight:LengthSqr()) / ACF.DragDiv
	local Correction = 0.5 * (Bullet.Accel - Drag) * DeltaTime -- Double integrates constant acceleration for better positional accuracy

	Bullet.SimPosLast = Bullet.SimPos
	Bullet.SimPos     = Bullet.SimPos + ACF.Scale * DeltaTime * (Bullet.SimFlight + Correction) -- Calculates the next shell position
	Bullet.SimFlight  = Bullet.SimFlight + (Bullet.Accel - Drag) * DeltaTime -- Calculates the next shell vector

	if IsValid(Bullet.Effect) then
		Bullet.Effect:ApplyMovement(Bullet)
	end

	debugoverlay.Line(Bullet.SimPosLast, Bullet.SimPos, 15, Yellow)
end

hook.Add("ACF_OnClock", "ACF_ManageBulletEffects", function(_, DeltaTime)
	for _, Bullet in pairs(ACF.BulletEffect) do
		BulletFlight(Bullet, DeltaTime)
	end
end)
