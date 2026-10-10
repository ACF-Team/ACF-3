local Storyboard = Ponder.API.NewStoryboard("acf", "tankextras", "turret_controllers")
Storyboard:WithName("Turret Controllers")
Storyboard:WithModelIcon("models/props_c17/tv_monitor01.mdl")
Storyboard:WithDescription("Learn about Remote and Lightweight turret controllers.")
Storyboard:WithIndexOrder(4)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Remote Turret Controller")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1, Angle = -225, Distance = 1800}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Base", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },
        {Name = "Gunner", IdentifyAs = "Gunner", Model = "models/chairs_playerstart/sitpose.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, -40, 10), ComeFrom = Vector(0, 0, 50), Material = "sprops/sprops_grid_12x12", ParentTo = "Base", },
        {Name = "Controller", IdentifyAs = "Remote Turret Controller", Model = "models/props_c17/tv_monitor01.mdl", Angles = Angle(0, 180, 0), Position = Vector(0, -70, 20), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "Turret", IdentifyAs = "Turret", Model = "models/acf/core/t_ring.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 60, 10), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Normally a gunner must be parented to a light turret, or to a horizontal drive under 250kg, to aim it freely."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A Remote Turret Controller lets a gunner aim a turret it isn't mounted on."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Share a parent with the gunner, sit in front of them with line of sight, then right click the controller and right click the gunner to link."}))

Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {
    Children = {"Controller"},
    Target = "Gunner",
    Easing = math.ease.InOutQuad,
    Length = 2,
}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Then right click the gunner and right click the turret you want them to control."}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {
    Children = {"Gunner"},
    Target = "Turret",
    Easing = math.ease.InOutQuad,
    Length = 2,
}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "You can place up to 2 Remote Turret Controllers per player."}))

local Chapter = Storyboard:Chapter("Lightweight Turret Controller")

Chapter:AddInstruction("RemoveModel", {Name = "Gunner"}):DelayByLength()
Chapter:AddInstruction("RemoveModel", {Name = "Controller"}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Controller", IdentifyAs = "Lightweight Turret Controller", Model = "models/props_lab/powerbox02c.mdl", Angles = Angle(0, 180, 0), Position = Vector(0, 30, 20), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A Lightweight Turret Controller aims a turret without any crew, as long as everything the turret carries, itself included, weighs 300kg or less."}))

Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Place it within 24 units of the turret, then right click it and right click the turret to link."}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {
    Children = {"Controller"},
    Target = "Turret",
    Easing = math.ease.InOutQuad,
    Length = 2,
}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "This is also capped at 2 per player, useful for small machine guns or APS launchers that don't need a dedicated gunner."}))
