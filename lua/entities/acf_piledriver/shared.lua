DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName     = "ACF Piledriver"
ENT.WireDebugName = "ACF Piledriver"
ENT.PluralName    = "ACF Piledrivers"
ENT.IsPiledriver  = true

cleanup.Register("acf_piledriver")

hook.Add("ACF_UpdateRoundData", "ACF Piledriver Ammo", function(Ammo, _, Data)
	if not Ammo.SpikeLength then return end

	Data.MuzzleVel = Ammo.SpikeLength * 0.0254 / engine.TickInterval()
end)
