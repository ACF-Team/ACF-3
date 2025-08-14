-- Purpose: Hooks into some ACF hooks to provide accurate player damage results.

local ACF = ACF

do
	local BlockDamageHook = false

	hook.Add("EntityTakeDamage", "ACF_EntityTakeDamage_BlockDamageInBaseplateSeats", function(Target, _)
		if BlockDamageHook then return end -- to avoid crashes/allow ACF to stop damage for a bit
		if not Target:IsPlayer() then return end
		if not Target:InVehicle() then return end

		local Vehicle = Target:GetVehicle()
		if not IsValid(Vehicle) then return end

		local Contraption = Vehicle:GetContraption()
		if not Contraption then return end

		local Base = Contraption.Base
		if IsValid(Base) and Base:GetClass() == "acf_baseplate" then
			return true -- Block damage, because there's a contraption, with a baseplate, with the acf_baseplate class
		end
	end)

	function ACF.KillPlayer(Victim, Attacker, Inflictor)
		if not IsValid(Victim) then return end
		if not Victim:IsPlayer() then return end

		BlockDamageHook = true do
			local DmgInfo = DamageInfo()
			DmgInfo:SetDamage(Victim:Health())
			DmgInfo:SetDamageType(DMG_GENERIC)
			if IsValid(Attacker) then DmgInfo:SetAttacker(Attacker) end
			if IsValid(Inflictor) then DmgInfo:SetInflictor(Inflictor) end
			Victim:TakeDamageInfo(DmgInfo)
		end BlockDamageHook = false

		-- Last chance... if DmgInfo didn't work, just ensure the player died.
		if Victim:Alive() then
			Victim:Kill()
		end
	end
	-- ACF.KillPlayer(Player(2), Player(3))
end

-- Track ACF damage inflictors
do
	hook.Add("ACF_OnDamageEntity", "ACF_OnDamageEntity_TrackInflictorInfo", function(Entity, _, DmgInfo)
		local Contraption = Entity:GetContraption()
		if not Contraption then return end

		Contraption.ACF_LastDamageTime = CurTime()
		Contraption.ACF_LastDamageAttacker = DmgInfo:GetAttacker()
		Contraption.ACF_LastDamageInflictor = DmgInfo:GetInflictor()
	end)

	hook.Add("CanPlayerEnterVehicle", "ACF_CanPlayerEnterVehicle_BlockEnterVehicleOnDeadContraption", function(Player, Vehicle)
		local Contraption = Vehicle:GetContraption()
		if not Contraption then return end
		local Now = CurTime()

		if Contraption.ACF_AllCrewKilled then
			if (Now - (Contraption.ACF_LastNotifyDeathTime or 0)) > 1 then
				ACF.SendNotify(Player, false, "This contraption is no longer usable.")
				Contraption.ACF_LastNotifyDeathTime = Now
			end
			return false
		end
	end)
end