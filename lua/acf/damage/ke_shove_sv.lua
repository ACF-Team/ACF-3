local hook        = hook
local ACF         = ACF
local Clock       = ACF.Utilities.Clock
local Contraption = ACF.Contraption


function ACF.KEShove(Target, Pos, Vec, KE)
	if not IsValid(Target) then return end

	if hook.Run("ACF_KEShove", Target, Pos, Vec, KE) == false then return end

	local Ancestor = Contraption.GetAncestor(Target)
	local Phys = Ancestor:GetPhysicsObject()

	if IsValid(Phys) then
		if not Ancestor.acflastupdatemass or Ancestor.acflastupdatemass + 2 < Clock.CurTime then
			Contraption.CalcMassRatio(Ancestor)
		end

		local Ratio    = Ancestor.acfphystotal / Ancestor.acftotal
		local LocalPos = Ancestor:WorldToLocal(Pos) * Ratio

		if KE ~= KE then
			print("Congratulations, you've just found a bug on ACF. Report this to the developer team.")
			print("Affected entity", Target, Ancestor)

			debug.Trace()

			return
		end

		Phys:ApplyForceOffset(Vec:GetNormalized() * KE * Ratio, Ancestor:LocalToWorld(LocalPos))
	end
end
