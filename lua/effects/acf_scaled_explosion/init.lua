
   
 /*--------------------------------------------------------- 
    Initializes the effect. The data is a table of data  
    which was passed from the server. 
 ---------------------------------------------------------*/ 
function EFFECT:Init( data ) 
	
	self.Origin = data:GetOrigin()
	self.DirVec = data:GetNormal()
	self.Radius = math.max(data:GetRadius()/50,1)
	self.Emitter = ParticleEmitter( self.Origin )
	self.ParticleMul = tonumber(LocalPlayer():GetInfo("acf_cl_particlemul")) or 1
	
	local ImpactTr = { }
		ImpactTr.start = self.Origin - self.DirVec*20
		ImpactTr.endpos = self.Origin + self.DirVec*20
	local Impact = util.TraceLine(ImpactTr)					--Trace to see if it will hit anything
	self.Normal = Impact.HitNormal
	
	local GroundTr = { }
		GroundTr.start = self.Origin + Vector(0,0,1)
		GroundTr.endpos = self.Origin - Vector(0,0,1)*self.Radius*20
		GroundTr.mask = 131083
	local Ground = util.TraceLine(GroundTr)				
	
	-- Material Enum
	-- 65  ANTLION
	-- 66 BLOODYFLESH
	-- 67 CONCRETE / NODRAW
	-- 68 DIRT
	-- 70 FLESH
	-- 71 GRATE
	-- 72 ALIENFLESH
	-- 73 CLIP
	-- 76 PLASTIC
	-- 77 METAL
	-- 78 SAND
	-- 79 FOLIAGE
	-- 80 COMPUTER
	-- 83 SLOSH
	-- 84 TILE
	-- 86 VENT
	-- 87 WOOD
	-- 89 GLASS

	local Mat = Impact.MatType
	local SmokeColor = Vector(90,90,90)
	if Impact.HitSky or not Impact.Hit then
		SmokeColor = Vector(90,90,90)
		self:Airburst( SmokeColor )
	elseif Mat == 71 or Mat == 73 or Mat == 77 or Mat == 80 then -- Metal
		SmokeColor = Vector(170,170,170)
		self:Metal( SmokeColor )
	elseif Mat == 68 or Mat == 79 then -- Dirt
		SmokeColor = Vector(100,80,50)
		self:Dirt( SmokeColor )	
	elseif Mat == 78 then -- Sand
		SmokeColor = Vector(100,80,50)
		self:Sand( SmokeColor )
	else -- Nonspecific
		SmokeColor = Vector(90,90,90)
		self:Concrete( SmokeColor )
	end
	
	if Ground.HitWorld then
		self:Shockwave( Ground, SmokeColor )
	end

 end   
 
