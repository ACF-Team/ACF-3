return function(PANEL)
    function PANEL:AddVectorSlider(Title, Min, Max, Decimals)
        local Base = self:AddPanel("ACF_Panel")

        Base.varX = Base:AddSlider(Title .. " X", Min.x, Max.x, Decimals)
        Base.varY = Base:AddSlider(Title .. " Y", Min.y, Max.y, Decimals)
        Base.varZ = Base:AddSlider(Title .. " Z", Min.z, Max.z, Decimals)

        -- TODO: Refactor this and other panel binds to reduce code duplication?

        -- Binds three sliders to a vector DataVar
        function Base:BindToDataVar(Name, Scope, TargetRealm)
            local suppress = false

            local function GetValue()
                return Vector(self.varX:GetValue(), self.varY:GetValue(), self.varZ:GetValue())
            end

            local function SetValue(vec)
                suppress = true
                self.varX:SetValue(vec.x) self.varY:SetValue(vec.y) self.varZ:SetValue(vec.z)
                suppress = false
            end

            local function PushToDataVar()
                if suppress then return end
                ACF.SetDataVar(Name, Scope, GetValue(), TargetRealm)
            end

            -- When any one slider changes, push the new vector to the DataVar
            self.varX:HijackAfter("OnValueChanged", PushToDataVar)
            self.varY:HijackAfter("OnValueChanged", PushToDataVar)
            self.varZ:HijackAfter("OnValueChanged", PushToDataVar)

            self.varX:HijackAfter("SetValue", PushToDataVar)
            self.varY:HijackAfter("SetValue", PushToDataVar)
            self.varZ:HijackAfter("SetValue", PushToDataVar)

            -- When the datavar changes, update all sliders.
            self:WatchDataVar(Name, Scope, function(value)
                SetValue(value)
            end)

            -- Initialize with current/default value
            local initial = ACF.GetDataVar(Name, Scope, TargetRealm)
            if initial then
                SetValue(initial)
            end
        end

        return Base
    end
end