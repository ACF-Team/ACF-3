AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF = ACF

ENT.OverlayDelay = 1 -- Time in seconds between each overlay update

-- You should overwrite these
function ENT:Enable() end
function ENT:Disable() end
function ENT:UpdateOverlayText() end

do -- Entity Overlay ----------------------------
	local Disable = "Disabled: %s\n%s"
	local Name    = "ACF Overlay Buffer %s"
	local timer   = timer

	local function GetText(Entity)
		if Entity.Disabled then
			return Entity:GetDisableText()
		end

		return Entity:UpdateOverlayText()
	end

	function ENT:GetDisableText()
		local Disabled = self.Disabled

		return Disable:format(Disabled.Reason, Disabled.Message)
	end

	function ENT:UpdateOverlay(Instant)
		if Instant then
			return self:SetOverlayText(GetText(self))
		end

		if self.OverlayCooldown then -- This entity has been updated too recently
			self.QueueOverlay = true -- Mark it to update when buffer time has expired
		else
			self:SetOverlayText(GetText(self))

			self.OverlayCooldown = true

			timer.Create(Name:format(self:EntIndex()), self.OverlayDelay, 1, function()
				if not IsValid(self) then return end

				self.OverlayCooldown = nil

				if self.QueueOverlay then
					self.QueueOverlay = nil

					self:UpdateOverlay()
				end
			end)
		end
	end
end ---------------------------------------------

do -- Entity linking and unlinking --------------
	local LinkText   = "%s can't be linked to %s."
	local UnlinkText = "%s can't be unlinked from %s."

	function ENT:Link(Target)
		if not IsValid(Target) then return false, "Attempted to link an invalid entity." end
		if self == Target then return false, "Can't link an entity to itself." end

		local Class    = Target:GetClass()
		local Function = ACF.GetClassLink(self:GetClass(), Class)

		if Function then
			return Function(self, Target)
		elseif self.DefaultLink then
			return self:DefaultLink(Target)
		end

		return false, LinkText:format(self.PluralName, Target.PluralName or Class)
	end

	function ENT:Unlink(Target)
		if not IsValid(Target) then return false, "Attempted to unlink an invalid entity." end
		if self == Target then return false, "Can't unlink an entity from itself." end

		local Class    = Target:GetClass()
		local Function = ACF.GetClassUnlink(self:GetClass(), Class)

		if Function then
			return Function(self, Target)
		elseif self.DefaultUnlink then
			return self:DefaultUnlink(Target)
		end

		return false, UnlinkText:format(self.PluralName, Target.PluralName or Class)
	end
end ---------------------------------------------

do -- Entity inputs -----------------------------
	local function SetupInputActions(Entity)
		Entity.InputActions = ACF.GetInputActions(Entity:GetClass())
	end

	local function FindInputName(Entity, Name, Actions)
		if not Entity.InputAliases then return Name end

		local Aliases = Entity.InputAliases
		local Checked = { [Name] = true }

		repeat
			if Actions[Name] then
				return Name
			end

			Checked[Name] = true

			Name = Aliases[Name] or Name
		until
			Checked[Name]


		return Name
	end

	function ENT:TriggerInput(Name, Value)
		if self.Disabled then return end -- Ignore input if disabled
		if not self.InputActions then SetupInputActions(self) end

		local Actions  = self.InputActions
		local RealName = FindInputName(self, Name, Actions)
		local Action   = Actions[RealName]

		if Action then
			Action(self, Value)

			self:UpdateOverlay()
		end
	end
end ---------------------------------------------

do -- Entity user -------------------------------
	-- TODO: Add a function to register more user sources
	local WireTable = {
		gmod_wire_adv_pod = true,
		gmod_wire_joystick = true,
		gmod_wire_expression2 = true,
		gmod_wire_joystick_multi = true,
		gmod_wire_pod = function(_, Input)
			if IsValid(Input.Pod) then
				return Input.Pod:GetDriver()
			end
		end,
		gmod_wire_keyboard = function(_, Input)
			if Input.ply then
				return Input.ply
			end
		end,
	}

	local function FindUser(Entity, Input, Checked)
		local Function = WireTable[Input:GetClass()]

		return Function and Function(Entity, Input, Checked or {})
	end

	WireTable.gmod_wire_adv_pod			= WireTable.gmod_wire_pod
	WireTable.gmod_wire_joystick		= WireTable.gmod_wire_pod
	WireTable.gmod_wire_joystick_multi	= WireTable.gmod_wire_pod
	WireTable.gmod_wire_expression2		= function(This, Input, Checked)
		for _, V in pairs(Input.Inputs) do
			if IsValid(V.Src) and not Checked[V.Src] and WireTable[V.Src:GetClass()] then
				Checked[V.Src] = true -- We don't want to start an infinite loop

				return FindUser(This, V.Src, Checked)
			end
		end
	end

	function ENT:GetUser(Input)
		if not IsValid(Input) then return self:GetPlayer() end

		local User = FindUser(self, Input)

		return IsValid(User) and User or self:GetPlayer()
	end
end ---------------------------------------------
