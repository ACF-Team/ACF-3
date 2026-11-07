--- Whether two values are equal, tables are compared recursively by value.
--- @param A any
--- @param B any
--- @return boolean
function ACF.SameData(A, B)
	if A == B then return true end
	if not istable(A) or not istable(B) then return false end

	for Key, Value in pairs(A) do
		if not ACF.SameData(Value, B[Key]) then return false end
	end

	for Key in pairs(B) do
		if A[Key] == nil then return false end
	end

	return true
end
