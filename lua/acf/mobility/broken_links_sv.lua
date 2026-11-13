local ACF         = ACF
local BrokenLinks = ACF.Mobility.BrokenLinks or {}

ACF.Mobility.BrokenLinks = BrokenLinks

-- Mobility links are removed by the clocks of engines and gearboxes once they stretch or bend too far. The source keeps a
-- requirement listing them for a while, so the owner can see what was linked and why it broke after the link is gone.

local EXPIRE = 60 -- Seconds a broken link stays listed, unless it gets relinked first

local function Refresh(Source)
	local Broken = Source.ACF_BrokenLinks

	if not Broken or not next(Broken) then
		Source.ACF_BrokenLinks = nil
		Source:SetRequirement("link_broken", true)

		return
	end

	local Links = {}

	for Target, Entry in pairs(Broken) do
		if IsValid(Target) then
			Links[#Links + 1] = Entry
		else
			Broken[Target] = nil
		end
	end

	if not Links[1] then return Refresh(Source) end

	Source:SetRequirement("link_broken", false, { Links = Links })
end

--- Lists a link the source just lost, positions are local to the entity they belong to.
--- @param Source entity The engine or gearbox the link came out of
--- @param Target entity What it was linked to
--- @param Reason string Why it broke, shown to the owner
--- @param From vector The output position, local to the source
--- @param To vector The input position, local to the target
function BrokenLinks.Add(Source, Target, Reason, From, To)
	if not IsValid(Source) or not Source.SetRequirement then return end

	local Broken = Source.ACF_BrokenLinks or {}
	local Stamp  = CurTime()

	Source.ACF_BrokenLinks = Broken
	Broken[Target] = { Target = Target, Reason = Reason, From = From, To = To, Stamp = Stamp }

	Refresh(Source)

	timer.Simple(EXPIRE, function()
		if not IsValid(Source) then return end

		local Current = Source.ACF_BrokenLinks
		local Entry   = Current and Current[Target]

		if Entry and Entry.Stamp == Stamp then
			Current[Target] = nil

			Refresh(Source)
		end
	end)
end

--- Forgets a broken link, called when the two entities are linked again.
--- @param Source entity
--- @param Target entity
function BrokenLinks.Clear(Source, Target)
	local Broken = Source.ACF_BrokenLinks
	if not (Broken and Broken[Target]) then return end

	Broken[Target] = nil

	Refresh(Source)
end
