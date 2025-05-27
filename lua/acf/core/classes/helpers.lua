local Classes = ACF.Classes

--- Adds an sbox limit for this class
--- @param Data {Name:string, Amount:number, Text:string}
function Classes.AddSboxLimit(Data)
	if CLIENT then return end

	local ConVarName = "sbox_max" .. Data.Name

	if ConVarExists(ConVarName) then return end

	CreateConVar(ConVarName,
				Data.Amount,
				FCVAR_ARCHIVE + FCVAR_NOTIFY,
				Data.Text or "")

	function Data:AddCount(Ply, Ent)
		return Ply:AddCount(self.Name, Ent)
	end

	function Data:CheckLimit(Ply)
		return Ply:CheckLimit(self.Name)
	end
end
