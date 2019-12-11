
   
 /*--------------------------------------------------------- 
    Initializes the effect. The data is a table of data  
    which was passed from the server. 
 ---------------------------------------------------------*/ 
 function EFFECT:Init( data ) 
	
	local Origin = data:GetOrigin()
	local Direction = data:GetNormal()
	local Scale = data:GetScale()
	local Emitter = ParticleEmitter( Origin )
	
	for i=0, 80*Scale do
		local particle = Emitter:Add( "particles/flamelet"..math.random(1,5) , Origin)
		if (particle) then
			particle:SetVelocity( ( Direction * math.random(500,2000) + VectorRand()*150 ) * Scale ) 
			particle:SetLifeTime( 0 )
			particle:SetDieTime( 0.5 )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 10 )
			particle:SetStartSize( 5 )
			particle:SetEndSize( 15 )
			particle:SetAirResistance( 350 )
			particle:SetColor(255 , 255 , 255 )
		end
	end
		
	for i=0, 20*Scale do
	
		local Debris = Emitter:Add( "effects/fleck_tile"..math.random(1,2), Origin )
		if (Debris) then
			Debris:SetVelocity ( VectorRand() * math.random(400*Scale,600*Scale) )
			Debris:SetLifeTime( 0 )
			Debris:SetDieTime( math.Rand( 2 , 4 )*Scale )
			Debris:SetStartAlpha( 255 )
			Debris:SetEndAlpha( 0 )
			Debris:SetStartSize( 2 )
			Debris:SetEndSize( 2 )
			Debris:SetRoll( math.Rand(0, 360) )
			Debris:SetRollDelta( math.Rand(-0.2, 0.2) )			
			Debris:SetAirResistance( 100 ) 			 
			Debris:SetGravity( Vector( 0, 0, -650 ) ) 			
			Debris:SetColor( 100,80,90 )
		end
	end
	
	for i=0, 20*Scale do
	
		local Embers = Emitter:Add( "particles/flamelet"..math.random(1,5), Origin )
		if (Embers) then
			Embers:SetVelocity ( VectorRand() * math.random(250*Scale,400*Scale) )
			Embers:SetLifeTime( 0 )
			Embers:SetDieTime( math.Rand( 2 , 4 )*Scale )
			Embers:SetStartAlpha( 255 )
			Embers:SetEndAlpha( 0 )
			Embers:SetStartSize( 5 )
			Embers:SetEndSize( 5 )
			Embers:SetRoll( math.Rand(0, 360) )
			Embers:SetRollDelta( math.Rand(-0.2, 0.2) )			
			Embers:SetAirResistance( 100 ) 			 
			Embers:SetGravity( Vector( 0, 0, -650 ) ) 			
			Embers:SetColor( 100,80,90 )
		end
	end

	for i=0, 20*Scale do
	
		local Smoke = Emitter:Add( "particles/smokey", Origin )
		if (Smoke) then
			Smoke:SetVelocity ( VectorRand() * math.random(150*Scale,200*Scale) )
			Smoke:SetLifeTime( 0 )
			Smoke:SetDieTime( math.Rand( 2 , 4 )*Scale )
			Smoke:SetStartAlpha( 150 )
			Smoke:SetEndAlpha( 0 )
			Smoke:SetStartSize( 20 )
			Smoke:SetEndSize( 200 )
			Smoke:SetRoll( math.Rand(0, 360) )
			Smoke:SetRollDelta( math.Rand(-0.2, 0.2) )			
			Smoke:SetAirResistance( 50 ) 			 
			Smoke:SetGravity( Vector( 0, 0, 100 ) ) 			
			Smoke:SetColor( 100,80,90 )
		end
	end

	Emitter:Finish() 
 end 
   
   
/*---------------------------------------------------------
   THINK
---------------------------------------------------------*/
function EFFECT:Think( )
	return false
end

/*---------------------------------------------------------
   Draw the effect
---------------------------------------------------------*/
function EFFECT:Render()

	self.Entity:SetRenderMode( 0 )
	
end

 