--local ACF = ACF
--local Turrets = ACF.Classes.Turrets

-- I will eventually work on this. Eventually.

--[[
Turrets.Register("4-Computer",{
	Name		= "Computers",
	Description	= "Computer capable of calculating the optimal angle to hit a target.\nHas a delay between uses.",
	Entity		= "acf_turret_computer",
	CreateMenu	= ACF.CreateTurretComputerMenu,
	LimitConVar	= {
		Name	= "_acf_turret_computer",
		Amount	= 20,
		Text	= "Maximum number of ACF turret computers a player can create."
	},
})
]]

--[[
		Ballistic computers that should be linked to a gun to gather bulletdata, and have a Calculate input
		When Calculate is triggered, Thinking flag is set so only one run can occur at once

		After calculation is done, output Firing Solution [ANGLE] (global), Flight Time [NUMBER]
	]]
--[[
do	-- Computers


	Turrets.RegisterItem("DIR-BalComp","4-Computer",{
		Name			= "Direct Ballistics Computer",
		Description		= "A component that is capable of calculating the angle required to shoot a weapon to hit a spot within view.\nHas a delay between uses.",
		Model			= "",

		Mass			= 100,

		Delay			= 3, -- Time after finishing before another calculation can run
		MaxThinkTime	= 2, -- After this long the calculation will halt and return early, and return 0 on everything
		ThinkTime		= 0.05,
		CalcError		= 0.25, -- Lee-way in units per 100u of lateral distance
	})

	Turrets.RegisterItem("IND-BalComp","4-Computer",{
		Name			= "Indirect Ballistics Computer",
		Description		= "A component that is capable of calculating the angle required to shoot a weapon to hit a spot out of view.\nHas a delay between uses.",
		Model			= "",

		Mass			= 150,

		Delay			= 5,
		MaxThinkTime	= 7.5,
		ThinkTime		= 0.1,
		CalcError		= 3,
	})
end]]