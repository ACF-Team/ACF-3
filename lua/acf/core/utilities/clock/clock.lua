local Clock = ACF.Utilities.Clock

-- This is weird, but in theory, we can get a pseudo-double-curtime with this, suitable for clock operations.
-- I mean in theory, gpGlobals curtime is calculated this way... right?
local function DoubleCurtime()
	return engine.TickCount() * engine.TickInterval()
end

Clock.DeltaTime = engine.TickInterval()
Clock.CurTime   = DoubleCurtime()

hook.Add("Think", "ACF Clock Update", function()
	local Now   = DoubleCurtime()
	local Delta = Now - Clock.CurTime

	Clock.DeltaTime = Delta
	Clock.CurTime   = Now

	hook.Run("ACF_OnTick", New, Delta)
end)
