local EFFECT     = "burning_gib_01"
local FIRE_SOUND = "ambient/fire/fire_med_loop1.wav"

PrecacheParticleSystem(EFFECT)

local function StopFire(Entity)
	Entity:StopParticlesNamed(EFFECT)

	local Sound = Entity.ACF_FireSound

	if Sound then
		Sound:Stop()

		Entity.ACF_FireSound = nil
	end
end

local function StartFire(Entity)
	ParticleEffectAttach(EFFECT, PATTACH_ABSORIGIN_FOLLOW, Entity, 0)

	if Entity.ACF_FireSound then return end

	local Sound = CreateSound(Entity, FIRE_SOUND)

	Sound:SetSoundLevel(80)
	Sound:Play()

	Entity.ACF_FireSound = Sound -- Has to stay referenced or the loop gets collected and goes silent
end

hook.Add("EntityNetworkedVarChanged", "ACF Fire Effects", function(Entity, Name, _, Burning)
	if Name ~= "ACF_Burning" then return end

	if Burning then
		StartFire(Entity)
	else
		StopFire(Entity)
	end
end)

hook.Add("EntityRemoved", "ACF Fire Effects", function(Entity)
	if Entity.ACF_FireSound then StopFire(Entity) end
end)
