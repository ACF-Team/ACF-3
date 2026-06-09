local Clock                       = ACF.Utilities.Clock
local LastBaseplateExplosions     = {}
local TIME_BETWEEN_HE_EXPLOSIONS  = 10

ACF.Classes.DefineClass("ACF.Baseplates.BaseplateType", function()
	function CLASS.BP_PhysicsCollideExplosion(Entity, Data)
		local CanExplode = hook.Run("ACF_PreExplodeBaseplate", Entity)
		if not CanExplode then return end

		local Contraption = Entity:CFW_GetContraption()
		if not Contraption then return end

		if Data.HitEntity:CFW_GetContraption() == Contraption then return end
		if Data.Speed > 1000 then
			local Owner       = Entity:CPPIGetOwner()
			local WillExplode = true

			if IsValid(Owner) then
				local Now         = Clock.CurTime
				local LastTime    = LastBaseplateExplosions[Owner]
				WillExplode = LastTime == nil or (Now - LastTime) > TIME_BETWEEN_HE_EXPLOSIONS
				LastBaseplateExplosions[Owner] = Now
			end

			timer.Simple(0, function()
				local Position = IsValid(Entity) and Entity:GetPos() or nil
				for Player in ACF.PlayersInContraptionIterator(Contraption) do
					Player:Kill()
				end

				for Ent in pairs(Contraption.ents) do
					ACF.HEKill(Ent, Data.HitNormal, Data.Speed * 100, Data.HitPos, nil, true)
				end

				if WillExplode and Position then
					ACF.Damage.explosionEffect(Position, Data.HitNormal, 120)
				end
			end)
		end
	end
end)