DEFINE_BASECLASS("acf_base_simple")

ENT.PrintName       = "ACF Sensor Synchronizer"
ENT.Author          = "ACF Team"
ENT.WireDebugName   = "ACF Sensor Synchronizer"
ENT.PluralName      = "ACF Sensor Synchronizers"
ENT.IsACFSensorSync = true
ENT.ACF_Limit       = 2

-- Sensor entities a Synchronizer can link to. Each must implement the sensor interface used in init.lua:
-- Active, ThinkTicks, Damage, SyncSource, DetectContraptions/DetectMissiles/DetectPlayers,
-- GetScanShape, CheckTargetLOS, StopIndependentScanning and ResumeIndependentScanning
ENT.ACF_SensorClasses = { acf_radar = true, acf_irst = true }

local SensorClasses = ENT.ACF_SensorClasses

ACF.Entities.AutoRegister(2026091001, function()
	LINKED_ENTITY_ARRAY_FIELD("Sensors", { AcceptableClasses = SensorClasses })
end, "Sensor Synchronizer", "Sensor Synchronizers")

ENT.ACF_StaticWireOutputs = {
	"Detected (Returns the amount of targets detected across all linked sensors.)",
	"ClosestDistance (Returns the distance in inches of the closest target detected.)",
	"IDs (Returns a list of IDs from all the detected targets.) [ARRAY]",
	"Owner (Returns a list of owner names from all the detected targets.) [ARRAY]",
	"Position (Returns a list of position vectors from all the detected targets.) [ARRAY]",
	"Velocity (Returns a list of velocity vectors from all the detected targets.) [ARRAY]",
	"Distance (Returns a list of distances from all the detected targets.) [ARRAY]",
	"Size (Returns a list of diameters, in inches, of all the detected targets.) [ARRAY]",
	"Type (Returns a list of target types for all detected targets.) [ARRAY]",
	"Sensor (Returns a list of the linked sensor entities that detected each target, matching the other arrays by index.) [ARRAY]",
	"Linked Sensors (Returns the amount of currently linked sensors.)",
	"Clk (Returns engine.TickCount at the moment of this synchronizer's last batch update.)",
	"Entity (The synchronizer itself.) [ENTITY]",
}

cleanup.Register("acf_sensorsync")
