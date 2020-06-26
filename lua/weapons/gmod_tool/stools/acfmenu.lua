
local cat = ((ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction");

TOOL.Category		= cat
TOOL.Name			= "#Tool.acfmenu.listname"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "type" ] = "gun"
TOOL.ClientConVar[ "id" ] = "12.7mmMG"

TOOL.ClientConVar[ "data1" ] = "12.7mmMG"
TOOL.ClientConVar[ "data2" ] = "AP"
TOOL.ClientConVar[ "data3" ] = 0
TOOL.ClientConVar[ "data4" ] = 0
TOOL.ClientConVar[ "data5" ] = 0
TOOL.ClientConVar[ "data6" ] = 0
TOOL.ClientConVar[ "data7" ] = 0
TOOL.ClientConVar[ "data8" ] = 0
TOOL.ClientConVar[ "data9" ] = 0
TOOL.ClientConVar[ "data10" ] = 0
TOOL.ClientConVar[ "data11" ] = 24
TOOL.ClientConVar[ "data12" ] = 24
TOOL.ClientConVar[ "data13" ] = 24

cleanup.Register( "acfmenu" )

if CLIENT then
	language.Add( "Tool.acfmenu.listname", "ACF Menu" )
	language.Add( "Tool.acfmenu.name", "Armored Combat Framework" )
	language.Add( "Tool.acfmenu.desc", "Spawn the Armored Combat Framework weapons and ammo" )
	language.Add( "Tool.acfmenu.0", "Left click to spawn the entity of your choice, Right click to link an entity to another (+Use to unlink)" )
	language.Add( "Tool.acfmenu.1", "Right click to link the selected sensor to a pod" )

	language.Add( "Undone_ACF Entity", "Undone ACF Entity" )
	language.Add( "Undone_acf_engine", "Undone ACF Engine" )
	language.Add( "Undone_acf_gearbox", "Undone ACF Gearbox" )
	language.Add( "Undone_acf_ammo", "Undone ACF Ammo" )
	language.Add( "Undone_acf_gun", "Undone ACF Gun" )
	language.Add( "SBoxLimit_acf_gun", "You've reached the ACF Guns limit!" )
	language.Add( "SBoxLimit_acf_rack", "You've reached the ACF Launchers limit!" )
	language.Add( "SBoxLimit_acf_ammo", "You've reached the ACF Explosives limit!" )
	language.Add( "SBoxLimit_acf_sensor", "You've reached the ACF Sensors limit!" )

	local DrawBoxes = CreateConVar("acf_drawboxes", 1, FCVAR_ARCHIVE, "Whether or not to draw hitboxes on ACF entities", 0, 1)

	function TOOL.BuildCPanel( CPanel )

		local pnldef_ACFmenu = vgui.RegisterFile( "acf/client/sk_menu.lua" )

		-- create
		local DPanel = vgui.CreateFromTable( pnldef_ACFmenu )
		CPanel:AddPanel( DPanel )

	end

	-- "Hitbox" colors
	local Sensitive      = Color(255, 0, 0, 50)
	local NotSoSensitive = Color(255, 255, 0, 50)

	-- Ammo overlay colors
	local Blue   = Color(0, 127, 255, 65)
	local Orange = Color(255, 127, 0, 65)
	local Green  = Color(0, 255, 0, 65)
	local Red    = Color(255,0,0,65)

	function TOOL:DrawHUD()
		if DrawBoxes:GetBool() then
			local Ent = LocalPlayer():GetEyeTrace().Entity

			if IsValid(Ent) then
				cam.Start3D()
					render.SetColorMaterial()

					if Ent.HitBoxes then -- Draw "hitboxes"
						for _, Tab in pairs(Ent.HitBoxes) do
							render.DrawWireframeBox(Ent:LocalToWorld(Tab.Pos), Ent:LocalToWorldAngles(Tab.Angle), Tab.Scale * -0.5, Tab.Scale * 0.5, Tab.Sensitive and Sensitive or NotSoSensitive)
						end
					end

					local FinalAmmo = 0

					if Ent.HasBoxedAmmo then FinalAmmo = math.floor((Ent.Ammo or 0) / Ent.MagSize) else FinalAmmo = (Ent.Ammo or 0) end

					local RoundsDisplay = 0
					if FinalAmmo > 0 and Ent.FitPerAxis then
						local RoundAngle = Ent:LocalToWorldAngles(Ent.LocalAng or Angle())

						local StartPos = ((Ent.FitPerAxis.x - 1) * (Ent.RoundSize.x + Ent.Spacing) * RoundAngle:Forward()) +
						((Ent.FitPerAxis.y - 1) * (Ent.RoundSize.y + Ent.Spacing) * RoundAngle:Right()) +
						((Ent.FitPerAxis.z - 1) * (Ent.RoundSize.z + Ent.Spacing) * RoundAngle:Up())

						if not Ent.BulkDisplay then
							for RX = 1, Ent.FitPerAxis.x do
								for RY = 1, Ent.FitPerAxis.y do
									for RZ = 1, Ent.FitPerAxis.z do
										local LocalPos = ((RX - 1) * (Ent.RoundSize.x + Ent.Spacing) * -RoundAngle:Forward()) +
										((RY - 1) * (Ent.RoundSize.y + Ent.Spacing) * -RoundAngle:Right()) +
										((RZ - 1) * (Ent.RoundSize.Z + Ent.Spacing) * -RoundAngle:Up())

										if RoundsDisplay < FinalAmmo then
											local C = Ent.IsRound and Blue or Ent.HasBoxedAmmo and Green or Orange

											render.DrawWireframeBox(Ent:LocalToWorld(Ent:OBBCenter()) + (StartPos / 2) + LocalPos, RoundAngle, -Ent.RoundSize / 2, Ent.RoundSize / 2, C)
											RoundsDisplay = RoundsDisplay + 1
										end

										if RoundsDisplay == FinalAmmo then break end
									end
								end
							end
						else -- Basic bitch box that scales according to ammo, only for bulk display
							local AmmoPerc = (Ent.Ammo or 1) / (Ent.MaxAmmo or 1)
							local SizeAdd = Vector(Ent.Spacing,Ent.Spacing,Ent.Spacing) * Ent.FitPerAxis
							local BulkSize = (Ent.FitPerAxis * Ent.RoundSize * (Vector(1,AmmoPerc,1))) + SizeAdd
							render.DrawWireframeBox(Ent:LocalToWorld(Ent:OBBCenter()) + (RoundAngle:Right() * (Ent.FitPerAxis.y * Ent.RoundSize.y) * 0.5 * (1 - AmmoPerc)),RoundAngle,-BulkSize / 2, BulkSize / 2, Red)
						end
					end
				cam.End3D()
			end
		end
	end
end

-- Spawn/update functions
function TOOL:LeftClick(Trace)
	if CLIENT then return true end
	if not IsValid(Trace.Entity) and not Trace.Entity:IsWorld() then return false end

	local Player = self:GetOwner()
	local Type = self:GetClientInfo("type")
	local Id = self:GetClientInfo("id")
	local TypeId

	if Type == "Ammo" then -- I am hackerman
		TypeId = { ent = "acf_ammo" }
	else
		TypeId = ACF.Weapons[Type][Id]
	end

	if not TypeId then return false end

	local DupeClass = duplicator.FindEntityClass(TypeId.ent)

	if not DupeClass then
		print("Didn't find entity duplicator records")
		return false
	end

	local Class = TypeId.ent
	local ArgList = list.Get("ACFCvars")
	local ArgTable = {
		Player,
		Trace.HitPos + Trace.HitNormal * 32,
		Trace.HitNormal:Angle():Up():Angle(),
	}

	-- Reading the list packaged with the ent to see what client CVar it needs
	for K, V in ipairs(ArgList[Class]) do
		ArgTable[K + 3] = self:GetClientInfo(V)
	end

	if Trace.Entity:GetClass() == Class and Trace.Entity.CanUpdate then
		local Success, Message = Trace.Entity:Update(ArgTable)

		ACF_SendNotify(Player, Success, Message)
	else
		-- Using the Duplicator entity register to find the right factory function
		local Ent = DupeClass.Func(unpack(ArgTable))

		if not IsValid(Ent) then
			ACF_SendNotify(Player, false, "Couldn't create entity.")
			return false
		end

		Ent:Activate()
		Ent:DropToFloor()

		if CPPI then
			Ent:CPPISetOwner(Player)
		end

		local PhysObj = Ent:GetPhysicsObject()

		if IsValid(PhysObj) then
			PhysObj:EnableMotion(false)
			PhysObj:Sleep()
		end

		undo.Create(Class)
			undo.AddEntity(Ent)
			undo.SetPlayer(Player)
		undo.Finish()
	end

	return true
end

-- Link/unlink functions
function TOOL:RightClick(Trace)
	if not IsValid(Trace.Entity) then return false end
	if CLIENT then return true end

	local Player = self:GetOwner()
	local Entity = Trace.Entity

	if self:GetStage() == 0 and Entity.Link then
		self.Master = Entity
		self:SetStage(1)

		return true
	elseif self:GetStage() == 1 then
		local Success, Message

		if Player:KeyDown(IN_USE) or Player:KeyDown(IN_SPEED) then
			Success, Message = self.Master:Unlink(Entity)
		else
			Success, Message = self.Master:Link(Entity)
		end

		ACF_SendNotify(Player, Success, Message)

		self:SetStage(0)
		self.Master = nil

		return true
	end

	return false
end