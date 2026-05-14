local ACF  = ACF
local Text = "Mass : %s kg\n"

function ACF.CreateReceiverMenu(Data, Menu)

	Menu:AddLabel(Text:format(Data.Mass))

	ACF.SetClientData("PrimaryClass", "acf_receiver")
end
