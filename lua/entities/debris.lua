
AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.PrintName = "Debris"

if CLIENT then return end

-- todo: rename this to acf_debris

function ENT:Initialize()
	
	self.Timer = CurTime() + 60
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	
	local phys = self:GetPhysicsObject()
	if IsValid( phys ) then
		phys:Wake()
	end
	
end

function ENT:Think()
	
	if self.Timer < CurTime() then
		self:Remove()
	end
	
	self:NextThink( CurTime() + 60 )
	
	return true
	
end

function ENT:OnTakeDamage( dmginfo )
	
	-- React physically when shot/getting blown
	-- not sure if this is actually necessary
	self:TakePhysicsDamage( dmginfo )
	
end
