local traceOut  = {}
local traceData = { mins = Vector(), maxs = Vector(), output = traceOut }
local trace     = SERVER and util.TraceHull or util.TraceLine

local hitClip

do -- Visual clip compatibility
	local function checkClip(entity, clip, Center, pos)
		if clip.physics then return false end -- Physical clips will be ignored, we can't hit them anyway

		local normal = entity:LocalToWorldAngles(clip.n or clip[1]):Forward()
		local origin = Center + normal * (clip.d or clip[2])

		return normal:Dot((origin - pos):GetNormalized()) > 0
	end

	function ACF.CheckClips(ent, pos)
		if not IsValid(ent) then return false end
		if not ent.ClipData then return false end -- Doesn't have clips
		if ent:GetClass() ~= "prop_physics" then return false end -- Only care about props
		if SERVER and not ent:GetPhysicsObject():GetVolume() then return false end -- Spherical collisions applied to it

		-- Compatibility with Proper Clipping tool: https://github.com/DaDamRival/proper_clipping
		-- The bounding box center will change if the entity is physically clipped
		-- That's why we'll use the original OBBCenter that was stored on the entity
		local center = ent:LocalToWorld(ent.OBBCenterOrg or ent:OBBCenter())

		for _, clip in ipairs(ent.ClipData) do
			if checkClip(ent, clip, center, pos) then return true end
		end

		return false
	end

	hitClip = ACF.CheckClips
end

do -- ACF.trace
	-- Automatically filters out and retries when hitting a clipped portion of a prop
	-- Does NOT modify the original filter

	local function doRecursiveTrace()
		trace(traceData)

		if traceOut.HitNonWorld and hitClip(traceOut.entity, traceOut.HitPos) then
			traceData.filter[#traceData.filter + 1] = traceOut.entity

			doRecursiveTrace()
		end
	end

	function ACF.trace(traceData)
		traceData.output = traceOut

		trace(traceData)

		if traceOut.HitNonWorld and hitClip(traceOut.entity, traceOut.HitPos) then
			traceData.originalFilter = traceData.filter
			traceData.filter[1]      = traceOut.entity

			doRecursiveTrace()

			traceData.filter         = traceData.originalFilter
			traceData.originalFilter = nil
		end

		return traceOut
	end
end
