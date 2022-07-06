local Classes = ACF.Classes


function Classes.AddSboxLimit(Data)
	if CLIENT then return end
	if ConVarExists("sbox_max" .. Data.Name) then return end

	CreateConVar("sbox_max" .. Data.Name,
				Data.Amount,
				FCVAR_ARCHIVE + FCVAR_NOTIFY,
				Data.Text or "")
end
