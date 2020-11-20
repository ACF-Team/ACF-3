local ACF = ACF

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
			local Result = {}

			for K, V in pairs(ToolData) do
				Result[K] = V
			end

			return Result
		end

		local function ReadData(Key, Default)
			if Key == nil then return end

			local Value = ToolData[Key]

			return Value ~= nil and Value or Default
		end

		function ACF.ReadBool(Key, Default)
			return tobool(ReadData(Key, Default))
		end

		function ACF.ReadNumber(Key, Default)
			local Value = ReadData(Key, Default)

			return Value ~= nil and tonumber(Value) or 0 -- tonumber can't handle nil values
		end

		function ACF.ReadString(Key)
			local Value = ReadData(Key, Default)

			return Value ~= nil and tostring(Value) or "" -- tostring can't handle nil values
		end

		ACF.ReadData = ReadData
		ACF.ReadRaw = ReadData
	end

	do -- Write function
		local LastSent = {}

		function ACF.WriteValue(Key, Value)
			if not isstring(Key) then return end
			if ToolData[Key] == Value then return end

			ToolData[Key] = Value

			hook.Run("OnToolDataUpdate", Key, Value)

			-- TODO: Replace with a queue system similar to the one used by the scalable base
			-- Allowing one network message per key per tick
			if timer.Exists("ACF WriteValue " .. Key) then return end

			timer.Create("ACF WriteValue " .. Key, 0, 1, function()
				local NewValue = ToolData[Key]

				-- Preventing network message spam if value hasn't really changed
				if LastSent[Key] == NewValue then return end

				LastSent[Key] = NewValue

				net.Start("ACF_ToolData")
					net.WriteString(Key)
					net.WriteType(NewValue)
				net.SendToServer()

				print("Sent", LocalPlayer(), Key, NewValue, type(NewValue))
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
					if not Panel.OldSetFunc then continue end

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

do -- Clientside visclip check
	local function CheckClip(Entity, Clip, Center, Pos)
		if Clip.physics then return false end -- Physical clips will be ignored, we can't hit them anyway

		local Normal = Entity:LocalToWorldAngles(Clip.n or Clip[1]):Forward()
		local Origin = Center + Normal * (Clip.d or Clip[2])

		return Normal:Dot((Origin - Pos):GetNormalized()) > 0
	end

	function ACF.CheckClips(Ent, Pos)
		if not IsValid(Ent) then return false end
		if not Ent.ClipData then return false end -- Doesn't have clips
		if Ent:GetClass() ~= "prop_physics" then return false end -- Only care about props

		-- Compatibility with Proper Clipping tool: https://github.com/DaDamRival/proper_clipping
		-- The bounding box center will change if the entity is physically clipped
		-- That's why we'll use the original OBBCenter that was stored on the entity
		local Center = Ent:LocalToWorld(Ent.OBBCenterOrg or Ent:OBBCenter())

		for _, Clip in ipairs(Ent.ClipData) do
			if CheckClip(Ent, Clip, Center, Pos) then return true end
		end

		return false
	end
end

do -- Panel helpers
	local Sorted = {}

	function ACF.LoadSortedList(Panel, List, Member)
		local Data = Sorted[List]

		if not Data then
			local Choices = {}
			local Count = 0

			for _, Value in pairs(List) do
				Count = Count + 1

				Choices[Count] = Value
			end

			table.SortByMember(Choices, Member, true)

			Data = {
				Choices = Choices,
				Index = 1,
			}

			Sorted[List] = Data
		end

		local Current = Data.Index

		Panel.ListData = Data

		Panel:Clear()

		for Index, Value in ipairs(Data.Choices) do
			Panel:AddChoice(Value.Name, Value, Index == Current)
		end
	end
end