local ACF = ACF
local Turrets = ACF.Classes.Turrets

Turrets.Register("3-Gyro",{
	Name		= "Gyroscopes",
	Description	= "Components that are used to augment function of turret drives.",
	Entity		= "acf_turret_gyro",
	CreateMenu	= ACF.CreateTurretGyroMenu,
	LimitConVar	= {
		Name	= "_acf_turret_gyro",
		Amount	= 20,
		Text	= "Maximum number of ACF turret gyros a player can create."
	},
})

do	-- Gyro
	--[[
		Ideally takes some amount of space (big collection of computers but put into one bigger computer model)
		Single-axis should be parented to or share the same parent as the linked turret drive (Can be linked to either turret drive, but only one)
		Dual-axis should be parented to or share the same parent as the horizontal turret drive (MUST be linked to a vertical AND horizontal turret drive, can not mix types)
	]]

	Turrets.RegisterItem("1-Gyro","3-Gyro",{
		Name			= "Single Axis Turret Gyro",
		Description		= "A component that will stabilize one turret drive.\nMust be parented to or share the parent with the linked turret drive.\nMust have a motor linked to the turret drive.",
		Model			= "models/bull/various/gyroscope.mdl",

		Mass			= 75,
		IsDual			= false,
	})

	Turrets.RegisterItem("2-Gyro","3-Gyro",{
		Name			= "Dual Axis Turret Gyro",
		Description		= "A component that will stabilize one vertical and horizontal turret drive.\nMust be parented to or share the parent with the horizontal turret drive.\nEach turret drive must have a motor linked.",
		Model			= "models/kobilica/relay.mdl",

		Mass			= 150,
		IsDual			= true,
	})
end