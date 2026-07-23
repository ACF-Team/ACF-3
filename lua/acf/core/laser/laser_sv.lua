util.AddNetworkString("ACF_SetupLaserSource")
util.AddNetworkString("ACF_ClearLaserSource")
util.AddNetworkString("ACF_SyncLaserSources")
util.AddNetworkString("ACF_UpdateLaserFilter")

local Sources = ACF.LaserSources

function ACF.SetupLaserSource(Entity, Data)
	if not IsValid(Entity) then return end
	if not istable(Data) then return end

	local LaserData = ACF.AddLaserSource(Entity, {
		NetVar = Data.NetVar,
		Offset = Data.Offset,
		Direction = Data.Direction,
		Filter = Data.Filter
	})

	-- We have to wait for the entity to be created on the clientside
	timer.Simple(0.1, function()
		net.Start("ACF_SetupLaserSource")
			net.WriteEntity(Entity)
			net.WriteTable(LaserData)
		net.Broadcast()
	end)
end

function ACF.ClearLaserSource(Entity)
	if not IsValid(Entity) then return end

	ACF.RemoveLaserSource(Entity)

	net.Start("ACF_ClearLaserSource")
		net.WriteEntity(Entity)
	net.Broadcast()
end

function ACF.FilterLaserEntity(Entity)
	if not IsValid(Entity) then return end

	for Source, Data in pairs(Sources) do
		local Filter = Data.Filter

		Filter[#Filter + 1] = Entity

		if Source.UpdateFilter then
			Source:UpdateFilter(Filter)
		end
	end

	net.Start("ACF_UpdateLaserFilter")
		net.WriteEntity(Entity)
	net.Broadcast()
end

hook.Add("ACF_OnLoadPlayer", "ACF Laser Setup", function(Player)
	net.Start("ACF_SyncLaserSources")
		net.WriteTable(Sources)
	net.Send(Player)
end)

hook.Add("ACF_OnLaunchMissile", "ACF Laser Filter Update", function(Missile)
	ACF.FilterLaserEntity(Missile)
end)
