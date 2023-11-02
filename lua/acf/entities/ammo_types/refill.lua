local ACF    = ACF
local Types  = ACF.Classes.AmmoTypes
local Sounds = ACF.Utilities.Sounds
local Ammo   = Types.Register("Refill", "AP")


function Ammo:OnLoaded()
	self.Name        = "Refill"
	self.Model       = "models/Items/BoxSRounds.mdl"
	self.Description = "Provides supplies to other ammo crates."
	self.Blacklist   = {}
end

function Ammo:GetDisplayData()
	return {}
end

function Ammo:BaseConvert(ToolData)
	local ProjMass = 5.5 * ACF.SteelDensity
	local PropMass = 0.001

	return {
		Id			= "12.7mmMG",
		Type		= ToolData.AmmoType,
		Caliber		= 12.7,
		ProjMass	= ProjMass,
		PropMass	= PropMass,
		CartMass	= ProjMass + PropMass,
		FillerMass	= 0.001,
		DragCoef	= 0,
		Tracer		= 0,
		MuzzleVel	= 0,
		RoundVolume	= 35,
	}
end

function Ammo:VerifyData()
end

if SERVER then
	util.AddNetworkString("ACF_RefillEffect")
	util.AddNetworkString("ACF_StopRefillEffect")

	local MaxDistance  = ACF.RefillDistance * ACF.RefillDistance
	local ActiveCrates = ACF.AmmoCrates

	local function CanRefillCrate(Refill, Crate, Distance)
		if Refill == Crate then return false end
		if not Refill:CanConsume() then return false end
		if Crate.IsRefill then return false end
		if Crate.Ammo >= Crate.Capacity then return false end
		if Crate.Disabled then return false end
		if Crate.Damaged then return false end

		return Distance <= MaxDistance
	end

	local function RefillEffect(Entity)
		net.Start("ACF_RefillEffect")
			net.WriteEntity(Entity)
		net.Broadcast()
	end

	local function StopRefillEffect(Entity)
		net.Start("ACF_StopRefillEffect")
			net.WriteEntity(Entity)
		net.Broadcast()
	end

	local function RefillCrates(Refill)
		local Position = Refill:GetPos()

		for Crate in pairs(ActiveCrates) do
			local Distance = Position:DistToSqr(Crate:GetPos())

			if CanRefillCrate(Refill, Crate, Distance) then
				local Supply = math.ceil(ACF.RefillSpeed / Crate.BulletData.CartMass / Distance ^ 0.5)
				local Transfer = math.min(Supply, Refill.Ammo, Crate.Capacity - Crate.Ammo)

				if hook.Run("ACF_CanRefill", Refill, Crate, Transfer) == false then continue end

				if not next(Refill.SupplyingTo) then
					RefillEffect(Refill)
				end

				if not Refill.SupplyingTo[Crate] then
					Refill.SupplyingTo[Crate] = true

					Crate:CallOnRemove("ACF Refill " .. Refill:EntIndex(), function()
						Refill.SupplyingTo[Crate] = nil
					end)
				end

				Crate:Consume(-Transfer)
				Refill:Consume(Transfer)

				Sounds.SendSound(Crate, "items/ammo_pickup.wav", 70, 100, 0.5)
				Sounds.SendSound(Refill, "items/ammo_pickup.wav", 70, 100, 0.5)

			elseif Refill.SupplyingTo[Crate] then
				Refill.SupplyingTo[Crate] = nil

				Crate:RemoveCallOnRemove("ACF Refill " .. Refill:EntIndex())

				if not next(Refill.SupplyingTo) then
					StopRefillEffect(Refill)
				end
			end
		end
	end

	function Ammo:OnFirst(Entity)
		if not Entity.IsACFAmmoCrate then return end

		if not Entity.SupplyingTo then
			Entity.SupplyingTo = {}
		end

		Entity.IsRefill   = true
		Entity.Unlinkable = true

		timer.Create("ACF Refill " .. Entity:EntIndex(), 1, 0, function()
			if not IsValid(Entity) then return end

			RefillCrates(Entity)
		end)
	end

	function Ammo:OnLast(Entity)
		if not Entity.IsRefill then return end

		local CallName = "ACF Refill " .. Entity:EntIndex()

		for Crate in pairs(Entity.SupplyingTo) do
			Crate:RemoveCallOnRemove(CallName)
		end

		Entity.SupplyingTo = nil
		Entity.IsRefill    = nil
		Entity.Unlinkable  = nil

		Entity:SetNW2Float("FillerMass", 0)

		StopRefillEffect(Refill)

		timer.Remove(CallName)
	end

	function Ammo:Create()
		print("Someone is trying to fire Refill bullets")
	end

	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "Refill")
		Entity:SetNW2Float("FillerMass", BulletData.FillerMass)
	end

	function Ammo:GetCrateName()
		return "Ammo Refill", "Refill", "Ammo Refill Crate"
	end

	function Ammo:GetCrateText()
		return ""
	end
else
	function Ammo:SetupAmmoMenuSettings(Settings)
		Settings.SuppressControls    = true
		Settings.SuppressInformation = true
	end

	function Ammo:AddAmmoPreview(Preview, Setup, ...)
		Ammo.BaseClass.AddAmmoPreview(self, Preview, Setup, ...)

		Setup.FOV = 115
	end
end
