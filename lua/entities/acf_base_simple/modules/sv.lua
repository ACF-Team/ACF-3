return function()
    local ACF = ACF

    ENT.OverlayDelay = 1 -- Time in seconds between each overlay update

    -- You should overwrite these
    function ENT:Enable() end
    function ENT:Disable() end
    function ENT:ACF_UpdateOverlayState() end

    local AddRequirementLines

    do -- Requirements ------------------------------
        local Diagnostics = ACF.Diagnostics

        --- Marks a requirement as met or not, the overlay lists the unmet ones with their help. Not applicable counts as met.
        --- @param Id string A requirement registered with ACF.Hints.RegisterRequirement
        --- @param Met boolean Whether the requirement is currently met
        --- @param Data table|nil Why it is not met, read by the requirement's detail and drawing
        --- @return boolean # Met, for use in conditions
        function ENT:SetRequirement(Id, Met, Data)
            local Unmet = self.ACF_UnmetRequirements

            if Met then
                if not (Unmet and Unmet[Id]) then return true end

                Unmet[Id] = nil

                table.RemoveByValue(self.ACF_UnmetOrder, Id)
                self:UpdateOverlay()
                ACF.Hints.DrawRequirements(self)

                return true
            end

            if not ACF.Hints.Requirements[Id] then error("Unknown requirement '" .. tostring(Id) .. "'") end

            if not Unmet then
                Unmet                      = {}
                self.ACF_UnmetRequirements = Unmet
                self.ACF_UnmetOrder        = {}
            end

            Data = Data or {}

            local Current = Unmet[Id]

            if Current and ACF.SameData(Current, Data) then return false end

            Unmet[Id] = Data

            if not Current then
                local Order = self.ACF_UnmetOrder

                Order[#Order + 1] = Id

                self:UpdateOverlay()
                ACF.Hints.DrawRequirements(self)

                return false
            end

            -- Only the text reaches the overlay, data such as trace positions is picked up by the next redraw
            local _, OldDetail = Diagnostics.Describe(Id, Current)
            local _, NewDetail = Diagnostics.Describe(Id, Data)

            if OldDetail ~= NewDetail then self:UpdateOverlay() end

            return false
        end

        --- @return boolean # Whether every requirement set on this entity is met
        function ENT:RequirementsMet()
            local Unmet = self.ACF_UnmetRequirements

            return not Unmet or next(Unmet) == nil
        end

        -- Override to hide the requirements when they are not relevant, such as a gun that is already loaded
        function ENT:ACF_ShowRequirements()
            return true
        end

        function AddRequirementLines(self, State)
            local Unmet = self.ACF_UnmetRequirements
            if not Unmet or not next(Unmet) or not self:ACF_ShowRequirements() then return end

            for _, Id in ipairs(self.ACF_UnmetOrder) do
                local Title, Detail = Diagnostics.Describe(Id, Unmet[Id])

                State:AddWarning(Detail ~= "" and Title .. ": " .. Detail or Title, Id)
            end
        end
    end ---------------------------------------------

    do -- Entity Overlay ----------------------------
        local Name    = "ACF Overlay Buffer %s"
        local timer   = timer

        function ENT:GetOverlayState()
            local OverlayState = self.OverlayState
            if not OverlayState then
                OverlayState = ACF.Overlay.State()
                self.OverlayState = OverlayState
                self:UpdateOverlay(true)
            end

            return OverlayState
        end

        local function DoUpdate(self, OverlayState)
            OverlayState:Begin()
            local EntityName = self:ACF_GetEntityName()
            OverlayState:AddHeader(EntityName)

            if ACF.IsDestroyed(self) then OverlayState:AddError(self.ACF_DestroyedLabel or "Destroyed") end

            ACF.Legality.AddOverlayLines(self, OverlayState)
            ACF.Hints.AddOverlayLines(self, OverlayState)
            AddRequirementLines(self, OverlayState)
            self:ACF_UpdateOverlayState(OverlayState)
            OverlayState:End()
            ACF.Overlay.UpdateOverlay(self, OverlayState)
        end
        function ENT:UpdateOverlay(Instant)
            local OverlayState = self.OverlayState
            if not OverlayState then
                OverlayState = ACF.Overlay.State()
                self.OverlayState = OverlayState
            end

            if Instant then
                DoUpdate(self, OverlayState)
                return
            end

            if self.OverlayCooldown then -- This entity has been updated too recently
                self.QueueOverlay = true -- Mark it to update when buffer time has expired
            else
                DoUpdate(self, OverlayState)

                self.OverlayCooldown = true

                timer.Create(Name:format(self:EntIndex()), self.OverlayDelay, 1, function()
                    if not IsValid(self) then return end

                    self.OverlayCooldown = nil

                    if self.QueueOverlay then
                        self.QueueOverlay = nil

                        self:UpdateOverlay(false)
                    end
                end)
            end
        end
    end ---------------------------------------------

    do -- Entity linking and unlinking --------------
        function ENT:Link(Target, FromChip)
            return ACF.PerformClassLink(self, Target, FromChip)
        end

        function ENT:Unlink(Target)
            return ACF.PerformClassUnlink(self, Target)
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

        function ENT:GetOwnerPlayer()
            local Player = self.GetPlayer and self:GetPlayer() -- Not set on entities restored from a duplication, use CPPI instead

            return IsValid(Player) and Player or self:CPPIGetOwner()
        end

        function ENT:GetUser(Input)
            if not IsValid(Input) then return self:GetOwnerPlayer() end

            local User = FindUser(self, Input)

            return IsValid(User) and User or self:GetOwnerPlayer()
        end
    end ---------------------------------------------
end