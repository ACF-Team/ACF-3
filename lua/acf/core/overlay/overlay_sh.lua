-- The ACF overlay system. Contact March if something breaks horribly.

local Overlay = ACF.Overlay or {}
ACF.Overlay = Overlay

-- Networking
do
    -- 128 elements for an entity overlay seems fair (if not hyperbolic, even)
    Overlay.MAX_ELEMENTS               = 128
    Overlay.MAX_ELEMENT_BITS           = 7

    Overlay.MAX_ELEMENT_DATA           = 64
    Overlay.MAX_ELEMENT_DATA_BITS      = 6

    Overlay.C2S_OVERLAY_START          = 0
    Overlay.C2S_OVERLAY_END            = 1
    Overlay.S2C_OVERLAY_DELTA_UPDATE   = 2

    local OVERLAY_MSG_TYPE_BITS      = 2
    local OVERLAY_MSG_STRINGTABLEIDX = "ACF_RequestOverlay"
    if SERVER then util.AddNetworkString(OVERLAY_MSG_STRINGTABLEIDX) end

    Overlay.Receivers = Overlay.Receivers or {}
    local Receivers = Overlay.Receivers

    function Overlay.NetStart(MessageType, Unreliable)
        net.Start(OVERLAY_MSG_STRINGTABLEIDX, Unreliable)
        net.WriteUInt(MessageType, OVERLAY_MSG_TYPE_BITS)
    end

    function Overlay.NetReceive(Type, Func)
        Receivers[Type] = Func
    end

    net.Receive(OVERLAY_MSG_STRINGTABLEIDX, function(...)
        local Type = net.ReadUInt(OVERLAY_MSG_TYPE_BITS)
        local Recv = Receivers[Type]
        if Recv then
            Recv(...)
        end
    end)
end