function EFFECT:Core()
		
	for i=0, 2*self.Radius*self.ParticleMul do
	 
		local Flame = self.Emitter:Add( "particles/flamelet"..math.random(1,5), self.Origin)
		if (Flame) then
			Flame:SetVelocity( VectorRand() * math.random(50,150*self.Radius) )
			Flame:SetLifeTime( 0 )
			Flame:SetDieTime( 0.15 )
			Flame:SetStartAlpha( math.Rand( 50, 255 ) )
			Flame:SetEndAlpha( 0 )
			Flame:SetStartSize( 2.5*self.Radius )
			Flame:SetEndSize( 15*self.Radius )
			Flame:SetRoll( math.random(120, 360) )
			Flame:SetRollDelta( math.Rand(-1, 1) )			
			Flame:SetAirResistance( 300 ) 			 
			Flame:SetGravity( Vector( 0, 0, 4 ) ) 			
			Flame:SetColor( 255,255,255 )
		end
		
	end
	
	for i=0, 4*self.Radius*self.ParticleMul do
	
		local Debris = self.Emitter:Add( "effects/fleck_tile"..math.random(1,2), self.Origin )
		if (Debris) then
			Debris:SetVelocity ( VectorRand() * math.random(150*self.Radius,250*self.Radius) )
			Debris:SetLifeTime( 0 )
			Debris:SetDieTime( math.Rand( 1.5 , 3 )*self.Radius/3 )
			Debris:SetStartAlpha( 255 )
			Debris:SetEndAlpha( 0 )
			Debris:SetStartSize( 1*self.Radius )
			Debris:SetEndSize( 1*self.Radius )
			Debris:SetRoll( math.Rand(0, 360) )
			Debris:SetRollDelta( math.Rand(-3, 3) )			
			Debris:SetAirResistance( 10 ) 			 
			Debris:SetGravity( Vector( 0, 0, -650 ) ) 			
			Debris:SetColor( 120,120,120 )
		end
	end
	
	for i=0, 5*self.Radius*self.ParticleMul do
	
		local Embers = self.Emitter:Add( "particles/flamelet"..math.random(1,5), self.Origin )
		if (Embers) then
			Embers:SetVelocity ( VectorRand() * math.random(70*self.Radius,160*self.Radius) )
			Embers:SetLifeTime( 0 )
			Embers:SetDieTime( math.Rand( 0.3 , 1 )*self.Radius/3 )
			Embers:SetStartAlpha( 255 )
			Embers:SetEndAlpha( 0 )
			Embers:SetStartSize( 1*self.Radius )
			Embers:SetEndSize( 0*self.Radius )
			Embers:SetStartLength( 5*self.Radius )
			Embers:SetEndLength ( 0*self.Radius )
			Embers:SetRoll( math.Rand(0, 360) )
			Embers:SetRollDelta( math.Rand(-0.2, 0.2) )	
			Embers:SetAirResistance( 20 ) 			 
			Embers:SetGravity( Vector( 0, 0, -650 ) ) 			
			Embers:SetColor( 200,200,200 )
		end
	end
	
	for i=0, 2*self.Radius*self.ParticleMul do
		local Whisp = self.Emitter:Add( "particle/smokesprites_000"..math.random(1,9), self.Origin )
			if (Whisp) then
				Whisp:SetVelocity(VectorRand() * math.random( 150,250*self.Radius) )
				Whisp:SetLifeTime( 0 )
				Whisp:SetDieTime( math.Rand( 3 , 5 )*self.Radius/3  )
				Whisp:SetStartAlpha( math.Rand( 20, 50 ) )
				Whisp:SetEndAlpha( 0 )
				Whisp:SetStartSize( 10*self.Radius )
				Whisp:SetEndSize( 80*self.Radius )
				Whisp:SetRoll( math.Rand(150, 360) )
				Whisp:SetRollDelta( math.Rand(-0.2, 0.2) )			
				Whisp:SetAirResistance( 100 ) 			 
				Whisp:SetGravity( Vector( math.random(-5,5)*self.Radius, math.random(-5,5)*self.Radius, 0 ) ) 			
				Whisp:SetColor( 150,150,150 )
			end
	end
	
	if self.Radius*self.ParticleMul > 4 then
		for i=0, 0.5*self.Radius*self.ParticleMul do
			local Cookoff = EffectData()				
				Cookoff:SetOrigin( self.Origin )
				Cookoff:SetScale( self.Radius/6 )
			util.Effect( "ACF_Cookoff", Cookoff )
		end
	end
	sound.Play( "ambient/explosions/explode_5.wav", self.Origin , math.Clamp(self.Radius*10,75,165), math.Clamp(300 - self.Radius*12,15,255))
	sound.Play( "ambient/explosions/explode_4.wav", self.Origin , math.Clamp(self.Radius*10,75,165), math.Clamp(300 - self.Radius*25,15,255))
	
end

function EFFECT:Shockwave( Ground, SmokeColor )

	local Mat = Ground.MatType
	local Radius = (1-Ground.Fraction)*self.Radius
	local Density = 15*Radius
	local Angle = Ground.HitNormal:Angle()
	for i=0, Density*self.ParticleMul do	
		
		Angle:RotateAroundAxis(Angle:Forward(), (360/Density))
		local ShootVector = Angle:Up()
		local Smoke = self.Emitter:Add( "particle/smokesprites_000"..math.random(1,9), Ground.HitPos )
		if (Smoke) then
			Smoke:SetVelocity( ShootVector * math.Rand(5,200*Radius) )
			Smoke:SetLifeTime( 0 )
			Smoke:SetDieTime( math.Rand( 1 , 2 )*Radius /3 )
			Smoke:SetStartAlpha( math.Rand( 50, 120 ) )
			Smoke:SetEndAlpha( 0 )
			Smoke:SetStartSize( 4*Radius )
			Smoke:SetEndSize( 15*Radius )
			Smoke:SetRoll( math.Rand(0, 360) )
			Smoke:SetRollDelta( math.Rand(-0.2, 0.2) )			
			Smoke:SetAirResistance( 200 ) 			 
			Smoke:SetGravity( Vector( math.Rand( -20 , 20 ), math.Rand( -20 , 20 ), math.Rand( 10 , 100 ) ) )			
			Smoke:SetColor( SmokeColor.x,SmokeColor.y,SmokeColor.z )
		end	
	
	end

