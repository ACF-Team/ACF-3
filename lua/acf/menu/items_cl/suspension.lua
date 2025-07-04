local ACF = ACF

--- Creates/recreates the menu for this tool
function ACF.CreateSuspensionToolMenu(Panel)
    local Menu = ACF.InitMenuBase(Panel, "SuspensionToolMenu", "acf_reload_suspension_menu")

    -- Handles recreating the menu, useful if you change elements.
    if not IsValid(Menu) then
        Menu = vgui.Create("ACF_Panel")
        Menu.Panel = Panel

        Panel:AddItem(Menu)

        ACF.ArmorMenu = Menu
    else
        Menu:ClearAllTemporal()
        Menu:ClearAll()
    end

    local Reload = Menu:AddButton("Reload Menu")
    Reload:SetTooltip("You can also type 'acf_reload_suspension_menu' in console.")
    function Reload:DoClickInternal()
        RunConsoleCommand("acf_reload_suspension_menu")
    end

    Menu:AddTitle("ACF Suspension Tool")
    Menu:AddLabel("This tool helps create constraints for basic drivetrains.")
    Menu:AddLabel("You can hover over any of these elements to see their description.")
    Menu:AddLabel("This tool is mostly stable, but may need further testing.")

    local GeneralSettings = Menu:AddCollapsible("General Settings", true)

    local MakeSpherical = GeneralSettings:AddCheckBox("Make Spherical", "acf_sus_tool_makespherical")
    MakeSpherical:SetTooltip("If checked, makespherical is applied to the wheels.\nShould have the same affect as the makespherical tool.")

    local DisableCollisions = GeneralSettings:AddCheckBox("Disable Collisions", "acf_sus_tool_disablecollisions")
    DisableCollisions:SetTooltip("If checked, the wheels will not collide with anything else.\nSame thing as doing it via the context menu.")

    -- Spring related
    local SpringType = GeneralSettings:AddComboBox()
    SpringType:AddChoice("Spring Type: Rigid (None)", 1)
    SpringType:AddChoice("Spring Type: Hydraulic", 2)
    SpringType:AddChoice("Spring Type: Elastic", 3)

    local SpringGeneral = GeneralSettings:AddCollapsible("General Spring Settings", true)

    -- Generate spring specific settings
    function SpringType:OnSelect(_, _, Data)
        GetConVar("acf_sus_tool_springtype"):SetInt(Data)
        SpringGeneral:ClearAll()
        if Data ~= 1 then
            local SpringSpecific = SpringGeneral:AddCollapsible("Specific Spring Settings", true)
            if Data == 2 then
                -- Hydraulic Specific
                local InOutSpeedMul = SpringSpecific:AddSlider("In/Out Speed Multiplier", 4, 120)
                InOutSpeedMul:SetConVar("acf_sus_tool_inoutspeedmul")
                InOutSpeedMul:SetTooltip("How fast it changes the length.")
            elseif Data == 3 then
                -- Elastic Specific
                local Elasticity = SpringSpecific:AddSlider("Elasticity", 0, 4000)
                Elasticity:SetConVar("acf_sus_tool_elasticity")
                Elasticity:SetTooltip("Stiffness of the elastic. The larger the number the less the elastic will stretch.")

                local Dampening = SpringSpecific:AddSlider("Damping", 0, 50)
                Dampening:SetConVar("acf_sus_tool_damping")
                Dampening:SetTooltip("How much energy the elastic loses. The larger the number, the less bouncy the elastic.")

                local RelativeDampening = SpringSpecific:AddSlider("Relative Damping", 0, 1)
                RelativeDampening:SetConVar("acf_sus_tool_relativedamping")
                RelativeDampening:SetTooltip("The amount of energy the elastic loses proportional to the relative velocity of the two objects the elastic is attached to.")
            end

            local SpringX = SpringGeneral:AddSlider("Spring X", -100, 100)
            SpringX:SetConVar("acf_sus_tool_springx")

            local SpringY = SpringGeneral:AddSlider("Spring Y", -100, 100)
            SpringY:SetConVar("acf_sus_tool_springy")

            local SpringZ = SpringGeneral:AddSlider("Spring Z", -100, 100)
            SpringZ:SetConVar("acf_sus_tool_springz")

            -- Arm related
            local ArmType = SpringGeneral:AddComboBox()
            ArmType:AddChoice("Arm Type: Forward Lever", 1)
            ArmType:AddChoice("Arm Type: Sideways Lever", 2)
            ArmType:AddChoice("Arm Type: Fork", 3)

            function ArmType:OnSelect(_, _, Data)
                GetConVar("acf_sus_tool_armtype"):SetInt(Data)
            end

            ArmType:ChooseOptionID(GetConVar("acf_sus_tool_armtype"):GetInt())

            local ArmX = SpringGeneral:AddSlider("Arm X", -100, 100)
            ArmX:SetConVar("acf_sus_tool_armx")

            local ArmY = SpringGeneral:AddSlider("Arm Y", -100, 100)
            ArmY:SetConVar("acf_sus_tool_army")

            local ArmZ = SpringGeneral:AddSlider("Arm Z", -100, 100)
            ArmZ:SetConVar("acf_sus_tool_armz")

            local LimiterLength = SpringGeneral:AddSlider("Limiter Length", 0, 100)
            LimiterLength:SetConVar("acf_sus_tool_limiterlength")
            LimiterLength:SetTooltip("Limits the distance the wheel can move from its default position")
        end
    end

    SpringType:ChooseOptionID(GetConVar("acf_sus_tool_springtype"):GetInt())

    local Create = Menu:AddButton("Create Drivetrain")
    Create:SetTooltip("Creates a new drivetrain with the selected entitites.")

    function Create:DoClickInternal()
        net.Start("ACF_Sus_Tool")
        net.WriteString("Create")
        net.SendToServer()
    end

    local Clear = Menu:AddButton("Clear Drivetrain")
    Clear:SetTooltip("Clears all constraints on selected entities.")

    function Clear:DoClickInternal()
        net.Start("ACF_Sus_Tool")
        net.WriteString("Clear")
        net.SendToServer()
    end

    local SettingsVisual = Menu:AddCollapsible("Visual Settings", true)
    SettingsVisual:AddCheckBox("Show Wheel Info", "acf_sus_tool_showwheelinfo")
    SettingsVisual:AddCheckBox("Show Arms Info", "acf_sus_tool_showarminfo")
    SettingsVisual:AddCheckBox("Show Springs Info", "acf_sus_tool_showspringinfo")

    local InstructionsGeneral = Menu:AddCollapsible("Instructions", true)
    InstructionsGeneral:AddLabel("1. Select the baseplate with SHIFT + RMB")
    InstructionsGeneral:AddLabel("2. Select all the wheels you want attached to your baseplate with RMB.")
    InstructionsGeneral:AddLabel("3. (Optional) Selecting a new plate with SHIFT + RMB will select a new steer plate.\nWheels selected afterwards will belong to this new plate.")
    InstructionsGeneral:AddLabel("4. (Optional) For hydraulic suspension, select the control plate with CTRL + RMB.")
    InstructionsGeneral:AddLabel("(Optional) If applicable, press the cleanup button in the menu to remove old constraints.")
    InstructionsGeneral:AddLabel("(Optional) If applicable, press the create button in the menu to create the suspension.")
end