-- Delta-encoding. TODO: Some of this needs better validation against MAX_ELEMENTS and MAX_ELEMENT_DATA!!!!!!!!!!
do
    function Overlay.DeltaDecodeSlot(DeprivedSlot, Reader)
        if Reader == nil then
            Reader = net
        end

        local TypeChange = net.ReadBool()
        if TypeChange then
            DeprivedSlot.Type = Reader.ReadUInt(Overlay.ELEMENT_TYPE_BITS)
        end

        local NetworkingNumData, IdealNumData
        if Reader.ReadBool() then
            NetworkingNumData = Reader.ReadUInt(Overlay.MAX_ELEMENT_DATA_BITS)
            IdealNumData = Reader.ReadUInt(Overlay.MAX_ELEMENT_DATA_BITS)
        else
            NetworkingNumData = DeprivedSlot:NumElementData()
            IdealNumData = NetworkingNumData
        end

        --print("        Type changed : " .. tostring(TypeChange))
        --print("        New type     : " .. tostring(DeprivedSlot.Type))

        local OneDataPieceChanged = false
        for I = 1, NetworkingNumData do
            local IsDeviation = Reader.ReadBool()
            if IsDeviation then
                --print("        Is deviation : " .. tostring(IsDeviation))
                local Changed = Reader.ReadBool()
                --print("          Changed      : " .. tostring(Changed))
                if Changed then
                    local Data = Reader.ReadType()
                    --print("          Data: " .. tostring(Data))
                    DeprivedSlot:SetElementData(I, Data)
                    OneDataPieceChanged = true
                end
            else
                OneDataPieceChanged = true
                local IsAddition = Reader.ReadBool()
                --print("        Is addition  : " .. tostring(IsAddition))
                if IsAddition then
                    local Data = Reader.ReadType()
                    --print("          Data: " .. tostring(Data))
                    DeprivedSlot:SetElementData(I, Data)
                end
            end
        end

        DeprivedSlot.ChangedSinceLastUpdate = OneDataPieceChanged
        DeprivedSlot.NumData = IdealNumData

        return OneDataPieceChanged
    end

    -- Decodes a bit reader to an ideal state.
    function Overlay.DeltaDecodeState(DeprivedState, Reader)
        if Reader == nil then
            Reader = net
        end

        -- Read if slots have changed. If not, we can use the deprived state.
        local SlotsChanged   = Reader.ReadBool()
        local NetworkingSlots, IdealSlots
        if SlotsChanged then
            NetworkingSlots = Reader.ReadUInt(Overlay.MAX_ELEMENT_BITS)
            IdealSlots = Reader.ReadUInt(Overlay.MAX_ELEMENT_BITS)
        else
            NetworkingSlots = DeprivedState:NumElementSlots()
            IdealSlots = NetworkingSlots
        end
        --print("Delta decode started.")
        --print("  Networking Slots: " .. NetworkingSlots)
        --print("  Total Slots:      " .. IdealSlots)
        local OneSlotChanged = false
        for I = 1, NetworkingSlots do
            local IsDeviation = Reader.ReadBool()
            --print("    Slot #" .. I)
            if IsDeviation then
                --print("      Deviation: " .. tostring(IsDeviation))
                local DeprivedSlot = DeprivedState:GetElementSlot(I)
                if Overlay.DeltaDecodeSlot(DeprivedSlot, Reader) then
                    OneSlotChanged = true
                end
            else
                OneSlotChanged = true
                local IsAddition = Reader.ReadBool()
                --print("      Addition: " .. tostring(IsAddition))
                if IsAddition then
                    local DeprivedSlot = DeprivedState:AllocElementSlot()
                    Overlay.DeltaDecodeSlot(DeprivedSlot, Reader)
                else
                    DeprivedState:TryClearSlot(I)
                end
            end
        end

        DeprivedState.ChangedSinceLastUpdate = OneSlotChanged
        DeprivedState.NumElements = IdealSlots
    end

    function Overlay.DeltaEncodeSlot(DeprivedSlot, IdealSlot, Writer, WriteToSlot, Full)
        if Writer == nil then
            Writer = net
        end

        -- Determine if the type changed. Encoded as true if it did, and false if it didn't.
        -- True means read the new type.
        local TypeChange = Full or DeprivedSlot.Type ~= IdealSlot.Type
        Writer.WriteBool(TypeChange)
        if TypeChange then
            Writer.WriteUInt(IdealSlot.Type, Overlay.ELEMENT_TYPE_BITS)
        end

        local DeprivedNumData   = DeprivedSlot:NumElementData()
        local IdealNumData      = IdealSlot:NumElementData()
        local NetworkingNumData = Full and IdealNumData or math.max(IdealNumData, DeprivedNumData)

        -- Same as before for state slots, we encode if the amount of data has changed.
        local DataDifference = IdealNumData - DeprivedNumData
        if DataDifference ~= 0 or Full then
            Writer.WriteBool(true)
            Writer.WriteUInt(NetworkingNumData, Overlay.MAX_ELEMENT_DATA_BITS)
            Writer.WriteUInt(IdealNumData, Overlay.MAX_ELEMENT_DATA_BITS)
        else
            Writer.WriteBool(false)
        end

        for I = 1, NetworkingNumData do
            local IsAddition     = Full or (not DeprivedSlot:HasElementData(I) and IdealSlot:HasElementData(I))
            local IsSubtraction  = not Full and (DeprivedSlot:HasElementData(I) and not IdealSlot:HasElementData(I))
            local IsDeviation    = not Full and (not IsAddition and not IsSubtraction)

            -- We encode two booleans here always.
            -- The first boolean determines if this data being networked is a deviation, or an addition/subtraction.
            -- The second is determined by the value of the first boolean. If this is a deviation, the boolean networked
            -- is true if the value has changed, and false if the value has not changed. If this is not a deviation, then
            -- the boolean networked is true if this is an addition, and false if this is a subtraction.
            Writer.WriteBool(IsDeviation)

            -- TODO: Can we get away from Read/WriteType sometime? Ideally, strict typing is used for elements...
            -- we can avoid the cost of the byte that way. But this is easier for now. Just need to keep that in mind for later. 
            if IsDeviation then
                local DeprivedData = DeprivedSlot:GetElementData(I)
                local IdealData    = IdealSlot:GetElementData(I)
                local Changed      = IdealData ~= DeprivedData
                Writer.WriteBool(Changed)
                if Changed then
                    Writer.WriteType(IdealData)
                    if WriteToSlot then
                        DeprivedSlot:SetElementData(I, IdealSlot:GetElementData(I))
                    end
                end
            elseif IsAddition then
                local IdealData = IdealSlot:GetElementData(I)
                Writer.WriteBool(true)
                Writer.WriteType(IdealData)
                if WriteToSlot then
                    DeprivedSlot:SetElementData(I, IdealData)
                end
            elseif IsSubtraction then
                Writer.WriteBool(false)
            end
        end

        -- Copy NumData
        if WriteToSlot then
            DeprivedSlot.NumData = IdealSlot.NumData
        end
    end

    -- Delta encodes a state to a bit writer. If WriteToState is true, then DeprivedState will be upgraded.
    function Overlay.DeltaEncodeState(DeprivedState, IdealState, Writer, WriteToState, Full)
        if Writer == nil then
            Writer = net
        end

        local DeprivedNumSlots = DeprivedState:NumElementSlots()
        local IdealNumSlots    = IdealState:NumElementSlots()
        local NetworkingSlots  = math.max(IdealNumSlots, DeprivedNumSlots)

        -- Packet starts with a boolean for if the number of slots changed.
        -- If the number of slots has changed, write NetworkingSlots so the receiver knows
        -- how many to truly decode. If not, then we can use the existing NumElement value 
        -- on the other end. This is encoded in a single byte. (unless MAX_ELEMENTS has to
        -- be upgraded, for whatever reason)
        local SlotDifference = IdealNumSlots - DeprivedNumSlots
        -- Tell the receiver the difference the new amount of slots.
        if SlotDifference ~= 0 or Full then
            Writer.WriteBool(true)
            Writer.WriteUInt(NetworkingSlots, Overlay.MAX_ELEMENT_BITS)
            Writer.WriteUInt(IdealNumSlots, Overlay.MAX_ELEMENT_BITS)
        else
            Writer.WriteBool(false)
        end

        -- Compare. For each slot we're networking, determine if this is an slot being created,
        -- a slot being destroyed, or a slot being updated. When a slot is being updated, only
        -- use one true boolean bit to encode it. The decoder will not read for a 2nd bit. But
        -- in the case of additions/subtractions, the first bit is false, and the 2nd bit tells
        -- the decoder if this is an addition (true) or a subtraction (false). Likely saves little
        -- in terms of bits but encoding it with a variadic state like this doesn't hurt 

        -- Addition encodes will write a full update, meaning all data in the slot is written.

        -- Deviation encodes will write any data that has changed using equality operators. If the
        -- data type wishes to change this behavior, they'd have to override __eq. We may add some
        -- feature to allow different ways to manage this later, but that can come at a later date.

        -- Subtraction encodes write only the two booleans. The data will be destroyed on the other end.

        for I = 1, NetworkingSlots do
            local IsAddition     = Full or (not DeprivedState:HasElementSlot(I) and IdealState:HasElementSlot(I))
            local IsSubtraction  = not Full and (DeprivedState:HasElementSlot(I) and not IdealState:HasElementSlot(I))
            local IsDeviation    = not Full and (not IsAddition and not IsSubtraction)

            if IsDeviation then -- Write differences
                Writer.WriteBool(true)
                local DeprivedSlot = DeprivedState:GetElementSlot(I)
                local IdealSlot    = IdealState:GetElementSlot(I)
                Overlay.DeltaEncodeSlot(DeprivedSlot, IdealSlot, Writer, WriteToState, Full)
            elseif IsAddition then -- Write new slot
                Writer.WriteBool(false)
                Writer.WriteBool(true)

                local DeprivedSlot = DeprivedState:AllocElementSlot()
                local IdealSlot    = IdealState:GetElementSlot(I)
                Overlay.DeltaEncodeSlot(DeprivedSlot, IdealSlot, Writer, WriteToState, Full)
            elseif IsSubtraction then -- Delete slot
                Writer.WriteBool(false)
                Writer.WriteBool(false)
                DeprivedState:TryClearSlot(I)
            end
        end

        -- Write to deprived state how many elements are in the state, if applicable
        if WriteToState then
            DeprivedState.NumElements = IdealState.NumElements
        end
    end
