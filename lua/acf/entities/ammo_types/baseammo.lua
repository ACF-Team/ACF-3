local Classes = ACF.Classes

Classes.DefineClass("ACF.Ammunition.BaseAmmo", function()
	if SERVER then
		-- Generic round-conversion wrapper shared by all ammo types. Operates on the instance:
		-- reads its own round inputs + weapon back-reference (self.Weapon). Subtypes provide
		-- VerifyData/BaseConvert; this stamps the weapon/ammo identity onto the bullet data.
		function CLASS:ServerConvert()
			self:VerifyData()

			local Data   = self:BaseConvert()
			local Weapon = self.Weapon

			-- V2 weapon instance -> FQN; grouped/shim weapon (missile/piledriver) -> its .ID.
			Data.WeaponType = Weapon and (Weapon.GetType and Classes.GetTypeName(Weapon:GetType()) or Weapon.ID)
			Data.AmmoType   = Classes.GetTypeName(self:GetType())

			return Data
		end
	end
end)

Classes.AddSboxLimit({
	Name   = "_acf_ammo",
	Amount = 32,
	Text   = "Maximum amount of ACF ammo crates a player can create."
})
