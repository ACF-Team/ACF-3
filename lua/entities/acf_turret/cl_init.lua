DEFINE_BASECLASS("acf_base_scalable") -- Required to get the local BaseClass

include("shared.lua")

language.Add("Cleanup__acf_turret","ACF Turrets")
language.Add("Cleanup__acf_turret","Cleaned up all ACF turrets!")
language.Add("SBoxLimit__acf_turret", "You've reached the ACF turrets limit!")

function ENT:Initialize(...)
	BaseClass.Initialize(self, ...)

	-- acf_extra/turret/cannon_turn_loop_1.wav
	self:SetNWVarProxy("turret_slew",function(_,_,_,slewRate)
		if not IsValid(self) then return end
		local truerate = math.abs(slewRate)
		local tick = engine.TickInterval()
		local pitch = (truerate / tick) + 20
		local vol = math.min(truerate * 0.75,1)
		local snd = self.Sound
		--print(truerate / tick)
		if snd ~= nil then
			if truerate == 0 and snd:IsPlaying() then
				snd:Stop()
			elseif truerate ~= 0 and not snd:IsPlaying() then
				snd:PlayEx(vol,pitch)
			end
			snd:ChangePitch(pitch,0.1)
			snd:ChangeVolume(vol,0.1)
		else
			local newsnd = CreateSound(self,"acf_extra/turret/cannon_turn_loop_1.wav")
			newsnd:PlayEx(vol,pitch)
			newsnd:SetSoundLevel(66)
			self.Sound = newsnd
		end
	end)
end

-- yes I know this can get falsely called, but the above catches it since the sound isn't valid and restarts it
-- Had to be done this way because having the delay checking if its truely gone makes CSoundPatch wet itself and disable the sound, but not truly stopping it
-- Thus leading to sounds playing until stopsounds was called in console
function ENT:OnRemove()
	if self.Sound then self.Sound:Stop() end
end

----

local Turrets = ACF.Classes.TurretTypes

do -- Updating
	function ENT:Update()

	end
end

do -- Turret menu item
	local function CreateMenu(Menu)
		ACF.SetToolMode("acf_menu", "Spawner", "Component")

		ACF.SetClientData("PrimaryClass", "acf_turret")
		ACF.SetClientData("SecondaryClass", "N/A")

		Menu:AddTitle("Procedural Turrets")
		Menu:AddLabel("WARNING: EXPERIMENTAL!\nProcedural Turrets are an experimental work in progress and may cause crashes, errors, or just not work properly with all of ACF.\n\nProcedural Turrets can be prevented from spawning by setting sbox_acf_max_turrets to 0")

		local ClassList = Menu:AddComboBox()
		local SizeX     = Menu:AddSlider("Ring diameter (gmu)", 5, 96 * 2, 0)

		local ClassBase = Menu:AddCollapsible("Turret Drive Information")
		local ClassName = ClassBase:AddTitle()
		local ClassDesc = ClassBase:AddLabel()

		function ClassList:OnSelect(Index, _, Data)
			if self.Selected == Data then return end

			self.ListData.Index = Index
			self.Selected       = Data

			ClassName:SetText(Data.Name)
			ClassDesc:SetText(Data.Description)
			SizeX:SetMinMax(Data.minSize,Data.maxSize)
			SizeX:SetValue(Data.defaultSize)
			--PrintTable(Data)
			ACF.SetClientData("TurretClass", Data.ID)
			print(Data.ID)
		end

		SizeX:SetClientData("PlateSizeX", "OnValueChanged")
		SizeX:DefineSetter(function(Panel, _, _, Value)
			local X = math.Round(Value, 2)

			Panel:SetValue(X)

			return X
		end)

		ACF.LoadSortedList(ClassList, Turrets, "Name")
	end

	ACF.AddMenuItem(3, "Entities", "Turrets", "cog", CreateMenu)
end

local red = Color(255,0,0)
local green = Color(0,255,0)
local orange = Color(255,127,0)
hook.Add("ACF_DrawFunc","ACF Turret Render",function(Ent,Trace)
	if Ent:GetClass() ~= "acf_turret" then return end
	local X = Ent:OBBMaxs().x
	local Pos = Ent:LocalToWorld(Ent:OBBCenter())
	local Pos2 = Ent:LocalToWorld(Ent:OBBCenter())
	render.DrawLine(Pos2,Pos2 + Ent:GetForward() * X,red,true)
	if not IsValid(Ent.rotator) then Ent.rotator = Ent:GetNWEntity("rotator") return else render.DrawLine(Pos,Pos + Ent.rotator:GetForward() * X,green,true) end
	local CoM = Ent:GetNWVector("centerofmass",Vector())

	local LocPos = Ent:WorldToLocal(Trace.HitPos)
	local LocDir = Vector(LocPos.x,LocPos.y,0):GetNormalized()

	render.DrawLine(Pos,Ent:LocalToWorld(Ent:OBBCenter() + LocDir * X * 2),orange,true)

	render.DrawLine(Ent:LocalToWorld(Ent:OBBCenter()),Ent.rotator:LocalToWorld(CoM),red,true)

	render.OverrideDepthEnable(true,true)
		render.DrawSphere(Ent.rotator:LocalToWorld(CoM),1.5,4,3,red)
	render.OverrideDepthEnable(false,false)

	local HomePos = (Pos2 + Ent:GetUp() + Ent:GetForward() * X):ToScreen()
	local CurPos = (Pos + Ent.rotator:GetForward() * X):ToScreen()
	local AimPos = (Ent:LocalToWorld(Ent:OBBCenter() + LocDir * X) - Ent:GetUp()):ToScreen()

	local COMPos = (Ent.rotator:LocalToWorld(CoM) + Vector(0,0,3)):ToScreen()
	cam.Start2D()
		draw.SimpleTextOutlined("Home",_,HomePos.x,HomePos.y,red,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
		draw.SimpleTextOutlined("Current: " .. -math.Round(Ent:WorldToLocalAngles(Ent.rotator:GetAngles()).yaw,2),_,CurPos.x,CurPos.y,green,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
		draw.SimpleTextOutlined("Aim: " .. -math.Round(Ent:WorldToLocalAngles(Ent:LocalToWorldAngles(LocDir:Angle())).yaw,2),_,AimPos.x,AimPos.y,orange,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)

		draw.SimpleTextOutlined(Ent:GetNWFloat("totalmass",0) .. "kg",_,COMPos.x,COMPos.y,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
	cam.End2D()
end)
