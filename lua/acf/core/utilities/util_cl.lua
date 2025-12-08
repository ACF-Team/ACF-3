local ACF = ACF

do -- Custom fonts
	surface.CreateFont("ACF_Title", {
		font = "Roboto",
		size = 18,
		weight = 850,
		antialias = true,
	})

	surface.CreateFont("ACF_Label", {
		font = "Roboto",
		size = 14,
		weight = 650,
		antialias = true,
	})

	surface.CreateFont("ACF_Control", {
		font = "Roboto",
		size = 14,
		weight = 550,
		antialias = true,
	})
end

do -- Networked notifications
	local notification = notification
	local Messages = ACF.Utilities.Messages
	local ReceiveShame = GetConVar("acf_legalshame")
	local LastNotificationSoundTime = 0
	net.Receive("ACF_Notify", function()
		local IsOK = net.ReadBool()
		local Msg  = net.ReadString()
		local Type = IsOK and NOTIFY_GENERIC or NOTIFY_ERROR

		local Now = SysTime()
		local DeltaTime = Now - LastNotificationSoundTime

		if not IsOK and DeltaTime > 0.2 then -- Rate limit sounds. Helps with lots of sudden errors not killing your ears
			surface.PlaySound("buttons/button10.wav")
			LastNotificationSoundTime = Now
		end

		Msg = "[ACF] " .. Msg
		notification.AddLegacy(Msg, Type, 7)
	end)

	net.Receive("ACF_NameAndShame", function()
		if not ReceiveShame:GetBool() then return end
		Messages.PrintLog("Error", net.ReadString())
	end)
end

do
	do
		-- Draws an outlined beam between var-length pairs of XY1 -> XY2 line segments.
		-- Is not the best thing in the world, only really used in gizmos to make it easier 
		-- to see during building
		function ACF.DrawOutlineBeam(width, color, ...)
			local args = {...}
			local Add = 0.4
			for i = 1, #args, 2 do
				local DirAdd = (args[i + 1] - args[i]):GetNormalized() * (Add / 2)

				render.DrawBeam(args[i] - DirAdd, args[i + 1] + DirAdd, width + Add, 0, 1, color_black)
			end
			for i = 1, #args, 2 do
				render.DrawBeam(args[i], args[i + 1], width, 0, 1, color)
			end
		end
	end
end