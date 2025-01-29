local Storyboard = Ponder.API.NewStoryboard("acf", "turrets", "turret-basics")
Storyboard:WithName("acf.storyboards.turrets.turret_basics")
Storyboard:WithIndexOrder(1)
Storyboard:WithModelIcon("models/acf/core/t_ring.mdl")
Storyboard:WithDescription(language.GetPhrase("acf.storyboards.turrets.turret_basics.desc"))

-- Explain the most fundamental parts of the turret
local Chapter1	= Storyboard:Chapter("#acf.storyboards.turrets.turret_basics.chapter1")
Chapter1:AddInstruction("PlaceModel", {	-- Ring
	Name	= "TurretRing",
	IdentifyAs	= "acf_turret",
	Model	= "models/acf/core/t_ring.mdl",
	Position	= Vector(0, 0, 10),
	ComeFrom	= Vector(0, 0, 32)
})
Chapter1:AddInstruction("Delay", {Length = 0.5})
Chapter1:AddInstruction("ShowText", {
	Name	= "Explain_HRing",
	Text	= language.GetPhrase("acf.storyboards.turrets.turret_basics.chapter1.explain_hring"),
	Time	= 0,
	Position	= Vector(12, 12, 0)
})
Chapter1:AddInstruction("TransformModel", {Target = "TurretRing", Rotation = Angle(0, 45, 0), Length = 0.5})
Chapter1:AddInstruction("Delay", {Length = 0.6})
Chapter1:AddInstruction("TransformModel", {Target = "TurretRing", Rotation = Angle(0, -45, 0), Length = 0.75})
Chapter1:AddInstruction("Delay", {Length = 0.85})
Chapter1:AddInstruction("TransformModel", {Target = "TurretRing", Rotation = Angle(0, 0, 0), Length = 0.75})
Chapter1:AddInstruction("Delay", {Length = 0.65})
Chapter1:AddInstruction("HideText", {Name = "Explain_HRing", Length = 0.5})
Chapter1:AddInstruction("Delay", {Length = 0.5})

Chapter1:AddInstruction("PlaceModel", {	-- Trunnion
	Name	= "TurretTrun",
	IdentifyAs	= "acf_turret",
	Model	= "models/acf/core/t_trun.mdl",
	Position	= Vector(36, 0, 16),
	ComeFrom	= Vector(0, 0, 32),
	ParentTo	= "TurretRing"
})
Chapter1:AddInstruction("Delay", {Length = 0.5})
Chapter1:AddInstruction("ShowText", {
	Name	= "Explain_VRing",
	Text	= language.GetPhrase("acf.storyboards.turrets.turret_basics.chapter1.explain_vring"),
	Time	= 0,
	Position	= Vector(36, 0, 26)
})
Chapter1:AddInstruction("TransformModel", {Target = "TurretTrun", Rotation = Angle(45, 0, 0), Length = 0.5})
Chapter1:AddInstruction("Delay", {Length = 0.6})
Chapter1:AddInstruction("TransformModel", {Target = "TurretTrun", Rotation = Angle(-45, 0, 0), Length = 0.75})
Chapter1:AddInstruction("Delay", {Length = 0.85})
Chapter1:AddInstruction("TransformModel", {Target = "TurretTrun", Rotation = Angle(0, 0, 0), Length = 0.75})
Chapter1:AddInstruction("Delay", {Length = 0.65})
Chapter1:AddInstruction("HideText", {Name = "Explain_VRing", Length = 0.5})
Chapter1:AddInstruction("Delay", {Length = 0.5})
Chapter1:AddInstruction("ShowText", {
	Name	= "Explain_Connections",
	Text	= language.GetPhrase("acf.storyboards.turrets.turret_basics.chapter1.explain_connections"),
	Time	= 0,
	Position	= Vector(12, 12, 0)
})
Chapter1:AddInstruction("Delay", {Length = 3})
Chapter1:AddInstruction("HideText", {Name = "Explain_Connections", Length = 0.5})

