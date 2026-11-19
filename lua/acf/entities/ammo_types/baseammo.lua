local Classes = ACF.Classes

Classes.DefineClass("ACF.Ammunition.BaseAmmo", function(CLASS)
	-- What a crate shows for this kind of round, set from the round list in the menu.
	-- Not menu fields so they don't count when comparing or converting rounds
	FIELD("String",  "KindName",      {Default = "", MaxLength = 24, SingleLine = true})
	FIELD("Boolean", "OverrideColor", {Default = false})
	FIELD("Number",  "KindColor",     {Default = 0xFFFFFF, Min = 0, Max = 0xFFFFFF, Decimals = 0}) -- Tracer color as 0xRRGGBB, crate color unless OverrideColor

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
