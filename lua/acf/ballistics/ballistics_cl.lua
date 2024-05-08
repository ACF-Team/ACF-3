local ACF    = ACF
local Yellow = Color(255, 255, 0)

ACF.BulletEffect = ACF.BulletEffect or {}

local function BulletFlight(Bullet, DeltaTime)
	local Drag       = Bullet.Flight:GetNormalized() *  (Bullet.DragCoef * Bullet.Flight:LengthSqr()) / ACF.DragDiv
	local Correction = 0.5 * (Bullet.Accel - Drag) * DeltaTime -- Double integrates constant acceleration for better positional accuracy

	Bullet.LastPos = Bullet.Pos
	Bullet.Pos     = Bullet.Pos + ACF.Scale * DeltaTime * (Bullet.Flight + Correction) -- Calculates the next shell position
	Bullet.Flight  = Bullet.Flight + (Bullet.Accel - Drag) * DeltaTime -- Calculates the next shell vector

	--if IsValid(Bullet.Effect) then
		--Bullet.Effect:ApplyMovement(Bullet)
	--end

	debugoverlay.Line(Bullet.LastPos, Bullet.Pos, 15, Yellow)
end

hook.Add("ACF_OnClock", "ACF_ManageBulletEffects", function(_, DeltaTime)
	for _, Bullet in pairs(ACF.BulletEffect) do
		BulletFlight(Bullet, DeltaTime)
	end
end)
