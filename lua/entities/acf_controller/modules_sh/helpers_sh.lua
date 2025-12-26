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

--- Sets a networked variable if the cached value has changed
function ENT.RecacheBindNW(Entity, SelfTbl, Key, Value, SetNWFunc)
	SelfTbl.CacheNW = SelfTbl.CacheNW or {}
	if SelfTbl.CacheNW[Key] == Value then return end
	SelfTbl.CacheNW[Key] = Value
	SetNWFunc(Entity, Key, Value)
end