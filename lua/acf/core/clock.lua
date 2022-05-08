-- This may seem silly but calling CurTime many times ends up being CPU intensive

local clock = {}

clock.curTime   = CurTime()
clock.deltaTime = engine.TickInterval()

hook.Add("Think", "ACF.clock", function()
	local theTime = CurTime()

	clock.deltaTime = theTime - clock.curTime
	clock.curTime   = CurTime()
end)

ACF.clock = clock