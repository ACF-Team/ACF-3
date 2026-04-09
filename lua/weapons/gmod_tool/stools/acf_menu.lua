TOOL.Name = "ACF Menu"
TOOL.Category = "Construction"

if CLIENT then
	language.Add("tool.acf_menu.name", "Extendable Combat Framework")
	language.Add("tool.acf_menu.desc", "Main menu for the ACF addon")

	TOOL.BuildCPanel = function(Panel)
		local BasePanel = ACF.InitMenuReloadableBase(Panel, "acf_reload_main_menu", "CreateMainMenu")
		Panel:AddItem(BasePanel)
	end
end

function TOOL:LeftClick(Trace)
	if CLIENT then return true end
	if Trace.HitSky then return false end

	local Player = self:GetOwner()
	local SpawnClass = ACF.GetDataVar("SpawnClass", "ToolGun", Player)
	local Entity = Trace.Entity

	if not Player:KeyDown(IN_SPEED) then -- Spawning/Updating
		if not SpawnClass or SpawnClass == "" then return false end

		local DataVarKVs = ACF.GetDataVars(SpawnClass, Player)
		if DataVarKVs then DataVarKVs = DataVarKVs[SpawnClass] end -- Returned results are in the format {SpawnClass = {DataVarKVs}}

		if IsValid(Entity) and Entity:GetClass() == SpawnClass then
			ACF.UpdateEntityData(Entity, DataVarKVs)
			return true
		end

		local Position = Trace.HitPos + Trace.HitNormal * 128
		local Angles   = Trace.HitNormal:Angle():Up():Angle()
		local Success, Result = ACF.SpawnEntity(SpawnClass, Player, Position, Angles, DataVarKVs, false)

		if Success then
			local PhysObj = Result:GetPhysicsObject()

			if Result.ACF_PostMenuSpawn then Result:ACF_PostMenuSpawn() end
			ACF.DropToFloor(Result)

			Result:SetSpawnEffect(true)

			if IsValid(PhysObj) then
				PhysObj:EnableMotion(false)
			end
		else
			print(Player, "Error", "Couldn't create entity: " .. Result)
		end
		return Success
	else -- Copying settings
		if not IsValid(Entity) then return false end
		if Entity:GetClass() ~= SpawnClass then return false end

		local DataVarKVs = Entity.ACF_LiveData
		ACF.SetDataVars({[SpawnClass] = DataVarKVs}, Player)
	end
end

function TOOL:RightClick(_)
	return true
end

function TOOL:Reload(_)
	return true
end

function TOOL:Think()
	-- print("thinking")
end

function TOOL:Deploy()
	-- print("deploying")
end

function TOOL:Holster()
	-- print("holstering")
end

function TOOL:DrawHud()
	-- print("drawing hud")
end

function TOOL:DrawTOOLScreen(_, _)
	-- print("drawing world")
end