end

function EFFECT:Metal( SmokeColor )

	self:Core()
	
	for i=0, 3*self.Radius*self.ParticleMul do
	
		local Smoke = self.Emitter:Add( "particle/smokesprites_000"..math.random(1,9), self.Origin )
		if (Smoke) then
			Smoke:SetVelocity( self.Normal * math.random( 50,80*self.Radius) + VectorRand() * math.random( 30,60*self.Radius) )
			Smoke:SetLifeTime( 0 )
			Smoke:SetDieTime( math.Rand( 1 , 2 )*self.Radius/3  )
			Smoke:SetStartAlpha( math.Rand( 50, 150 ) )
			Smoke:SetEndAlpha( 0 )
			Smoke:SetStartSize( 5*self.Radius )
			Smoke:SetEndSize( 30*self.Radius )
			Smoke:SetRoll( math.Rand(150, 360) )
			Smoke:SetRollDelta( math.Rand(-0.2, 0.2) )			
			Smoke:SetAirResistance( 100 ) 			 
			Smoke:SetGravity( Vector( math.random(-5,5)*self.Radius, math.random(-5,5)*self.Radius, -50 ) ) 			
			Smoke:SetColor( SmokeColor.x,SmokeColor.y,SmokeColor.z )
		end
	
	end
	
end

function EFFECT:Concrete( SmokeColor )

	self:Core()
	
	for i=0, 3*self.Radius*self.ParticleMul do
	
		local Smoke = self.Emitter:Add( "particle/smokesprites_000"..math.random(1,9), self.Origin )
		if (Smoke) then
			Smoke:SetVelocity( self.Normal * math.random( 50,80*self.Radius) + VectorRand() * math.random( 30,60*self.Radius) )
			Smoke:SetLifeTime( 0 )
			Smoke:SetDieTime( math.Rand( 1 , 2 )*self.Radius/3  )
			Smoke:SetStartAlpha( math.Rand( 50, 150 ) )
			Smoke:SetEndAlpha( 0 )
			Smoke:SetStartSize( 5*self.Radius )
			Smoke:SetEndSize( 30*self.Radius )
			Smoke:SetRoll( math.Rand(150, 360) )
			Smoke:SetRollDelta( math.Rand(-0.2, 0.2) )			
			Smoke:SetAirResistance( 100 ) 			 
			Smoke:SetGravity( Vector( math.random(-5,5)*self.Radius, math.random(-5,5)*self.Radius, -50 ) ) 			
			Smoke:SetColor(  SmokeColor.x,SmokeColor.y,SmokeColor.z  )
		end
	
	end
	
end

function EFFECT:Dirt( SmokeColor )
	
	self:Core()
	
	for i=0, 3*self.Radius*self.ParticleMul do
	
		local Smoke = self.Emitter:Add( "particle/smokesprites_000"..math.random(1,9), self.Origin )
		if (Smoke) then
			Smoke:SetVelocity( self.Normal * math.random( 50,80*self.Radius) + VectorRand() * math.random( 30,60*self.Radius) )
			Smoke:SetLifeTime( 0 )
			Smoke:SetDieTime( math.Rand( 1 , 2 )*self.Radius/3  )
			Smoke:SetStartAlpha( math.Rand( 50, 150 ) )
			Smoke:SetEndAlpha( 0 )
			Smoke:SetStartSize( 5*self.Radius )
			Smoke:SetEndSize( 30*self.Radius )
			Smoke:SetRoll( math.Rand(150, 360) )
			Smoke:SetRollDelta( math.Rand(-0.2, 0.2) )			
			Smoke:SetAirResistance( 100 ) 			 
			Smoke:SetGravity( Vector( math.random(-5,5)*self.Radius, math.random(-5,5)*self.Radius, -50 ) ) 			
			Smoke:SetColor(  SmokeColor.x,SmokeColor.y,SmokeColor.z  )
		end
	
	end
		
