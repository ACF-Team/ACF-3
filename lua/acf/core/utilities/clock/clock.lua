local Clock        = ACF.Utilities.Clock
local Run          = hook.Run
local TickCount    = engine.TickCount
local TickInterval = engine.TickInterval

-- This is weird, but in theory, we can get a pseudo-double-curtime with this, suitable for clock operations.
-- I mean in theory, gpGlobals curtime is calculated this way... right?
local function DoubleCurtime()
	return TickCount() * TickInterval()
end

Clock.DeltaTime        = TickInterval()
Clock.CurTime          = CurTime()
Clock.PreciseCurTime   = DoubleCurtime()

hook.Add("Think", "ACF Clock Update", function()
	local Now     = CurTime()
	local DbNow   = DoubleCurtime()
	local Delta   = Now   - Clock.CurTime
	local DbDelta = DbNow - Clock.PreciseCurTime

	Clock.DeltaTime        = Delta
	Clock.PreciseDeltaTime = DbDelta
	Clock.CurTime          = Now
	Clock.PreciseCurTime   = DbNow

	Run("ACF_OnTick", New, Delta)
end)