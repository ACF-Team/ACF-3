local ACF = ACF

do -- Visual clip compatibility
	local function CheckClip(Entity, Clip, Center, Pos)
		if Clip.physics then return false end -- Physical clips will be ignored, we can't hit them anyway

		local Normal = Entity:LocalToWorldAngles(Clip.n or Clip[1]):Forward()
		local Origin = Center + Normal * (Clip.d or Clip[2])

		return Normal:Dot((Origin - Pos):GetNormalized()) > 0
	end

	function ACF.CheckClips(Ent, Pos)
		if not IsValid(Ent) then return false end

		local ClipData = Ent.ClipData

		if not ClipData then return false end -- Doesn't have clips
		if Ent:GetClass() ~= "prop_physics" then return false end -- Only care about props
		if SERVER and not Ent:GetPhysicsObject():GetVolume() then return false end -- Spherical collisions applied to it

		-- Compatibility with Proper Clipping tool: https://github.com/DaDamRival/proper_clipping
		-- The bounding box center will change if the entity is physically clipped
		-- That's why we'll use the original OBBCenter that was stored on the entity
		local Center = Ent:LocalToWorld(Ent.OBBCenterOrg or Ent:OBBCenter())

		for _, Clip in ipairs(ClipData) do
			if CheckClip(Ent, Clip, Center, Pos) then return true end
		end

		return false
	end
end

do -- ACF.trace
	-- Automatically filters out and retries when hitting a clipped portion of a prop
	-- Does NOT modify the original filter
	local util = util

	local function DoRecursiveTrace(TraceData)
		local Output = TraceData.output

		util.TraceLine(TraceData)

		if Output.HitNonWorld and ACF.CheckClips(Output.Entity, Output.HitPos) then
			local Filter = TraceData.filter

			Filter[#Filter + 1] = Output.Entity

			DoRecursiveTrace(TraceData)
		end
	end

	local function TestTraceable(Ent)
		local EntTbl = Ent:GetTable()

		if EntTbl._IsSpherical then return true end
		if EntTbl.ACF_InvisibleToTrace then return true end

		if EntTbl.ACF_KillableButIndestructible and EntTbl.ACF and EntTbl.ACF.Health <= 0 then
			return true
		end

		return false
	end

	--- ACF trace function that automatically filters out and retries when hitting a clipped portion of a prop.
	function ACF.trace(TraceData)
		local Original = TraceData.output
		local Output   = {}

		TraceData.output = Output

		util.TraceLine(TraceData)

		-- Check for clips or to filter this entity
		if Output.HitNonWorld and (ACF.GlobalFilter[Output.Entity:GetClass()] or TestTraceable(Output.Entity) or ACF.CheckClips(Output.Entity, Output.HitPos)) then
			local OldFilter = TraceData.filter
			local Filter    = { Output.Entity }

			for _, V in ipairs(OldFilter) do Filter[#Filter + 1] = V end

			TraceData.filter = Filter

			DoRecursiveTrace(TraceData)

			TraceData.filter = OldFilter
		end

		if Original then
			for K in pairs(Original) do Original[K] = nil end
			for K, V in pairs(Output) do Original[K] = V end

			TraceData.output = Original
		end

		return Output
	end
end
