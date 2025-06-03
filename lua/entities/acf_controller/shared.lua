DEFINE_BASECLASS("acf_base_simple")

ENT.PrintName     = "ACF Controller"
ENT.WireDebugName = "ACF Controller"
ENT.PluralName    = "ACF Controllers"
ENT.IsACFEntity   = true
ENT.IsACFController = true
ENT.ACF_InvisibleToBallistics = true

cleanup.Register("acf_controller")

ENT.Editable = true
function ENT:SetupDataTables()
	self:NetworkVar( "Bool", "FlipAD", { KeyName = "flipad", Edit = { type = "Bool", order = 10, category = "Miscellaneous" } } )
	self:NetworkVar( "Bool", "DisableAIOCam", { KeyName = "disableaiocam", Edit = { type = "Bool", order = 11, category = "Miscellaneous" } } )
	self:NetworkVar( "Bool", "DisableAIOHUD", { KeyName = "disableaiohud", Edit = { type = "Bool", order = 12, category = "Miscellaneous" } } )
	self:NetworkVar( "Bool", "DisableFiring", { KeyName = "disablefiring", Edit = { type = "Bool", order = 13, category = "Miscellaneous" } } )
	-- self:NetworkVar( "String", "KeyBinds", { KeyName = "keybinds", Edit = { readonly = true, order = 14, category = "Miscellaneous" } } )

	self:NetworkVar( "Float", "ZoomSpeed", { KeyName = "zoomspeed", Edit = { type = "Float", order = 20, category = "Camera Settings", min = 0.001, max = 90 } } )
	self:NetworkVar( "Float", "ZoomMin", { KeyName = "zoommin", Edit = { type = "Float", order = 21, category = "Camera Settings" , min = 0.001, max = 90 } } )
	self:NetworkVar( "Float", "ZoomMax", { KeyName = "zoommax", Edit = { type = "Float", order = 22, category = "Camera Settings" , min = 0.001, max = 90 } } )
	self:NetworkVar( "Float", "SlewMin", { KeyName = "slewmin", Edit = { type = "Float", order = 23, category = "Camera Settings" , min = 0.001, max = 10 } } )
	self:NetworkVar( "Float", "SlewMax", { KeyName = "slewmax", Edit = { type = "Float", order = 23, category = "Camera Settings" , min = 0.001, max = 10 } } )

	self:NetworkVar( "Int", "CamCount", { KeyName = "camcount", Edit = { type = "Int", order = 30, category = "Camera Specific Settings", min = 1, max = 3} } )
	self:NetworkVar( "Vector", "Cam1Offset", { KeyName = "cam1offset", Edit = { type = "Generic", order = 31, category = "Camera Specific Settings"} } )
	self:NetworkVar( "Int", "Cam1Orbit", { KeyName = "cam1orbit", Edit = { type = "Float", order = 32, category = "Camera Specific Settings" , min = 0, max = 400 } } )
	self:NetworkVar( "Vector", "Cam2Offset", { KeyName = "cam2offset", Edit = { type = "Generic", order = 33, category = "Camera Specific Settings"} } )
	self:NetworkVar( "Int", "Cam2Orbit", { KeyName = "cam2orbit", Edit = { type = "Float", order = 34, category = "Camera Specific Settings" , min = 0, max = 400 } } )
	self:NetworkVar( "Vector", "Cam3Offset", { KeyName = "cam3offset", Edit = { type = "Generic", order = 35, category = "Camera Specific Settings"} } )
	self:NetworkVar( "Int", "Cam3Orbit", { KeyName = "cam3orbit", Edit = { type = "Float", order = 36, category = "Camera Specific Settings" , min = 0, max = 400 } } )

	self:NetworkVar( "Int", "HUDType", { KeyName = "hudtype", Edit = { type = "Combo", order = 40, category = "HUD Settings", values = {Minimal = 0, Simple = 1} } } )
	self:NetworkVar( "Float", "HUDScale", { KeyName = "hudscale", Edit = { type = "Float", order = 41, category = "HUD Settings", min = 0, max = 3 } } )
	self:NetworkVar( "Vector", "HUDColor", { KeyName = "hudcolor", Edit = { type = "VectorColor", order = 42, category = "HUD Settings" } } )

	self:NetworkVar( "Int", "ThrottleIdle", { KeyName = "throttleidle", Edit = { type = "Int", order = 60, category = "Drivetrain Settings", min = 0, max = 100 } } )
	self:NetworkVar( "Int", "SpeedUnit", { KeyName = "speedunit", Edit = { type = "Combo", order = 61, category = "Drivetrain Settings", values = {KPH = 0, MPH = 1} } } )
	self:NetworkVar( "Int", "FuelUnit", { KeyName = "fuelunit", Edit = { type = "Combo", order = 62, category = "Drivetrain Settings", values = {L = 0, H = 1} } } )

	self:NetworkVar( "Int", "BrakeEngagement", { KeyName = "brakeengagement", Edit = { type = "Combo", order = 71, category = "Brake Settings", values = {Manual = 0, Automatic = 1} } } )
	self:NetworkVar( "Float", "BrakeStrength", { KeyName = "brakestrength", Edit = { type = "Float", order = 73, category = "Brake Settings", min = 0.001, max = 1000 } } )

	self:NetworkVar( "Float", "ShiftTime", { KeyName = "shifttime", Edit = { type = "Int", order = 80, category = "Shifting Settings", min = 100, max = 3000 } } )
	self:NetworkVar( "Int", "ShiftMinRPM", { KeyName = "shiftminrpm", Edit = { type = "Int", order = 81, category = "Shifting Settings", min = 0, max = 10000 } } )
	self:NetworkVar( "Int", "ShiftMaxRPM", { KeyName = "shiftmaxrpm", Edit = { type = "Int", order = 82, category = "Shifting Settings", min = 0, max = 10000 } } )
end