end

-- Element type class
do
    local ElementTypes = Overlay.ElementTypes or {}
    Overlay.ElementTypes = ElementTypes

    local ElementTypesByIdx = Overlay.ElementTypesByIdx or {}
    Overlay.ElementTypesByIdx = ElementTypesByIdx

    local ElementBits = Overlay.ELEMENT_TYPE_BITS or 1
    Overlay.ELEMENT_TYPE_BITS = ElementBits

    local function BitsRequired(x)
        return x == 0 and 1 or math.floor(math.log(x, 2)) + 1
    end

    function Overlay.GetElementTypeIdx(Name)
        local TypeData = ElementTypes[Name]
        return TypeData and TypeData.Idx or error(string.format("Invalid type '%s' given to GetElementTypeIdx", Name))
    end

    function Overlay.GetElementType(Idx)
        local TypeData = ElementTypesByIdx[Idx]
        return TypeData and TypeData.TypeDef or error(string.format("Invalid type idx '%d' given to GetElementTypeIdx", Idx))
    end

    function Overlay.DefineElementType(Name, TypeDef)
        -- If the overlay element already exists, perform a rewrite without recalculating element type bits.
        if ElementTypes[Name] then
            ElementTypes[Name].TypeDef = TypeDef
            return
        end

        local Idx = table.Count(ElementTypes)
        ElementTypes[Name] = {
            TypeDef = TypeDef,
            Idx = Idx
        }
        ElementTypesByIdx[Idx] = ElementTypes[Name]
        -- Recalculate bits required to network element types
        Overlay.ELEMENT_TYPE_BITS = BitsRequired(Idx)

        -- Write a macro to the OverlayState class's metatable.
        Overlay.State["Add" .. Name] = function(self, ...)
            self:AddElement(Name, ...)
        end
    end
