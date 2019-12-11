ACF.BulletEffect = {}

function ACF_ManageBulletEffects()
	
	for Index,Bullet in pairs(ACF.BulletEffect) do
		ACF_SimBulletFlight( Bullet, Index )			--This is the bullet entry in the table, the omnipresent Index var refers to this
	end
	
end
hook.Add("Think", "ACF_ManageBulletEffects", ACF_ManageBulletEffects)

function ACF_SimBulletFlight( Bullet, Index )

	--local DeltaTime = ACF.CurTime - Bullet.LastThink
	local DeltaTime = CurTime() - Bullet.LastThink --intentionally not using cached curtime value
	
	local Drag = Bullet.SimFlight:GetNormalized() * (Bullet.DragCoef * Bullet.SimFlight:Length()^2)/ACF.DragDiv
	--print(Drag)
	--debugoverlay.Cross(Bullet.SimPos,3,15,Color(255,255,255,32), true)
	Bullet.SimPosLast = Bullet.SimPos
	Bullet.SimPos = Bullet.SimPos + (Bullet.SimFlight * ACF.VelScale * DeltaTime)		--Calculates the next shell position
	Bullet.SimFlight = Bullet.SimFlight + (Bullet.Accel - Drag)*DeltaTime			--Calculates the next shell vector
	
	if Bullet and Bullet.Effect:IsValid() then
		Bullet.Effect:ApplyMovement( Bullet )
	end
	Bullet.LastThink = CurTime() --ACF.CurTime --intentionally not using cached curtime value
	
end
