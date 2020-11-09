-- Traceline doesn't behave properly against entities moving towards the origin of the trace.
-- For whatever reason, tracehull doesn't has this problem (Or at least it isn't as consistent).
-- In terms of performance, both functions are almost the same.

-- This should fix the issue on every single addon that has this problem when using tracelines.
-- Hopefully this won't cause any kind of conflicts with another addon.
-- Thank you based Dakota.

-- Note from Dakota: Check impacts on wedge joints, especially if they are visclipped. Hitnormal might be fucked in some cases.
-- Note from the wiki: This function may not always give desired results clientside due to certain physics mechanisms not existing on the client.

local Hull = util.TraceHull
local Zero = Vector()

function util.TraceLine(TraceData, ...)
	if TraceData then
		TraceData.mins = -Zero -- I wonder if negating it is necessary at all.
		TraceData.maxs = Zero
	end

	return Hull(TraceData, ...)
end