-- Explain motors
local Chapter2 = Storyboard:Chapter("#acf.storyboards.turrets.turret_basics.chapter2")
Chapter2:AddInstruction("PlaceModel", {	-- Horizontal motor
	Name	= "TurretHMotor",
	IdentifyAs	= "acf_turret_motor",
	Model	= "models/acf/core/t_drive_h.mdl",
	Position	= Vector(-26, 26, 0),
	ComeFrom	= Vector(0, 0, 32),
	ParentTo	= "TurretRing"
})
Chapter2:AddInstruction("Delay", {Length = 0.5})
Chapter2:AddInstruction("ShowText", {
	Name	= "Explain_HMotor",
	Text	= language.GetPhrase("acf.storyboards.turrets.turret_basics.chapter2.explain_hmotor"),
	Time	= 0,
	Position	= Vector(-26, 26, 10)
})
Chapter2:AddInstruction("Delay", {Length = 3})
Chapter2:AddInstruction("HideText", {Name = "Explain_HMotor", Length = 0.5})

Chapter2:AddInstruction("PlaceModel", {	-- Vertical motor
	Name	= "TurretVMotor",
	IdentifyAs	= "acf_turret_motor",
	Model	= "models/acf/core/t_drive_e.mdl",
	Position	= Vector(-4, -24, 0),
	Angles		= Angle(0, 0, 90),
	ComeFrom	= Vector(0, 0, 32),
	ParentTo	= "TurretTrun"
})
Chapter2:AddInstruction("Delay", {Length = 0.5})
Chapter2:AddInstruction("ShowText", {
	Name	= "Explain_EMotor",
	Text	= language.GetPhrase("acf.storyboards.turrets.turret_basics.chapter2.explain_emotor"),
	Time	= 0,
	Position	= Vector(36 - 4, -24, 26)
})
Chapter2:AddInstruction("Delay", {Length = 3})
Chapter2:AddInstruction("HideText", {Name = "Explain_EMotor", Length = 0.5})

Chapter2:AddInstruction("ShowText", {
	Name	= "Explain_MotorDifferences",
	Text	= language.GetPhrase("acf.storyboards.turrets.turret_basics.chapter2.explain_motordiff"),
	Time	= 0,
	Position	= Vector(-26, 26, 10)
})
Chapter2:AddInstruction("Delay", {Length = 4})
Chapter2:AddInstruction("HideText", {Name = "Explain_MotorDifferences", Length = 0.5})

Chapter2:AddInstruction("ShowText", {
	Name	= "Explain_MotorRequirements",
	Text	= language.GetPhrase("acf.storyboards.turrets.turret_basics.chapter2.explain_motorreq"),
	Time	= 0,
	Position	= Vector(12, 12, 0)
})
Chapter2:AddInstruction("Delay", {Length = 4})
Chapter2:AddInstruction("HideText", {Name = "Explain_MotorRequirements", Length = 0.5})

local Chapter3 = Storyboard:Chapter("#acf.storyboards.turrets.turret_basics.chapter3")
Chapter3:AddInstruction("PlaceModel", {	-- Gyroscope (dual)
	Name	= "TurretGyro",
	IdentifyAs	= "acf_turret_gyro",
	Model	= "models/acf/core/t_gyro.mdl",
	Position	= Vector(-26, -26, 8),
	ComeFrom	= Vector(0, 0, 32),
	ParentTo	= "TurretRing"
})
Chapter3:AddInstruction("Delay", {Length = 0.5})
Chapter3:AddInstruction("ShowText", {
	Name	= "Explain_Gyro",
	Text	= language.GetPhrase("acf.storyboards.turrets.turret_basics.chapter3.explain_gyro"),
	Time	= 0,
	Position	= Vector(-26, -26, 18)
})
Chapter3:AddInstruction("Delay", {Length = 4})
Chapter3:AddInstruction("HideText", {Name = "Explain_Gyro", Length = 0.5})

--local Chapter4 = Storyboard:Chapter("#acf.storyboards.turrets.turret_basics.chapter4")


Chapter3:RecommendStoryboard("acf.turrets.turret-parenting")