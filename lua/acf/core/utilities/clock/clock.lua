local Clock = ACF.Utilities.Clock

Clock.DeltaTime = engine.TickInterval()
Clock.CurTime   = CurTime()

hook.Add("Think", "ACF Clock Update", function()
	local Now   = CurTime()
	local Delta = Now - Clock.CurTime

	Clock.DeltaTime = Delta
	Clock.CurTime   = Now

	hook.Run("ACF_OnClock", New, Delta)
end)
