--- Sets a wire output if the cached value has changed
function ENT.RecacheBindOutput(Entity, SelfTbl, Output, Value)
	if SelfTbl.Outputs[Output].Value == Value then return end
	WireLib.TriggerOutput(Entity, Output, Value)
end

function ENT.RecacheBindState(SelfTbl, Key, Value)
	if SelfTbl.KeyStates[Key] == Value then return end
	SelfTbl.KeyStates[Key] = Value
end

function ENT.GetKeyState(SelfTbl, Key)
	return SelfTbl.KeyStates[Key] or false
end

-- Rebindable action states, set from ACF_Controller_Action net messages instead of raw IN_* keys
function ENT.RecacheActionState(SelfTbl, ActionID, Value)
	if SelfTbl.ActionStates[ActionID] == Value then return false end
	SelfTbl.ActionStates[ActionID] = Value
	if Value then SelfTbl.ActionLatches[ActionID] = true end
	return true
end

function ENT.GetBindState(SelfTbl, ActionID)
	return SelfTbl.ActionStates[ActionID] or false
end

--- Same as GetBindState, but also true once for a press that was released before this was checked.
function ENT.ConsumeBindState(SelfTbl, ActionID)
	local Latched = SelfTbl.ActionLatches[ActionID]
	SelfTbl.ActionLatches[ActionID] = nil

	return Latched or SelfTbl.ActionStates[ActionID] or false
end

--- Sets a networked variable if the cached value has changed
function ENT.RecacheBindNW(Entity, SelfTbl, Key, Value, SetNWFunc)
	SelfTbl.CacheNW = SelfTbl.CacheNW or {}
	if SelfTbl.CacheNW[Key] == Value then return end
	SelfTbl.CacheNW[Key] = Value
	SetNWFunc(Entity, Key, Value)
end