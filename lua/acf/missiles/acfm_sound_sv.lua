local ACF = ACF

timer.Simple(1, function()
	local Sounds = ACF.SoundToolSupport

	Sounds.acf_rack = {
		GetSound = function(ent) return { Sound = ent.SoundPath or "" } end,

		SetSound = function(ent, soundData)
			ent.SoundPath = soundData.Sound
			ent:SetNWString("Sound", soundData.Sound)
		end,

		ResetSound = function(ent)
			local setSound = Sounds.acf_rack.SetSound

			setSound(ent, { Sound = ent.DefaultSound or "" })
		end
	}

	Sounds.acf_radar = {
		GetSound = function(ent) return { Sound = ent.SoundPath } end,

		SetSound = function(ent, soundData)
			ent.SoundPath = soundData.Sound
			ent:SetNWString( "Sound", soundData.Sound )
		end,

		ResetSound = function(ent)
			local setSound = Sounds.acf_radar.SetSound

			setSound(ent, { Sound = ent.DefaultSound })
		end
	}
end)
