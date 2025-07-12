local ACF    = ACF
local Debug	 = ACF.Debug
local Yellow = Color(255, 255, 0)
local Teal   = Color(0, 255, 255)

ACF.BulletEffect = ACF.BulletEffect or {}

local function BulletFlight(Bullet, DeltaTime)
	local Drag       = Bullet.SimFlight:GetNormalized() *  (Bullet.DragCoef * Bullet.SimFlight:LengthSqr()) / ACF.DragDiv
	local Correction = 0.5 * (Bullet.Accel - Drag) * DeltaTime -- Double integrates constant acceleration for better positional accuracy

	Bullet.SimPosLast = Bullet.SimPos
	Bullet.SimPos     = Bullet.SimPos + ACF.Scale * DeltaTime * (Bullet.SimFlight + Correction) -- Calculates the next shell position
	Bullet.SimFlight  = Bullet.SimFlight + (Bullet.Accel - Drag) * DeltaTime -- Calculates the next shell vector

	if IsValid(Bullet.Effect) then
		-- Determine if the bullet should pause until further update from the server.
		-- Assume that a valid clientside trace hit means that the server will let us know what happened
		-- so in the meantime we should stop trying to draw the effect.
		local Trace = ACF.trace {
			start = Bullet.SimPosLast,
			endpos = Bullet.SimPos,
			filter = function(x) return x:GetClass() ~= "acf_gun" end
		}

		Debug.Line(Bullet.SimPosLast, Trace.HitPos, 15, Teal)
		Debug.Line(Trace.HitPos, Bullet.SimPos, 15, Yellow)

		if Trace.Hit then
			Bullet.Effect.DrawEffect = false
		else
			Bullet.Effect:ApplyMovement(Bullet)
		end
	end
end

hook.Add("ACF_OnTick", "ACF_ManageBulletEffects", function(_, DeltaTime)
	for _, Bullet in pairs(ACF.BulletEffect) do
		BulletFlight(Bullet, DeltaTime)
	end
end)
