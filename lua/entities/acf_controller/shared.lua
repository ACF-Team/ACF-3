DEFINE_BASECLASS("acf_base_simple")

ENT.PrintName     = "ACF Controller"
ENT.WireDebugName = "ACF Controller"
ENT.PluralName    = "ACF Controllers"
ENT.IsACFController = true
ENT.ACF_InvisibleToBallistics = true

cleanup.Register("acf_controller")

ENT.Editable = true
function ENT:SetupDataTables()
	self:NetworkVar( "Bool", "DisableAIOCam", { KeyName = "disableaiocam", Edit = { type = "Bool", order = 10, category = "Miscellaneous", tooltip = "Disables the AIO camera" } } )
	self:NetworkVar( "Bool", "DisableAIOHUD", { KeyName = "disableaiohud", Edit = { type = "Bool", order = 11, category = "Miscellaneous", tooltip = "Disables rendering AIO HUD" } } )
	self:NetworkVar( "Bool", "DisableFiring", { KeyName = "disablefiring", Edit = { type = "Bool", order = 12, category = "Miscellaneous", tooltip = "Disables the AIO's control of your guns" } } )
	self:NetworkVar( "Bool", "DisableAmmoSelect", { KeyName = "disableammoselect", Edit = { type = "Bool", order = 13, category = "Miscellaneous", tooltip = "Disables the AIO ammo selector" } } )
	self:NetworkVar( "Bool", "FlipAD", { KeyName = "flipad", Edit = { type = "Bool", order = 14, category = "Miscellaneous", tooltip = "Flips A and D for steering" } } )
	self:NetworkVar( "Bool", "ThrottleIgnoresAD", { KeyName = "throttleignoresad", Edit = { type = "Bool", order = 15, category = "Miscellaneous", tooltip = "Useful for cars if you want to steer without power" } } )
	self:NetworkVar( "Bool", "ForceCarSteering", { KeyName = "forceawd", Edit = { type = "Bool", order = 16, category = "Miscellaneous", tooltip = "Override to consider mobility as all wheel drive"  } } )
	self:NetworkVar( "Float", "ReloadAngle", { KeyName = "reloadangle", Edit = { type = "Float", order = 17, category = "Miscellaneous", min = -30, max = 30, tooltip = "If nonzero, Elevates the primary weapon to this angle when loading" } } )
	self:NetworkVar( "Float", "SmokeFuse", { KeyName = "smokefuse", Edit = { type = "Float", order = 18, category = "Miscellaneous", min = 0, max = 1, tooltip = "IF nonzero, airburst fuse time in seconds for smoke launchers" } } )
	self:NetworkVar( "Float", "FireDelay", { KeyName = "firedelay", Edit = { type = "Float", order = 19, category = "Miscellaneous", min = 0, max = 5, tooltip = "Fallback fire delay if non can be found (e.g. missiles)" } } )

	self:NetworkVar( "Float", "ZoomSpeed", { KeyName = "zoomspeed", Edit = { type = "Float", order = 20, category = "Camera Settings", min = 0.001, max = 90, tooltip = "FOV zoom rate with scroll"  } } )
	self:NetworkVar( "Float", "ZoomMin", { KeyName = "zoommin", Edit = { type = "Float", order = 21, category = "Camera Settings" , min = 0.001, max = 90, tooltip = "FOV when zoomed in (closer to 0)"  } } )
	self:NetworkVar( "Float", "ZoomMax", { KeyName = "zoommax", Edit = { type = "Float", order = 22, category = "Camera Settings" , min = 0.001, max = 90, tooltip = "FOV when zoomed out (closer to 90)"  } } )
	self:NetworkVar( "Float", "SlewMin", { KeyName = "slewmin", Edit = { type = "Float", order = 23, category = "Camera Settings" , min = 0.001, max = 10, tooltip = "Camera rotation rate when zoomed in"  } } )
	self:NetworkVar( "Float", "SlewMax", { KeyName = "slewmax", Edit = { type = "Float", order = 23, category = "Camera Settings" , min = 0.001, max = 10, tooltip = "Camera rotation rate when zoomed out"  } } )

	self:NetworkVar( "Int", "CamCount", { KeyName = "camcount", Edit = { type = "Int", order = 30, category = "Camera Specific Settings", min = 1, max = 3, tooltip = "Number of cameras to use" } } )
	self:NetworkVar( "Vector", "Cam1Offset", { KeyName = "cam1offset", Edit = { type = "Generic", order = 31, category = "Camera Specific Settings", tooltip = "Offset for first camera" } } )
	self:NetworkVar( "Int", "Cam1Orbit", { KeyName = "cam1orbit", Edit = { type = "Float", order = 32, category = "Camera Specific Settings" , min = 0, max = 400, tooltip = "Orbit distance for first camera" } } )
	self:NetworkVar( "Vector", "Cam2Offset", { KeyName = "cam2offset", Edit = { type = "Generic", order = 33, category = "Camera Specific Settings", tooltip = "Offset for second camera" } } )
	self:NetworkVar( "Int", "Cam2Orbit", { KeyName = "cam2orbit", Edit = { type = "Float", order = 34, category = "Camera Specific Settings" , min = 0, max = 400, tooltip = "Orbit distance for second camera" } } )
	self:NetworkVar( "Vector", "Cam3Offset", { KeyName = "cam3offset", Edit = { type = "Generic", order = 35, category = "Camera Specific Settings", tooltip = "Offset for third camera" } } )
	self:NetworkVar( "Int", "Cam3Orbit", { KeyName = "cam3orbit", Edit = { type = "Float", order = 36, category = "Camera Specific Settings" , min = 0, max = 400, tooltip = "Orbit distance for third camera" } } )
	self:NetworkVar( "Int", "HUDType", { KeyName = "hudtype", Edit = { type = "Combo", order = 40, category = "HUD Settings", values = {Minimal = 0, Simple = 1}, tooltip = "HUD style" } } )
	self:NetworkVar( "Float", "HUDScale", { KeyName = "hudscale", Edit = { type = "Float", order = 41, category = "HUD Settings", min = 0, max = 3, tooltip = "HUD scale" } } )
	self:NetworkVar( "Vector", "HUDColor", { KeyName = "hudcolor", Edit = { type = "VectorColor", order = 42, category = "HUD Settings", tooltip = "HUD color" } } )

	self:NetworkVar( "Int", "ThrottleIdle", { KeyName = "throttleidle", Edit = { type = "Int", order = 60, category = "Drivetrain Settings", min = 0, max = 100, tooltip = "If nonzero, engines are throttled to this value forever" } } )
	self:NetworkVar( "Int", "SpeedUnit", { KeyName = "speedunit", Edit = { type = "Combo", order = 61, category = "Drivetrain Settings", values = {KPH = 0, MPH = 1}, tooltip = "Unit speed should be displayed in" } } )
	self:NetworkVar( "Int", "FuelUnit", { KeyName = "fuelunit", Edit = { type = "Combo", order = 62, category = "Drivetrain Settings", values = {L = 0, G = 1}, tooltip = "Unit fuel levels should be displayed in" } } )

	self:NetworkVar( "Int", "BrakeEngagement", { KeyName = "brakeengagement", Edit = { type = "Combo", order = 71, category = "Brake Settings", values = {Manual = 0, Automatic = 1}, tooltip = "How the brake is used to stop" } } )
	self:NetworkVar( "Int", "DisableWeldBrake", { KeyName = "disableweldbrake", Edit = { type = "Bool", order = 72, category = "Brake Settings", tooltip = "Disables weld brake and only uses ACF brakes to stop the vehicle (useful for very light cars)"  } } )
	self:NetworkVar( "Int", "BrakeStrength", { KeyName = "brakestrength", Edit = { type = "Int", order = 73, category = "Brake Settings", min = 0.001, max = 1000, tooltip = "Brake strength (at low speed) (used as steer angle for cars)"  } } )
	self:NetworkVar( "Int", "BrakeStrengthTop", { KeyName = "brakestrengthtop", Edit = { type = "Int", order = 74, category = "Brake Settings", min = 0.001, max = 1000, tooltip = "Brake strength (at top speed) (used as steer angle for cars)"  } } )
	self:NetworkVar( "Int", "SpeedLow", { KeyName = "speedlow", Edit = { type = "Int", order = 75, category = "Brake Settings", min = 0.001, max = 1000, tooltip = "low speed for brake setting"  } } )
	self:NetworkVar( "Int", "SpeedTop", { KeyName = "speedtop", Edit = { type = "Int", order = 76, category = "Brake Settings", min = 0.001, max = 1000, tooltip = "top speed for brake setting"  } } )

	self:NetworkVar( "Float", "ShiftTime", { KeyName = "shifttime", Edit = { type = "Int", order = 80, category = "Shifting Settings", min = 100, max = 3000, tooltip = "Delay between gear shifts"  } } )
	self:NetworkVar( "Int", "ShiftMinRPM", { KeyName = "shiftminrpm", Edit = { type = "Int", order = 81, category = "Shifting Settings", min = 0, max = 10000, tooltip = "Shifts gear down at this RPM"  } } )
	self:NetworkVar( "Int", "ShiftMaxRPM", { KeyName = "shiftmaxrpm", Edit = { type = "Int", order = 82, category = "Shifting Settings", min = 0, max = 10000, tooltip = "Shifts gear up at this RPM"  } } )

	self:NetworkVar( "Float", "SteerPercent1", { KeyName = "steerpercent1", Edit = { type = "Float", order = 90, category = "Car Steering Settings", min = -1, max = 1, tooltip = "Percent of brake strength used to steer 1st wheel pair" } } )
	self:NetworkVar( "Float", "SteerPercent2", { KeyName = "steerpercent2", Edit = { type = "Float", order = 91, category = "Car Steering Settings", min = -1, max = 1, tooltip = "Percent of brake strength used to steer 2nd wheel pair" } } )
	self:NetworkVar( "Float", "SteerPercent3", { KeyName = "steerpercent3", Edit = { type = "Float", order = 92, category = "Car Steering Settings", min = -1, max = 1, tooltip = "Percent of brake strength used to steer 3rd wheel pair" } } )
	self:NetworkVar( "Float", "SteerPercent4", { KeyName = "steerpercent4", Edit = { type = "Float", order = 93, category = "Car Steering Settings", min = -1, max = 1, tooltip = "Percent of brake strength used to steer 4th wheel pair" } } )
	self:NetworkVar( "Float", "SteerRate", { KeyName = "steerrate", Edit = { type = "Float", order = 94, category = "Car Steering Settings", min = -45, max = 45, tooltip = "Speed wheels are steered at" } } )
