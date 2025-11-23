ACF.SoundToolSupport = ACF.SoundToolSupport or {}

local Sounds = ACF.SoundToolSupport

Sounds.acf_gun = {
	GetSound = function(Ent)
		return {
			Sound  = Ent.SoundPath,
			Pitch  = Ent.SoundPitch,
			Volume = Ent.SoundVolume
		}
	end,
	SetSound = function(Ent, SoundData)
		Ent.SoundPath   = SoundData.Sound
		Ent.SoundPitch  = SoundData.Pitch
		Ent.SoundVolume = SoundData.Volume

		Ent:SetNWString("Sound", SoundData.Sound)
		Ent:SetNWFloat("SoundPitch", SoundData.Pitch)
		Ent:SetNWFloat("SoundVolume", SoundData.Volume)
	end,
	ResetSound = function(Ent)
		Ent.SoundPath   = Ent.DefaultSound
		Ent.SoundPitch  = 1
		Ent.SoundVolume = 1

		Ent:SetNWString("Sound", Ent.DefaultSound)
		Ent:SetNWFloat("SoundPitch", 1)
		Ent:SetNWFloat("SoundVolume", 1)
	end
}

Sounds.acf_engine = {
	GetSound = function(Ent)
		return {
			Sound  = Ent.SoundPath,
			Pitch  = Ent.SoundPitch,
			Volume = Ent.SoundVolume
		}
	end,
	SetSound = function(Ent, SoundData)
		local Sound = SoundData.Sound:Trim():lower()

		Ent.SoundPath   = Sound
		Ent.SoundPitch  = SoundData.Pitch
		Ent.SoundVolume = SoundData.Volume

		Ent:UpdateSound()
	end,
	ResetSound = function(Ent)
		Ent.SoundPath   = Ent.DefaultSound
		Ent.SoundPitch  = 1
		Ent.SoundVolume = 1

		Ent:UpdateSound()
	end
}

Sounds.acf_gearbox = {
	GetSound = function(Ent)
		return {
			Sound  = Ent.SoundPath,
			Pitch  = Ent.SoundPitch,
			Volume = Ent.SoundVolume,
		}
	end,
	SetSound = function(Ent, SoundData)
		Ent.SoundPath   = SoundData.Sound
		Ent.SoundPitch  = SoundData.Pitch
		Ent.SoundVolume = SoundData.Volume
	end,
	ResetSound = function(Ent)
		Ent.SoundPath   = Ent.DefaultSound
		Ent.SoundPitch  = nil
		Ent.SoundVolume = nil
	end
}

Sounds.acf_piledriver = {
	GetSound = function(Ent)
		return {
			Sound  = Ent.SoundPath or "",
			Pitch  = Ent.SoundPitch or 1,
			Volume = Ent.SoundVolume or 0.5,
		}
	end,
	SetSound = function(Ent, SoundData)
		Ent.SoundPath   = SoundData.Sound
		Ent.SoundPitch  = SoundData.Pitch
		Ent.SoundVolume = SoundData.Volume
	end,
	ResetSound = function(Ent)
		Ent.SoundPath   = nil
		Ent.SoundPitch  = nil
		Ent.SoundVolume = nil
	end
}

Sounds.acf_turret_motor = {
	GetSound = function(Ent)
		return {
			Sound  = Ent.SoundPath or Ent.DefaultSound,
			Pitch  = Ent.SoundPitch or 0.7,
			Volume = Ent.SoundVolume or 0.1,
		}
	end,
	SetSound = function(Ent, SoundData)
		Ent.SoundPath   = SoundData.Sound
		Ent.SoundPitch  = SoundData.Pitch
		Ent.SoundVolume = SoundData.Volume

		if IsValid(Ent.Turret) then Ent.Turret:UpdateSound() end
	end,
	ResetSound = function(Ent)
		Ent.SoundPath   = Ent.DefaultSound
		Ent.SoundPitch  = nil
		Ent.SoundVolume = nil

		if IsValid(Ent.Turret) then Ent.Turret:UpdateSound() end
	end
}

Sounds.acf_waterjet = {
	GetSound = function(Ent)
		return {
			Sound  = Ent:ACF_GetUserVar("SoundPath"),
			Pitch  = Ent:ACF_GetUserVar("SoundPitch"),
			Volume = Ent:ACF_GetUserVar("SoundVolume"),
		}
	end,
	SetSound = function(Ent, SoundData)
		local Sound = SoundData.Sound:Trim():lower()

		Ent:ACF_SetUserVar("SoundPath", Sound)
		Ent:ACF_SetUserVar("SoundPitch", SoundData.Pitch)
		Ent:ACF_SetUserVar("SoundVolume", SoundData.Volume)

		Ent:UpdateSound()
	end,
	ResetSound = function(Ent)
		Ent:ACF_SetUserVar("SoundPath", "ambient/machines/spin_loop.wav")
		Ent:ACF_SetUserVar("SoundPitch", 1)
		Ent:ACF_SetUserVar("SoundVolume", 0.2)

		Ent:UpdateSound()
	end
}