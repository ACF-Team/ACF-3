local ACF    = ACF
local Fuel   = ACF.Mobility.Fuel or {}
local Groups = Fuel.Groups or {} -- Parent entity -> { Engines = {}, Tanks = {} }

ACF.Mobility.Fuel = Fuel
Fuel.Groups       = Groups

-- Engines only draw from tanks sharing their direct parent. Engine.FuelTanks and Tank.Engines are
-- kept in sync here so link sources, E2/SF and the overlays keep working.

local function Pair(Engine, Tank)
	if not Engine.FuelTypes[Tank.FuelType] then return end

	Engine.FuelTanks[Tank] = true
	Tank.Engines[Engine]   = true

	Engine:UpdateOverlay()
end

--- Drops cached tanks of engines that should now prefer this tank.
function Fuel.Notify(Tank)
	local Priority = Tank.FuelPriority

	for Engine in pairs(Tank.Engines) do
		local Current = Engine.FuelTank

		if Current and Current ~= Tank and Priority < Current.FuelPriority then
			Engine.FuelTank = nil
		end
	end
end

function Fuel.Leave(Entity)
	local Parent = Entity.ACF_FuelParent
	if Parent == nil then return end

	Entity.ACF_FuelParent = nil

	local Group = Groups[Parent]

	if Group then
		Group.Engines[Entity] = nil
		Group.Tanks[Entity]   = nil

		if not next(Group.Engines) and not next(Group.Tanks) then
			Groups[Parent] = nil
		end
	end

	if Entity.IsACFEngine then
		for Tank in pairs(Entity.FuelTanks) do
			Tank.Engines[Entity] = nil
		end

		Entity.FuelTanks = {}
		Entity.FuelTank  = nil
	else
		for Engine in pairs(Entity.Engines) do
			Engine.FuelTanks[Entity] = nil

			if Engine.FuelTank == Entity then Engine.FuelTank = nil end

			Engine:UpdateOverlay()
		end

		Entity.Engines = {}
	end
end

--- (Re)registers an engine or fuel tank under its current parent.
function Fuel.Join(Entity)
	Fuel.Leave(Entity)

	local Parent = Entity:GetParent()
	if not IsValid(Parent) then return end

	local Group = Groups[Parent]

	if not Group then
		Group = { Engines = {}, Tanks = {} }
		Groups[Parent] = Group
	end

	Entity.ACF_FuelParent = Parent

	if Entity.IsACFEngine then
		Group.Engines[Entity] = true
		Entity.FuelTank = nil

		for Tank in pairs(Group.Tanks) do
			Pair(Entity, Tank)
		end
	else
		Group.Tanks[Entity] = true

		for Engine in pairs(Group.Engines) do
			Pair(Engine, Entity)
		end

		Fuel.Notify(Entity)
	end
end