end

-- Thank you march (https://github.com/marchc1/imagestickers/blob/master/lua/imagestickers/properties.lua)
local EditAIOSettings = {
	MenuLabel = "Edit AIO Settings",
	Order = 99999,
	PrependSpacer = true,
	MenuIcon = "icon16/image_edit.png",

	Filter = function(_, ent, _)
		if not IsValid(ent) then return false end
		if not ent.IsACFController then return false end
		return true
	end,

	Action = function(_, ent)
		-- Create a popout window with the control embedded in it
		local window = g_ContextMenu:Add( "DFrame" )
		window:SetSize(400, 500)
		window:SetTitle("AIO Controller Settings [" .. ent:EntIndex() .. "]")
		window:Center()
		window:SetSizable(true)
		window:SetDraggable(true)
		window:MoveToFront()

		local Notice = window:Add("DLabel")
		Notice:Dock(TOP)
		Notice:DockMargin(5, 5, 5, 5)
		Notice:SetText("MOST changes made here are update live on the AIO controller.\nRedupe and paste if nothing seems to update.\nHover over an option to see its description.")
		Notice:SetDark(true)
		Notice:SizeToContents()
		Notice:SetFont("ACF_Label")

		local control = window:Add("DEntityProperties")
		function control:EditVariable(varname, item)
			local row = self:CreateRow(item.category, item.title)
			row:Setup(item.type, item)
			row.DataUpdate = function(_)
				if not IsValid(self.m_Entity) then self:EntityLost() return end
				row:SetValue(self.m_Entity:GetNetworkKeyValue(varname))
			end

			row.DataChanged = function(_, val)
				if not IsValid(self.m_Entity) then self:EntityLost() return end
				self.m_Entity:EditValue(varname, tostring(val))
			end

			row:SetTooltip(item.tooltip or "")
		end

		-- Pass entity to control to populate it
		control:SetEntity(ent)
		control:Dock(FILL)
		window.Properties = control

		-- Close window if entity is removed while open
		control.OnEntityLost = function()
			window:Remove()
		end
	end
}

hook.Add( "CanProperty", "block_aio_default_property", function( _, property, ent )
	if (property == "editentity" and ent.IsACFController) then return false end
end )

properties.Add("edit.aio_settings", EditAIOSettings)