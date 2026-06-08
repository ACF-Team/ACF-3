DEFINE_BASECLASS "acf_base_simple"

ENT.PrintName     = "ACF Armor Controller"
ENT.WireDebugName = "ACF Armor Controller"
ENT.PluralName    = "ACF Armor Controller2"
ENT.IsACFEntity = true
ENT.IsACFArmorController = true
ENT.ACF_Limit      = 4
ENT.ACF_PreventArmoring = true

cleanup.Register("acf_armor_controller")

properties.Add("armorcontroller", {
	MenuLabel     = "Edit armor controller",
	Order         = 300001,
	MenuIcon      = "icon16/brick_edit.png",

	Filter = function(self, ent, pl)
		if not IsValid(ent) then return false end
		if not gamemode.Call("CanProperty", pl, "acf_armor_controller", ent) then return false end
		return ent.IsACFArmorController or false
	end,

	Action = function(self, ent) -- The action to perform upon using the property ( Clientside )
		self:MsgStart()
		net.WriteEntity(ent)
		self:MsgEnd()
	end,

	Receive = function(self, length, ply) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()

		if ( !properties.CanBeTargeted( ent, ply ) ) then return end
		if ( !self:Filter( ent, ply ) ) then return end

		print("test")
	end
})