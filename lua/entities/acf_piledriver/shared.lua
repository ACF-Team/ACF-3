DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName     = "ACF Piledriver"
ENT.WireDebugName = "ACF Piledriver"
ENT.PluralName    = "ACF Piledrivers"
ENT.IsPiledriver  = true

cleanup.Register("acf_piledriver")

hook.Add("ACF_UpdateRoundData", "ACF Piledriver Ammo", function(Ammo, _, Data, GUIData)
	if not Ammo.SpikeLength then return end

	local HollowCavity = GUIData.MaxCavVol * math.min(0.1 + Data.Caliber * 0.01, 1)
	local ExpRatio     = HollowCavity / GUIData.ProjVolume

	Data.MuzzleVel  = Ammo.SpikeLength * 0.01 / engine.TickInterval()
	Data.CavVol     = HollowCavity
	Data.ProjMass   = (Data.ProjArea * Data.ProjLength - HollowCavity) * 0.0079
	Data.ShovePower = 0.2 + ExpRatio * 0.5
	Data.ExpCaliber = Data.Caliber + ExpRatio * Data.ProjLength
	Data.PenArea    = (math.pi * Data.ExpCaliber * 0.5) ^ 2 ^ ACF.PenAreaMod
	Data.DragCoef   = Data.ProjArea * 0.0001 / Data.ProjMass
	Data.CartMass   = Data.PropMass + Data.ProjMass
end)
