local ACF   = ACF
local clock = ACF.clock

local deltaTime

ACF.BulletEffect = ACF.BulletEffect or {}

local function BulletFlight(Bullet)
	local Drag       = Bullet.SimFlight:GetNormalized() *  (Bullet.DragCoef * Bullet.SimFlight:LengthSqr()) / ACF.DragDiv
	local Correction = 0.5 * (Bullet.Accel - Drag) * deltaTime -- Double integrates constant acceleration for better positional accuracy

	Bullet.SimPosLast = Bullet.SimPos
	Bullet.SimPos     = Bullet.SimPos + ACF.Scale * deltaTime * (Bullet.SimFlight + Correction) -- Calculates the next shell position
	Bullet.SimFlight  = Bullet.SimFlight + (Bullet.Accel - Drag) * deltaTime -- Calculates the next shell vector

	if IsValid(Bullet.Effect) then
		Bullet.Effect:ApplyMovement(Bullet)
	end

	debugoverlay.Line(Bullet.SimPosLast, Bullet.SimPos, 15, Color(255, 255, 0))
end

hook.Add("Think", "ACF_ManageBulletEffects", function()
	deltaTime = clock.deltaTime

	for Index, Bullet in pairs(ACF.BulletEffect) do
		--This is the bullet entry in the table, the omnipresent Index var refers to this
		BulletFlight(Bullet, Index)
	end
end)