end

-- Ponder classes my beloved <3
local function Class(baseclass)
    return setmetatable({}, {__index = baseclass, __call = function(self, ...)
        local obj = setmetatable({}, {__index = self, __tostring = self.ToString})
        if self.__new then self.__new(obj, ...) end
        return obj
    end})
end

-- State class. This represents a single entities overlay state.
-- This can be allocated on a single entity (in the case of an entity performing its overlay functionality) or
-- in the case of per-player-per-entity tracking where delta-states need to be computed.
do
    Overlay.ElementSlot = Class()
    local ElementSlot = Overlay.ElementSlot

    Overlay.State = Class()
    local State = Overlay.State

    do
        function ElementSlot:__new()
            self.Type    = -1
            self.Data    = {}
            self.NumData = 0

            self.ChangedSinceLastUpdate = false
        end

        -- Bounded ipairs.
        local function IterElementData(A, I)
            I = I + 1
            if I > A.NumData then return end
            return I, A.Data[I]
        end

        function ElementSlot:IterateElementData() return IterElementData, self, 0 end
        function ElementSlot:NumElementData() return self.NumData end

        -- Does the data exist? Takes into account NumData rather than Data.
        function ElementSlot:HasElementData(Idx)
            if Idx > self.NumData then return false end
            return true
        end

        -- Gets the element data, accounting for NumData.
        function ElementSlot:GetElementData(Idx)
            if Idx > self.NumData then return nil end
            return self.Data[Idx]
        end

        function ElementSlot:SetElementData(Idx, Value)
            self.Data[Idx] = Value
            self.NumData = math.max(self.NumData, Idx)
        end
    end

    do
        function State:__new()
            self.ElementSlots = {}
            self.NumElements = 0
            self.ReliantStack = {}

            self.ChangedSinceLastUpdate = false
        end

        -- Prepares a write to the state.
        function State:Begin()
            self.NumElements = 0
            table.Empty(self.ReliantStack)
        end

        -- Ends a write to the state.
        function State:End()
            -- Currently does nothing, but its a good principle to have this in case its needed later.
        end

        local function ClearSlot(Slot)
            Slot.Type    = -1
            for I = 1, Slot.NumData do
                Slot.Data[I] = nil
            end
            Slot.NumData = 0
        end

        -- Tries to clear a slot, if it exists.
        function State:TryClearSlot(SlotIdx)
            local Slot = self.ElementSlots[SlotIdx]
            if Slot then
                ClearSlot(Slot)
            end
        end

        -- Allocates an element slot in the state. This increments NumElements as well.
        -- If the slot exists, it is wiped. If it doesn't, it is created.
        function State:AllocElementSlot()
            local SlotIdx = self.NumElements + 1

            local Slot
            if self.ElementSlots[SlotIdx] then
                Slot = self.ElementSlots[SlotIdx]
            else
                Slot = ElementSlot()
                self.ElementSlots[SlotIdx] = Slot
            end
            ClearSlot(Slot)

            self.NumElements = SlotIdx
            return self.ElementSlots[SlotIdx]
        end

        -- Marks the last slot as "reliant". It will be removed if no data was written afterwards.
        function State:MarkReliantSlot()
            self.ReliantStack[#self.ReliantStack + 1] = {
                ReliantIdx = self.NumElements
            }
        end

        -- Discards the last reliant slot if nothing else was written.
        function State:DiscardReliantSlot()
            local Slot = self.ReliantStack[#self.ReliantStack]
            if not Slot then return end

            table.remove(self.ReliantStack, #self.ReliantStack)
            if self.NumElements == Slot.ReliantIdx then
                -- Discard that element.
                table.remove(self.ElementSlots, Slot.ReliantIdx)
                -- Update everyone else in the stack so their idxs are correct
                for I = 1, #self.ReliantStack do
                    local StackItem = self.ReliantStack[I]
                    if StackItem.ReliantIdx > Slot.ReliantIdx then
                        StackItem.ReliantIdx = StackItem.ReliantIdx - 1
                    end
                end
                self.NumElements = self.NumElements - 1
            end
        end

        -- Adds an element to the overlay state.
        -- The varargs are written to the slots data table.
        -- Type is a name, which gets computed into its type idx.
        function State:AddElement(Type, ...)
            local TypeIdx = Overlay.GetElementTypeIdx(Type)

            local Slot = self:AllocElementSlot()
            Slot.Type = TypeIdx
            -- Copy varargs to data.
            Slot.NumData = select('#', ...)
            for I = 1, Slot.NumData do
                Slot.Data[I] = select(I, ...)
            end
        end

        -- Bounded ipairs.
        local function IterElementSlots(A, I)
            I = I + 1
            if I > A.NumElements then return end
            return I, A.ElementSlots[I]
        end

        function State:IterateElementSlots() return IterElementSlots, self, 0 end
        function State:NumElementSlots() return self.NumElements end

        -- Does the slot exist? Takes into account NumElements rather than Elements.
        function State:HasElementSlot(Idx)
            if Idx > self.NumElements then return false end
            return true
        end

        -- Gets the element slot, accounting for NumElements.
        function State:GetElementSlot(Idx)
            if Idx > self.NumElements then return nil end
            return self.ElementSlots[Idx]
        end
    end

    -- Write existing macros.
    for TypeName in pairs(Overlay.ElementTypes) do
        -- Write a macro to the OverlayState class's metatable.
        Overlay.State["Add" .. TypeName] = function(self, ...)
            self:AddElement(TypeName, ...)
        end
    end
end