end

function EFFECT:Sand( SmokeColor )
	
	self:Core()
	
	for i=0, 3*self.Radius*self.ParticleMul do
	
		local Smoke = self.Emitter:Add( "particle/smokesprites_000"..math.random(1,9), self.Origin )
		if (Smoke) then
			Smoke:SetVelocity( self.Normal * math.random( 50,80*self.Radius) + VectorRand() * math.random( 30,60*self.Radius) )
			Smoke:SetLifeTime( 0 )
			Smoke:SetDieTime( math.Rand( 1 , 2 )*self.Radius/3  )
			Smoke:SetStartAlpha( math.Rand( 50, 150 ) )
			Smoke:SetEndAlpha( 0 )
			Smoke:SetStartSize( 5*self.Radius )
			Smoke:SetEndSize( 30*self.Radius )
			Smoke:SetRoll( math.Rand(150, 360) )
			Smoke:SetRollDelta( math.Rand(-0.2, 0.2) )			
			Smoke:SetAirResistance( 100 ) 			 
			Smoke:SetGravity( Vector( math.random(-5,5)*self.Radius, math.random(-5,5)*self.Radius, -50 ) ) 			
			Smoke:SetColor(  SmokeColor.x,SmokeColor.y,SmokeColor.z  )
		end
	
	end
		
end

function EFFECT:Airburst( SmokeColor )

	self:Core()
	
	for i=0, 3*self.Radius*self.ParticleMul do
	
		local Smoke = self.Emitter:Add( "particle/smokesprites_000"..math.random(1,9), self.Origin )
		if (Smoke) then
			Smoke:SetVelocity( VectorRand() * math.random( 25,50*self.Radius) )
			Smoke:SetLifeTime( 0 )
			Smoke:SetDieTime( math.Rand( 1 , 2 )*self.Radius/3  )
			Smoke:SetStartAlpha( math.Rand( 50, 150 ) )
			Smoke:SetEndAlpha( 0 )
			Smoke:SetStartSize( 5*self.Radius )
			Smoke:SetEndSize( 30*self.Radius )
			Smoke:SetRoll( math.Rand(150, 360) )
			Smoke:SetRollDelta( math.Rand(-0.2, 0.2) )			
			Smoke:SetAirResistance( 100 ) 			 
			Smoke:SetGravity( Vector( math.random(-5,5)*self.Radius, math.random(-5,5)*self.Radius, -50 ) ) 			
			Smoke:SetColor( SmokeColor.x,SmokeColor.y,SmokeColor.z  )
		end
	
	end
	
	for i=0, 10*self.Radius*self.ParticleMul do
	
		local AirBurst = self.Emitter:Add( "particle/smokesprites_000"..math.random(1,9), self.Origin )
		if (AirBurst) then
			AirBurst:SetVelocity( VectorRand() * math.random( 150,200*self.Radius) )
			AirBurst:SetLifeTime( 0 )
			AirBurst:SetDieTime( math.Rand( 1 , 2 )*self.Radius/3  )
			AirBurst:SetStartAlpha( math.Rand( 100, 255 ) )
			AirBurst:SetEndAlpha( 0 )
			AirBurst:SetStartSize( 6*self.Radius )
			AirBurst:SetEndSize( 35*self.Radius )
			AirBurst:SetRoll( math.Rand(150, 360) )
			AirBurst:SetRollDelta( math.Rand(-0.2, 0.2) )			
			AirBurst:SetAirResistance( 200 ) 			 
			AirBurst:SetGravity( Vector( math.random(-10,10)*self.Radius, math.random(-10,10)*self.Radius, 20 ) ) 			
			AirBurst:SetColor( SmokeColor.x,SmokeColor.y,SmokeColor.z )
		end
	end

end
   
/*---------------------------------------------------------
   THINK
---------------------------------------------------------*/
function EFFECT:Think( )
		
end

/*---------------------------------------------------------
   Draw the effect
---------------------------------------------------------*/
function EFFECT:Render()
end

 
