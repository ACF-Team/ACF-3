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
		size = 18,
		weight = 850,
	})

	surface.CreateFont("ACF_Label", {
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
		function ACF.GetToolData()
			return ToolData
		end

		function ACF.ReadBool(Key)
			if not Key then return false end

			return tobool(ToolData[Key])
		end

		function ACF.ReadNumber(Key)
			if not Key then return 0 end

			local Data = ToolData[Key]

			if Data == nil then return 0 end

			return tonumber(Data)
		end

		function ACF.ReadString(Key)
			if not Key then return "" end

			local Data = ToolData[Key]

			if Data == nil then return "" end

			return tostring(Data)
		end
	end

	do -- Write function
		local LastSent = {}
		local KeyPattern = "^[%w]+"
		local ValuePattern = "[%w]*[%.]?[%w]+$"

		local function IsValidKey(Key)
			if not Key then return false end

			return Key:match(KeyPattern) and true or false
		end

		local function IsValidValue(Value)
			if Value == nil then return false end

			return tostring(Value):match(ValuePattern) and true or false
		end

		function ACF.WriteValue(Key, Value)
			if not IsValidKey(Key) then return end
			if not IsValidValue(Value) then return end
			if ToolData[Key] == Value then return end

			ToolData[Key] = Value

			hook.Run("OnToolDataUpdate", Key, Value)

			-- Allowing one network message per key per tick
			if timer.Exists("ACF WriteValue " .. Key) then return end

			timer.Create("ACF WriteValue " .. Key, 0, 1, function()
				local NewValue = tostring(ToolData[Key])

				-- Preventing network message spam if value hasn't really changed
				if LastSent[Key] == NewValue then return end

				LastSent[Key] = NewValue

				net.Start("ACF_ToolData")
					net.WriteString(Key .. ":" .. NewValue)
				net.SendToServer()

				print("Sent", LocalPlayer(), Key, NewValue)
			end)
		end
	end

	do -- Panel functions
		local PANEL = FindMetaTable("Panel")
		local Trackers = {}
		local Setters = {}
		local Variables = {
			Trackers = {},
			Setters = {},
		}

		local function AddVariable(Panel, Key, Target)
			local Data = Variables[Target]
			local VData = Data[Key]

			if not VData then
				Data[Key] = {
					[Panel] = true
				}
			else
				VData[Panel] = true
			end
		end

		local function AddTracker(Panel, Key)
			local Data = Trackers[Panel]

			if not Data then
				Trackers[Panel] = {
					[Key] = true
				}
			else
				Data[Key] = true
			end

			AddVariable(Panel, Key, "Trackers")
		end

		local function AddSetter(Panel, Key)
			local Data = Setters[Panel]

			if not Data then
				Setters[Panel] = {
					[Key] = true
				}
			else
				Data[Key] = true
			end

			AddVariable(Panel, Key, "Setters")
		end

		local function ClearVariables(Panel)
			if Trackers[Panel] then
				for K in pairs(Trackers[Panel]) do
					Variables.Trackers[K][Panel] = nil
				end

				Trackers[Panel] = nil
			end

			if Setters[Panel] then
				for K in pairs(Setters[Panel]) do
					Variables.Setters[K][Panel] = nil
				end

				Setters[Panel] = nil
			end
		end

		local function LoadFunctions(Panel)
			if not Panel.LegacyRemove then
				Panel.LegacyRemove = Panel.Remove

				function Panel:Remove()
					ClearVariables(self)

					self:LegacyRemove()
				end
			end

			if Panel.Hijack and Panel.Hijack ~= Panel.PrevHijack then
				if Panel.PrevHijack then
					Panel[Panel.PrevHijack] = Panel.OldSetFunc
				end

				Panel.PrevHijack = Panel.Hijack
				Panel.OldSetFunc = Panel[Panel.Hijack]

				function Panel:NewSetFunc(Value)
					if self.DataVar then
						ACF.WriteValue(self.DataVar, Value)
						return
					end

					self:OldSetFunc(Value)
				end

				Panel[Panel.Hijack] = Panel.NewSetFunc
			end
		end

		function PANEL:SetDataVar(Key, Function)
			if not Key then return end

			self.DataVar = Key
			self.Hijack = Function or self.Hijack or "SetValue"

			AddSetter(self, Key)
			LoadFunctions(self)

			if not ToolData[Key] then
				ACF.WriteValue(Key, self:GetValue())
			end
		end

		function PANEL:TrackDataVar(Key, Function)
			self.Hijack = Function or self.Hijack or "SetValue"

			AddTracker(self, Key)
			LoadFunctions(self)
		end

		function PANEL:SetValueFunction(Function)
			if not isfunction(Function) then return end

			LoadFunctions(self)

			self.ValueFunction = Function

			if self.Hijack then
				self:NewSetFunc(self:ValueFunction())
			end
		end

		function PANEL:ClearDataVars()
			if self.LegacyRemove then
				self.Remove = self.LegacyRemove
				self.LegacyRemove = nil
			end

			if self.Hijack then
				self[self.Hijack] = self.OldSetFunc
				self.OldSetFunc = nil
				self.NewSetFunc = nil
				self.PrevHijack = nil
				self.Hijack = nil
			end

			self.ValueFunction = nil
			self.DataVar = nil

			ClearVariables(self)
		end

		hook.Add("OnToolDataUpdate", "ACF Update Panel Values", function(Key, Value)
			local TrackerPanels = Variables.Trackers[Key]
			local SetterPanels = Variables.Setters[Key]

			-- First we'll process the panels that set the value of this key
			if SetterPanels then
				for Panel in pairs(SetterPanels) do
					local NewValue = Value

					if Panel.ValueFunction then
						NewValue = Panel:ValueFunction()
					end

					Panel:OldSetFunc(NewValue)
				end
			end

			-- Then we'll process the panels that just keep track of this value
			if TrackerPanels then
				for Panel in pairs(TrackerPanels) do
					if not Panel.ValueFunction then continue end

					Panel:OldSetFunc(Panel:ValueFunction(true))
				end
			end
		end)
	end
end
