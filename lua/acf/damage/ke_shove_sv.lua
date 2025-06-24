local hook        = hook
local ACF         = ACF
local Clock       = ACF.Utilities.Clock
local Contraption = ACF.Contraption


function ACF.KEShove(Target, Pos, Vec, KE)
	if not IsValid(Target) then return end
	if Target.ACF_Killed then return end

	if not hook.Run("ACF_OnPushEntity", Target, Pos, Vec, KE) then return end

	local Ancestor = Target:GetAncestor()
	local Phys = Ancestor:GetPhysicsObject()

	if IsValid(Phys) then
		if not Ancestor.acflastupdatemass or Ancestor.acflastupdatemass + 2 < Clock.CurTime then
			Contraption.CalcMassRatio(Ancestor)
		end

		local Ratio    = Ancestor.acfphystotal / Ancestor.acftotal
		local LocalPos = Ancestor:WorldToLocal(Pos) * Ratio

		if KE ~= KE then
			local ErrorText = "Congratulations, you've just found a bug on ACF. Report this to the developer team.\nAffected entity"
			ErrorNoHaltWithStack(ErrorText, Target, Ancestor)

			return
		end

		Phys:ApplyForceOffset(Vec:GetNormalized() * KE * Ratio, Ancestor:LocalToWorld(LocalPos))
	end
end
