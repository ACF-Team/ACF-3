-- Toolgun ghost-preview system for the ACF menu tool.
--
-- The old stage/operation state machine (with its ACF_ToolNetVars networking, RegisterOperation/
-- RegisterToolInfo, SetToolMode and LoadToolFunctions) used to live here. It has been replaced by the
-- client-driven menu framework in lua/acf/menu/framework/ (contexts + named actions + send-on-commit),
-- so this file now provides only the ghost entity that a Preview-marked spawn action shows under the
-- player's aim.

local ACF = ACF

do -- Ghost entity handling
	local ModelData        = ACF.ModelData
	local ShouldRun        = not SERVER
	local DrawingSecondary = false
	local DefaultScale     = Vector(1, 1, 1)
	local ToolEnt
	local GhostData = {
		Primary   = {Model = "models/props_borealis/bluebarrel001.mdl", Material = "", Scale = Vector(DefaultScale), AbsoluteScale = false, PosOffset = nil, AngOffset = nil},
		Secondary = {Model = "", Material = "", Scale = Vector(DefaultScale), AbsoluteScale = false, PosOffset = nil, AngOffset = nil},
	}
	ACF.GhostEntityData = ACF.GhostEntityData or GhostData

	local function MakeGhostEntity(Tool, Model, Position, Angles)
		-- Release the old ghost entity
		Tool:ReleaseGhostEntity()

		-- Don't allow ragdolls/effects to be ghosts
		if not util.IsValidProp(Model) then return end

		if CLIENT then
			Tool.GhostEntity = ents.CreateClientProp(Model)
		else
			Tool.GhostEntity = ents.Create("prop_physics")
		end

		-- If there's too many entities we might not spawn..
		if not IsValid(Tool.GhostEntity) then
			Tool.GhostEntity = nil
			return
		end

		Tool.GhostEntity:SetModel(Model)
		Tool.GhostEntity:SetPos(Position)
		Tool.GhostEntity:SetAngles(Angles)
		Tool.GhostEntity:Spawn()

		-- We do not want physics at all
		Tool.GhostEntity:PhysicsDestroy()

		Tool.GhostEntity:SetMoveType(MOVETYPE_NONE)
		Tool.GhostEntity:SetNotSolid(true)
		Tool.GhostEntity:SetRenderMode(RENDERMODE_TRANSCOLOR)
		Tool.GhostEntity:SetColor(Color(255, 255, 255, 150))

		-- Do not save this thing in saves/dupes
		Tool.GhostEntity.DoNotDuplicate = true

		-- Mark this entity as ghost prop for other code
		Tool.GhostEntity.IsToolGhost = true

		return Tool.GhostEntity
	end

	local function GetModelDimensions(EntData)
		local Scale = EntData.Scale
		local ModelSize = ModelData.GetModelSize(EntData.Model)
		if not ModelSize then return Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0) end

		if Scale and not Scale:IsEqualTol(DefaultScale, 0) and not EntData.AbsoluteScale then
			Scale = Scale / ModelSize
		end

		local ModelMesh = ModelData.GetModelMesh(EntData.Model, Scale)

		return ModelMesh, ModelSize, Scale
	end

	local function ModifyGhostEntity(GhostEnt, EntKey)
		local EntData = GhostData[EntKey]
		GhostEnt:SetModel(EntData.Model)

		GhostEnt.ModelMesh, GhostEnt.ModelSize, GhostEnt.Scale = GetModelDimensions(EntData)
		local ModelMesh, Scale = GhostEnt.ModelMesh, GhostEnt.Scale

		if Scale then
			local ScaleMatrix = Matrix()
			ScaleMatrix:Scale(Scale)
			GhostEnt:EnableMatrix("RenderMultiply", ScaleMatrix)

			if ModelMesh then
				GhostEnt:PhysicsInitMultiConvex(ModelMesh)
				GhostEnt:EnableCustomCollisions(true)
				GhostEnt:SetRenderBounds(GhostEnt:GetCollisionBounds())
				GhostEnt:DrawShadow(false)

				local PhysObj = GhostEnt:GetPhysicsObject()

				if IsValid(PhysObj) then
					PhysObj:EnableMotion(false)
					PhysObj:Sleep()
				end
			end
		end

		if EntData.Material then
			GhostEnt:SetMaterial(EntData.Material)
		end
	end

	function ACF.CreateGhostEntity(Tool)
		if not ShouldRun then return end

		local Player = Tool:GetOwner()
		if not IsValid(Player) then return end

		local CurWeapon = Player:GetActiveWeapon()
		if not IsValid(CurWeapon) or CurWeapon:GetClass() ~= "gmod_tool" then return end

		local CurTool = Player:GetTool()
		if not CurTool or CurTool.Name ~= "#tool.acf_menu.menu_name" then return end

		local EntKey  = DrawingSecondary and "Secondary" or "Primary"
		local EntData = GhostData[EntKey]

		if EntData.Model then
			local Trace    = Player:GetEyeTrace()
			local Position = Trace.HitPos + (Trace.HitNormal * 128) + (EntData.PosOffset or vector_origin)
			local Angles   = Trace.HitNormal:Angle():Up():Angle() + (EntData.AngOffset or angle_zero)

			MakeGhostEntity(Tool, EntData.Model, Position, Angles)

			timer.Simple(0, function()
				local GhostEnt = Tool.GhostEntity
				if not IsValid(GhostEnt) then return end

				ToolEnt = Tool

				ModifyGhostEntity(GhostEnt, EntKey)
			end)
		end
	end

	function ACF.UpdateGhostEntity(NewGhostData)
		if not ShouldRun or not istable(NewGhostData) then return end

		for EntKey, EntData in pairs(NewGhostData) do
			for DataKey, DataVal in pairs(EntData) do
				GhostData[EntKey][DataKey] = DataVal
			end
		end

		timer.Simple(0, function()
			local EntKey = DrawingSecondary and "Secondary" or "Primary"
			if not ToolEnt then return end

			if not IsValid(ToolEnt.GhostEntity) then return end

			ModifyGhostEntity(ToolEnt.GhostEntity, EntKey)
		end)
	end

	function ACF.RenderGhostEntity(Tool)
		if not ShouldRun then return end

		local GhostEnt = Tool.GhostEntity
		if not IsValid(GhostEnt) then return end

		local Player = Tool:GetOwner()
		if not IsValid(Player) then return end

		local Trace = Player:GetEyeTrace()
		local TraceEnt = Trace.Entity
		local ShouldDrawSecondary = Player:KeyDown(IN_SPEED)

		-- The active page reports its primary/secondary spawn classes off its contexts; we use them only
		-- to snap the ghost onto an existing same-class entity (update-in-place preview).
		local MenuPrimary, MenuSecondary
		if ACF.Menu and ACF.Menu.ActivePage and ACF.Menu.GetGhostClasses then
			MenuPrimary, MenuSecondary = ACF.Menu.GetGhostClasses()
		end

		local SecondaryClass = MenuSecondary or "N/A"
		local UpdateClass    = ShouldDrawSecondary and SecondaryClass or MenuPrimary
		local EntKey  = DrawingSecondary and "Primary" or "Secondary"
		local EntData = GhostData[EntKey]
		local Position, Angles

		if DrawingSecondary ~= ShouldDrawSecondary and SecondaryClass ~= "N/A" then
			DrawingSecondary = ShouldDrawSecondary
			ModifyGhostEntity(GhostEnt, EntKey)
		end

		local CanUpdate = IsValid(TraceEnt) and TraceEnt:GetClass() == UpdateClass

		if CanUpdate then
			Position = TraceEnt:GetPos() + (EntData.PosOffset or vector_origin)
			Angles   = TraceEnt:GetAngles() + (EntData.AngOffset or angle_zero)
		else
			Position = Trace.HitPos + (Trace.HitNormal * 128) + (EntData.PosOffset or vector_origin)
			Angles   = Trace.HitNormal:Angle():Up():Angle() + (EntData.AngOffset or angle_zero)
		end

		GhostEnt:SetPos(Position)
		GhostEnt:SetAngles(Angles)

		if not CanUpdate then
			ACF.DropToFloor(GhostEnt)
		end
	end

	function ACF.ReleaseGhostEntity(Tool)
		if not ShouldRun then return end

		Tool:ReleaseGhostEntity()
	end

	function ACF.GetGhostEntity()
		return ToolEnt and ToolEnt.GhostEntity
	end

	local HoldOverlay = {} -- Entities to keep overlay on for

	-- Respects occlusion
	hook.Add("PreDrawOpaqueRenderables", "ACF_Menu_DrawOverlay", function()
		local Player = LocalPlayer()
		local Trace = Player:GetEyeTrace()
		for Entity in pairs(HoldOverlay) do
			if not IsValid(Entity) then continue end
			if not Entity.DrawOverlay then continue end
			if Entity.CanDrawOverlay and not Entity:CanDrawOverlay() then continue end

			Entity:DrawOverlay(Trace)
		end
	end)

	function ACF.RunHoldOverlay(Tool)
		local isFirstTimePredicted = IsFirstTimePredicted()
		if not isFirstTimePredicted then return end

		local Player = Tool:GetOwner()
		if Player:KeyPressed(IN_WALK) then
			local Trace = Player:GetEyeTrace()
			local Entity = Trace.Entity
			if not IsValid(Entity) then return end
			if not Entity.DrawOverlay then return end
			if HoldOverlay[Entity] then HoldOverlay[Entity] = nil else HoldOverlay[Entity] = true end

			local Weapon = Tool.Weapon
			Weapon:DoShootEffect( Trace.HitPos, Trace.HitNormal, Trace.Entity, Trace.PhysicsBone, isFirstTimePredicted )
		end
	end
end
