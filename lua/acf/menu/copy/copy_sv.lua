local ACF      = ACF
local Messages = ACF.Utilities.Messages
local Copy     = ACF.Menu.Copy

--- Sends the entity's settings to the player's menu
function Copy.CopyFrom(Player, Entity, Pick)
	local Spawnable = IsValid(Entity) and ACF.Entities.SpawnFuncs[Entity:GetClass()]

	if not Copy.CanCopy(Entity) or not Entity.ACF_LiveData or not Spawnable then
		Messages.SendChat(Player, "Error", "#acf.menu.copy.unsupported")
		return false
	end

	ACF.Menu.SendCopy(Player, Entity, Pick)

	return true
end
