do -- Clientside chat messages
	local Types = {
		Normal = {
			Prefix = "",
			Color = Color(80, 255, 80)
		},
		Info = {
			Prefix = " - Info",
			Color = Color(0, 233, 255)
		},
		Warning = {
			Prefix = " - Warning",
			Color = Color(255, 160, 0)
		},
		Error = {
			Prefix = " - Error",
			Color = Color(255, 80, 80)
		}
	}

	function ACF.AddMessageType(Name, Prefix, TitleColor)
		if not Name then return end

		Types[Name] = {
			Prefix = Prefix and (" - " .. Prefix) or "",
			Color = TitleColor or Color(80, 255, 80),
		}
	end

	local function PrintToChat(Type, ...)
		if not ... then return end

		local Data = Types[Type] or Types.Normal
		local Prefix = "[ACF" .. Data.Prefix .. "] "
		local Message = istable(...) and ... or { ... }

		chat.AddText(Data.Color, Prefix, color_white, unpack(Message))
	end

	ACF.PrintToChat = PrintToChat

	net.Receive("ACF_ChatMessage", function()
		local Type = net.ReadString()
		local Message = net.ReadTable()

		PrintToChat(Type, Message)
	end)
end

do -- Custom fonts
	surface.CreateFont("ACF_Title", {
		font = "Roboto",
		size = 22,
		weight = 850,
	})

	surface.CreateFont("ACF_Subtitle", {
		font = "Roboto",
		size = 18,
		weight = 850,
	})

	surface.CreateFont("ACF_Paragraph", {
		font = "Roboto",
		size = 14,
		weight = 650,
	})

	surface.CreateFont("ACF_Control", {
		font = "Roboto",
		size = 14,
		weight = 550,
	})
end

do -- Tool data functions
	local ToolData = {}

	do -- Read functions
		function ACF.ReadBool(Key)
			if not Key then return false end

			return tobool(ToolData[Key])
		end

		function ACF.ReadNumber(Key)
			if not Key then return 0 end

			return tonumber(ToolData[Key])
		end

		function ACF.ReadString(Key)
			if not Key then return "" end

			return tostring(ToolData[Key])
		end
	end

	do -- Write function
		local KeyPattern = "^[%w]+"
		local ValuePattern = "[%w]*[%.]?[%w]+$"

		local function IsValidKey(Key)
			if not Key then return false end

			return Key:match(KeyPattern) and true or false
		end

		local function IsValidValue(Value)
			if not Value then return false end

			return tostring(Value):match(ValuePattern) and true or false
		end

		local function UpdateKeyValue(Key, Value)
			if ToolData[Key] == Value then return end

			ToolData[Key] = Value

			net.Start("ACF_ToolData")
				net.WriteString(Key .. ":" .. Value)
			net.SendToServer()

			hook.Run("OnToolDataUpdate", Key, Value)

			print("Sent", LocalPlayer(), Key, Value)
		end

		function ACF.WriteValue(Key, Value)
			if not IsValidKey(Key) then return end
			if not IsValidValue(Value) then return end

			UpdateKeyValue(Key, Value)
		end
	end

	do -- Panel functions
		local PANEL = FindMetaTable("Panel")
		local Panels = {}

		local function AddFunctions(Panel)
			Panel.LegacySetValue = Panel.SetValue
			Panel.LegacyRemove = Panel.Remove

			Panels[Panel] = true

			function Panel:SetValue(Value, ...)
				ACF.WriteValue(self.DataVar, Value)

				self:LegacySetValue(Value, ...)
			end

			function Panel:Remove(...)
				Panels[Panel] = nil

				self:LegacyRemove(...)
			end
		end

		function PANEL:SetDataVariable(Key)
			if not Key then return end
			if not self.SetValue then return end

			self.DataVar = Key

			if not ToolData[Key] then
				ACF.WriteValue(Key, self:GetValue())
			end

			if not self.LegacySetValue then
				AddFunctions(self)
			end
		end

		function PANEL:ClearDataVariable()
			if not self.LegacySetValue then return end

			Panels[self] = nil

			self.SetValue = self.LegacySetValue
			self.Remove = self.LegacyRemove
			self.LegacySetValue = nil
			self.LegacyRemove = nil
			self.DataVar = nil
		end

		hook.Add("OnToolDataUpdate", "ACF Update Panel Values", function(Key, Value)
			for Panel in pairs(Panels) do
				if Panel.DataVar == Key then
					Panel:LegacySetValue(Value)
				end
			end
		end)
	end
end