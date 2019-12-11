
   
 /*--------------------------------------------------------- 
    Initializes the effect. The data is a table of data  
    which was passed from the server. 
 ---------------------------------------------------------*/ 
 function EFFECT:Init( data ) 
	
	self.Origin = data:GetOrigin()
	self.DirVec = data:GetNormal()
	self.Radius = data:GetRadius()
	self.Emitter = ParticleEmitter( self.Origin )
	
 end   
   
/*---------------------------------------------------------
   THINK
---------------------------------------------------------*/
function EFFECT:Think( )

	for i=0, 2*self.Radius do
	
		local Light = self.Emitter:Add( "sprites/light_glow02_add.vmt", self.Origin )
		if (Light) then
			Light:SetVelocity( Normal * math.random( 40,60*self.Radius) + VectorRand() * math.random( 25,50*self.Radius) )
			Light:SetLifeTime( 0 )
			Light:SetDieTime( math.Rand( 1 , 2 )*self.Radius/3  )
			Light:SetStartAlpha( math.Rand( 50, 150 ) )
			Light:SetEndAlpha( 0 )
			Light:SetStartSize( 2.5*self.Scale )
			Light:SetEndSize( 25*self.Radius )
			Light:SetRoll( math.Rand(150, 360) )
			Light:SetRollDelta( math.Rand(-2, 2) )			
			Light:SetAirResistance( 100 ) 			 
			Light:SetGravity( Vector( math.random(-10,10)*self.Radius, math.random(-10,10)*self.Radius, 250 ) ) 			
			Light:SetColor( 170,140,90 )
		end
	
	end
	
end

/*---------------------------------------------------------
   Draw the effect
---------------------------------------------------------*/
function EFFECT:Render()
end

 
