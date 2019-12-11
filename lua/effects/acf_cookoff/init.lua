
   
 /*--------------------------------------------------------- 
    Initializes the effect. The data is a table of data  
    which was passed from the server. 
 ---------------------------------------------------------*/ 
function EFFECT:Init( data )

	self.Scale = data:GetScale()*5
	self.Entity:SetModel("models/dav0r/hoverball.mdl")
	self.Entity:SetPos( data:GetOrigin() )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetColor( Color(0,0,0,0 ))
	self.Entity:SetRenderMode(RENDERMODE_TRANSALPHA)
	--Msg("Effect Spawned/n")
	
	self.LifeTime = RealTime() + math.random(1, 2)
	self.Emitter = ParticleEmitter( self.Entity:GetPos())
	
	local phys = self.Entity:GetPhysicsObject()
	if( phys && phys:IsValid() )then
		phys:Wake()
		phys:ApplyForceCenter( VectorRand() * math.random( 500 , 800 ) * self.Scale )
	else
		--Msg("Phys invalid/n")
	end
	
end

function EFFECT:Think()

	local Smoke = self.Emitter:Add( "particle/smokesprites_000"..math.random(1,9), self.Entity:GetPos())
	if (Smoke) then
		Smoke:SetVelocity( VectorRand() * math.Rand(20,50) )
		Smoke:SetLifeTime( 0 )
		Smoke:SetDieTime( math.Rand( 2 , 4 ) )
		Smoke:SetStartAlpha( math.random( 20,80 ) )
		Smoke:SetEndAlpha( 0 )
		Smoke:SetStartSize( 4*self.Scale/2 )
		Smoke:SetEndSize( 8*self.Scale/2 )
		Smoke:SetRoll( math.Rand(0, 360) )
		Smoke:SetRollDelta( math.Rand(-0.2, 0.2) )			
		Smoke:SetAirResistance( 50 ) 			 
		Smoke:SetGravity( Vector( math.Rand(0, 0)*self.Scale, math.Rand(0, 0)*self.Scale, 0 ) ) 			
		Smoke:SetColor( 90,90,90 )
	end
	
	local Fire = self.Emitter:Add( "particles/flamelet"..math.random(1,5), self.Entity:GetPos())
	if (Fire) then
		Fire:SetVelocity( VectorRand() * math.Rand(50,100) )
		Fire:SetLifeTime( 0 )
		Fire:SetDieTime( 0.15 )
		Fire:SetStartAlpha( math.random( 100,150 ) )
		Fire:SetEndAlpha( 0 )
		Fire:SetStartSize( 1*self.Scale/2 )
		Fire:SetEndSize( 2*self.Scale/2 )
		Fire:SetRoll( math.Rand(0, 360) )
		Fire:SetRollDelta( math.Rand(-0.2, 0.2) )			
		Fire:SetAirResistance( 100 ) 			 
		Fire:SetGravity( VectorRand()*self.Scale ) 			
		Fire:SetColor( 255,255,255 )
	end
	
	return self.LifeTime > RealTime()
end

function EFFECT:Render()
	self.Entity:DrawModel()
end
 