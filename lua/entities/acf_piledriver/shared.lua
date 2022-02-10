DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName       = "ACF Piledriver"
ENT.WireDebugName   = "ACF Piledriver"
ENT.PluralName      = "ACF Piledrivers"
ENT.IsACFPiledriver = true

cleanup.Register("acf_piledriver")

hook.Add("ACF_UpdateRoundData", "ACF Piledriver Ammo", function(Ammo, _, Data, GUIData)
	if not Ammo.SpikeLength then return end

	local Cavity   = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, Data.ProjLength)
	local ExpRatio = Cavity / GUIData.ProjVolume

	Data.MuzzleVel  = Ammo.SpikeLength * 0.01 / engine.TickInterval()
	Data.CavVol     = Cavity
	Data.ProjMass   = (Data.ProjArea * Data.ProjLength - Cavity) * 0.0079
	Data.ShovePower = 0.2 + ExpRatio
	Data.Diameter   = Data.Caliber + ExpRatio * Data.ProjLength
	Data.DragCoef   = Data.ProjArea * 0.0001 / Data.ProjMass
	Data.CartMass   = Data.PropMass + Data.ProjMass
end)
