DEFINE_BASECLASS("acf_base_simple")

ENT.PrintName      = "ACF Radar Synchronizer"
ENT.Author         = "ACF Team"
ENT.WireDebugName  = "ACF Radar Synchronizer"
ENT.PluralName     = "ACF Radar Synchronizers"
ENT.IsACFRadarSync = true
ENT.ACF_Limit      = 2

ACF.Entities.AutoRegisterV2(function() end, "Radar Synchronizer", "Radar Synchronizers")

ENT.ACF_StaticWireOutputs = {
	"Detected (Returns the amount of targets detected across all linked radars.)",
	"ClosestDistance (Returns the distance in inches of the closest target detected.)",
	"IDs (Returns a list of IDs from all the detected targets.) [ARRAY]",
	"Owner (Returns a list of owner names from all the detected targets.) [ARRAY]",
	"Position (Returns a list of position vectors from all the detected targets.) [ARRAY]",
	"Velocity (Returns a list of velocity vectors from all the detected targets.) [ARRAY]",
	"Distance (Returns a list of distances from all the detected targets.) [ARRAY]",
	"Size (Returns a list of diameters, in inches, of all the detected targets.) [ARRAY]",
	"Type (Returns a list of target types for all detected targets.) [ARRAY]",
	"Sensor (Returns a list of the linked radar entities that detected each target, matching the other arrays by index.) [ARRAY]",
	"Linked Radars (Returns the amount of currently linked radars.)",
	"Clk (Returns engine.TickCount at the moment of this synchronizer's last batch update.)",
	"Entity (The synchronizer itself.) [ENTITY]",
}

cleanup.Register("acf_radarsync")
