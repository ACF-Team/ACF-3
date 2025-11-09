DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName       = "ACF Piledriver"
ENT.WireDebugName   = "ACF Piledriver"
ENT.PluralName      = "ACF Piledrivers"
ENT.IsACFPiledriver = true

cleanup.Register("acf_piledriver")

ENT.ACF_UserVars = {
	["Weapon"]   = {
		Type       = "GroupClass",
		ClassName  = "Piledrivers",
		Default    = "PD",
		ClientData = true
	},
	["Caliber"]  = {
		Type       = "Number",
		Min        = function(Ctx)
			return Ctx:ResolveClientData("Weapon").Caliber.Min
		end,
		Max        = function(Ctx)
			return Ctx:ResolveClientData("Weapon").Caliber.Max
		end,
		Default    = function(Ctx)
			return Ctx:ResolveClientData("Weapon").Caliber.Base
		end,
		Decimals   = 2,
		ClientData = true
	}
}

ENT.ACF_WireInputs = {
	"Fire (Attempts to fire the piledriver.)",
}

ENT.ACF_WireOutputs = {
	"Ready (Returns 1 if the piledriver can be fired.)",
	"Status (Returns the current state of the piledriver.) [STRING]",
	"Shots Left (Returns the amount of charges available to fire.)",
	"Reload Time (Returns the charge rate of the piledriver.)",
	"Rate of Fire (Returns how many charges per minute can be fired.)",
	"Spike Mass (Returns the mass in grams of the piledriver's spike.)",
	"Muzzle Velocity (Returns the speed in m/s at which the spike is fired.)",
	"Entity (The piledriver itself.) [ENTITY]",
}

hook.Add("ACF_OnUpdateRound", "ACF Piledriver Ammo", function(Ammo, _, Data, GUIData)
	if not Ammo.SpikeLength then return end

	local Cavity   = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, Data.ProjLength)
	local ExpRatio = Cavity / GUIData.ProjVolume

	Data.MuzzleVel  = Ammo.SpikeLength * 0.01 / engine.TickInterval()
	Data.CavVol     = Cavity
	Data.ProjMass   = (Data.ProjArea * Data.ProjLength - Cavity) * ACF.SteelDensity
	Data.ShovePower = 0.2 + ExpRatio
	Data.Diameter   = Data.Caliber + ExpRatio * Data.ProjLength
	Data.DragCoef   = Data.ProjArea * 0.0001 / Data.ProjMass
	Data.CartMass   = Data.PropMass + Data.ProjMass
end)