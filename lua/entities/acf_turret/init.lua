AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

--------

local ACF   = ACF

ACF.AddParentDetour("acf_turret", "rotator")

function ENT:Enable() end -- TODO: make it stop working when it shouldn't work, and work when it should
function ENT:Disable() end

do -- Spawning and updating
	local Turrets = ACF.Classes.TurretTypes
	local ModelData  = ACF.ModelData

	local function CreateInputs(Entity, Data, Class)
		local List = { "Active (Toggle the drive on or off)", "Angle (Desired angle to aim towards) [ANGLE]"}

		if Class.SetupInputs then
			Class:SetupInputs(List, Entity, Data, Class)
		end

		hook.Run("ACF_OnSetupInputs", "acf_turret", List, Entity, Data, Class)

		if Entity.Inputs then
			Entity.Inputs = WireLib.AdjustInputs(Entity, List)
		else
			Entity.Inputs = WireLib.CreateInputs(Entity, List)
		end
	end

	local function CreateOutputs(Entity, Data, Class, Weapon)
		local List = { }

		if Class.SetupOutputs then
			Class.SetupOutputs(List, Entity, Data, Class, Weapon)
		end

		hook.Run("ACF_OnSetupOutputs", "acf_turret", List, Entity, Data, Class, Weapon)

		if Entity.Outputs then
			Entity.Outputs = WireLib.AdjustOutputs(Entity, List)
		else
			Entity.Outputs = WireLib.CreateOutputs(Entity, List)
		end
	end

	local function GetMass(Class,PhysObj,Model)
		--local sizePerc = ((Diameter - Class.minSize) / (Class.maxSize - Class.minSize))
		local Volume = PhysObj:GetVolume()
		local Factor = Volume / ModelData.GetModelVolume(Model)
		--print(Volume,Factor)
		return math.Round(Class.Mass * Factor)
	end

	local function VerifyData(Data)
		Data.PlateSizeX = ACF.CheckNumber(Data.PlateSizeX, 24)
	end

	local function UpdateTurret(Entity, Data, Class)
		local Diameter = Data.PlateSizeX
		local ratio    = Diameter / Entity:GetOriginalSize().x
		local Model    = Class.Model

		local RingHeight = ratio * Class.RatioScale
		if Data.TurretClass == "Horizontal" then
			Model = Diameter <= 12 and Class.ModelSmall or Class.Model
			if Entity:GetModel() ~= Model then Entity:SetModel(Model) end
			ratio = Diameter / Entity:GetOriginalSize().x

			RingHeight = Diameter <= 12 and (12 / Entity:GetOriginalSize().z) or ratio * Class.RatioScale
		elseif Data.TurretClass == "Vertical" then
			RingHeight = math.max(ratio * Class.RatioScale,0.5)
		end

		Entity.ACF.Model = Model
		if Entity:GetModel() ~= Model then Entity:SetModel(Model) end

		Entity:SetScale(Vector(ratio, ratio, RingHeight))

		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name      = Diameter .. "\" " .. Class.Name
		Entity.ShortName = Diameter .. "\" TD"
		Entity.EntType   = Class.Name
		Entity.PlateSizeX  = Diameter

		Entity.desiredAngle = Entity.desiredAngle or Angle(0, 0, 0)
		Entity.currentAngle = Entity.currentAngle or Angle(0, 0, 0)
		Entity.Manual	 = true -- This is set to false when using the Angle input, is for global angles
		-- Otherwise when using Elevation/Bearing input its true for local angles
		Entity.desiredDeg = 0 -- Sets the desired starting angle to 0, combined with above being true the turret won't turn without another angle input right away

		Entity.scaledMaxSlew = (Class.BaseScaleDiameter / Entity.PlateSizeX) * Class.BaseSpeed
		Entity.scaledSlewAccel = ((Class.BaseScaleDiameter / Entity.PlateSizeX) * Class.BaseAccel) ^ 1.5
		local sizePerc = ((Entity.PlateSizeX - Class.minSize) / (Class.maxSize - Class.minSize))
		Entity.maxWeight = (Class.minMass * (1 - sizePerc)) + (Class.maxMass * sizePerc)

		--print(Entity.scaledMaxSlew .. " deg/s",Entity.scaledSlewAccel .. " deg/s^2",Entity.maxWeight .. "kg max")

		CreateInputs(Entity, Data, Class)
		CreateOutputs(Entity, Data, Class)

		Entity:SetNWString("WireName", "ACF " .. Entity.Name)
		Entity:SetNWString("Class", Entity.Class)

		ACF.Activate(Entity, true)

		local PhysObj = Entity.ACF.PhysObj

		if IsValid(PhysObj) then
			local Mass = GetMass(Class,PhysObj,Model)

			Entity.ACF.LegalMass = Mass

			PhysObj:SetMass(Mass)
		end

		Entity:UpdateOverlay()
	end

	function MakeACF_Turret(Player, Pos, Ang, Data)
		VerifyData(Data)

		if not Player:CheckLimit("_acf_turret") then return false end

		local Entity  = ents.Create("acf_turret")
		if not IsValid(Entity) then return end

		local rotator = ents.Create("acf_turret_rotator")

		if not IsValid(rotator) then
			Entity:Remove()
			return
		end

		local Class = Turrets[Data.TurretClass]

		Player:AddCount("_acf_turret", Entity)
		Player:AddCleanup("_acf_turret", Entity)

		Entity:SetModel(Class.Model)
		Entity:SetPlayer(Player)
		Entity:SetAngles(Ang)
		--if Data.TurretClass == "Vertical" and not Data.BuildDupeInfo then Entity:SetAngles(Ang + Angle(0,0,-90)) else Entity:SetAngles(Ang) end -- Aligns the vertical drive so its easy to pick up and move without figuring which is "up"
		Entity:SetPos(Pos)
		Entity:Spawn()

		rotator:SetPos(Entity:GetPos())
		rotator:SetAngles(Entity:GetAngles())
		rotator:SetParent(Entity)
		rotator:SetModel("models/sprops/misc/origin.mdl")
		rotator:Spawn()

		Entity.Owner     = Player -- MUST be stored on ent for PP
		Entity.DataStore = ACF.GetEntityArguments("acf_turret")
		Entity.ACF       = {}
		Entity.Class     = Data.Class
		Entity.TurretClass = Data.TurretClass
		Entity.DamageScale = 1

		-- For now this is just other turret entities on this one
		Entity.WatchedChildren = {}
		Entity.LocalCoM = Vector()
		Entity.HeldMass = 0
		Entity.TotalCoM = Vector()
		Entity.TotalMass = 0
		Entity.NextCoMThink = CurTime()
		Entity.WeightScale = 1
		Entity.BalanceScale = 1

		Entity.rotator   = rotator
		Entity:SetNWEntity("rotator",rotator)

		Entity:SetNWVector("centerofmass",Entity.TotalCoM)

		Entity.slewRate  = 0 -- Internal value for motor speeds
		Entity.Active	 = false -- If true, the motor is active and the turret is attempting to point to the required angle
		-- If false, the motor slows to a stop and no aiming happens

		--Entity.lastAng = Entity:GetAngles()

		UpdateTurret(Entity, Data, Class)

		if Class.OnSpawn then
			Class:OnSpawn(Entity, Data)
		end

		hook.Run("ACF_OnEntitySpawn", "acf_turret", Entity, Data, Class)

		do -- Mass entity mod removal
			local EntMods = Data.EntityMods

			if EntMods and EntMods.mass then
				EntMods.mass = nil
			end
		end

		return Entity
	end

	ACF.RegisterEntityClass("acf_turret", MakeACF_Turret, "TurretClass", "PlateSizeX")

	function ENT:Update(Data)
		VerifyData(Data)

		local Turret    = Turrets[Data.TurretClass]
		local OldTurret = self

		if OldTurret.TurretClass ~= Data.TurretClass then return false, "Mismatched turret types! " .. OldTurret.TurretClass .. " > " .. Data.TurretClass end

		if OldTurret.OnLast then
			OldTurret:OnLast(self)
		end

		hook.Run("ACF_OnEntityLast", "acf_turret", self, OldClass)

		ACF.SaveEntity(self)

		UpdateTurret(self, Data, Turret)

		ACF.RestoreEntity(self)

		if Turret.OnUpdate then
			Turret:OnUpdate(Plate, Data)
		end

		hook.Run("ACF_OnEntityUpdate", "acf_turret", self, Data, Turret)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		return true, "Turret drive updated successfully!"
	end

	function ENT:OnRemove()
		if IsValid(self.rotator) then
			self.rotator:Remove()
		end
	end

	function ENT:GetChildren()
		if not IsValid(self.rotator) then return {} end
		local List = self.rotator:GetChildren()
		for k,_ in pairs(List) do
			if k == NULL or (k:GetMoveParent() ~= self.rotator) or (k:GetMoveParent() == NULL) then List[k] = nil end
		end
		return List
	end

	local function GetTotalMassCenter(Turret) -- Gets the TOTAL center of mass of everything on the turret and below in hierarchy
		if not IsValid(Turret) then return end

		Turret.TotalCoM = Turret.LocalCoM
		Turret.TotalMass = Turret.HeldMass

		for _,v in pairs(Turret.WatchedChildren) do
			GetTotalMassCenter(v)
			Turret.TotalMass = Turret.TotalMass + v.TotalMass
		end

		local Shift = Vector()
		for _,v in pairs(Turret.WatchedChildren) do
			Shift = Turret.rotator:WorldToLocal(v:LocalToWorld(v.TotalCoM)) * (v.TotalMass / Turret.TotalMass)
			Turret.TotalCoM = Turret.TotalCoM + Shift
		end

		Turret:SetNWFloat("totalmass",math.Round(Turret.TotalMass,1))
		Turret:SetNWVector("centerofmass",Turret.TotalCoM)

		--print(Turret.ACF.LegalMass)
		Turret.WeightScale = 1 - math.Clamp((math.max(Turret.TotalMass - Turret.ACF.LegalMass,0) / Turret.maxWeight) - 1,0,1)
		local Dist = math.sqrt( (Turret.TotalCoM.x ^ 2) + (Turret.TotalCoM.y ^ 2) )

		local MinDistMult = 1.5
		if Turret.PlateSizeX > 12 and Turret.TurretClass == "Horizontal" then MinDistMult = 0.5 end
		local Radius = Turret.PlateSizeX / 2
		Turret.BalanceScale = 1 - ((math.Clamp((math.max(Dist - (Radius * MinDistMult),0) / Radius) * 3,0,1)) * 0.95)

		Turret:UpdateOverlay()
	end

	local function GetFilteredChildren(Entity, Pass, FilterClass) -- Specialized for this use case
		local List = Pass or {}
		-- I need it to stop when it finds a turret and add it, but do not go past it (don't worry, its done)

		for _, V in pairs(Entity:GetChildren()) do
			if not IsValid(V) or List[V] then continue end

			List[V] = V
			if V:GetClass() ~= FilterClass then GetFilteredChildren(V, List) end
		end

		return List
	end

	function ENT:GetMassCenter()
		if not IsValid(self) then return end
		if not IsValid(self:GetPhysicsObject()) then return end

		--PrintTable(ChildList)
		self.WatchedChildren = {}
		self.HeldMass = self:GetPhysicsObject():GetMass()
		self.LocalCoM = self:OBBCenter() -- Not teeeechnically correct but it will loop back endlessly, and its close enough as is

		local Add = {}
		local ChildList = {}

		GetFilteredChildren(self,ChildList,"acf_turret")

		for k,v in pairs(ChildList) do
			if k:GetClass() == "acf_turret" then
				self.WatchedChildren[k] = v -- These will have their own LocalCoM to read from, so we'll do magic with that later
			else
				if IsValid(k:GetPhysicsObject()) then
					local PO = k:GetPhysicsObject()
					self.HeldMass = self.HeldMass + PO:GetMass()
					Add[k] = PO
				end
			end
		end

		local Shift = Vector()
		for k,v in pairs(Add) do
			Shift = self.rotator:WorldToLocal(k:LocalToWorld(v:GetMassCenter())) * (v:GetMass() / self.HeldMass)
			self.LocalCoM = self.LocalCoM + Shift
		end

		--debugoverlay.Cross(self:LocalToWorld(self.LocalCoM),6,15,_,true)
		--debugoverlay.Text(self:LocalToWorld(self.LocalCoM),self.HeldMass .. "kg",15)

		self.TotalCoM = self.LocalCoM
		GetTotalMassCenter(self)

		self.NextCoMThink = CurTime() + math.Rand(3,7)

		return self.LocalCoM
	end
end

do -- Wire io
	ACF.AddInputAction("acf_turret", "Active", function(Ent, Value)
		if not IsValid(Ent) then return end
		Ent.Active = Value ~= 0 and true or false
	end)

	ACF.AddInputAction("acf_turret", "Angle", function(Ent, Value)
		if not IsValid(Ent) then return end

		local p, y, r = Value[1], Value[2], Value[3]
		Ent.Manual = false

		Ent.desiredAngle = Angle(p, y, r)
	end)

	ACF.AddInputAction("acf_turret", "Elevation", function(Ent, Value) -- Only on vertical drive
		if not IsValid(Ent) then return end
		Ent.Manual = true
		Ent.desiredDeg = Value
	end)

	ACF.AddInputAction("acf_turret", "Bearing", function(Ent, Value) -- Only on horizontal drive
		if not IsValid(Ent) then return end
		Ent.Manual = true
		Ent.desiredDeg = Value
	end)
end

do -- Movement
	--[[
	local function clampAngle(a, mins, maxs) -- Just commented out so the builder doesn't freak out :(

	end]]

	local red = Color(255,0,0)
	local green = Color(0,255,0)

	function ENT:Think()
		local tick = engine.TickInterval()
		local bearing = self.Manual and self.rotator:WorldToLocalAngles(self:LocalToWorldAngles(Angle(0,-self.desiredDeg,0))).yaw or self.rotator:WorldToLocalAngles(self.desiredAngle).yaw -- Get the bearing (relative yaw) of the desired angle from the current angle
		local slewMax = self.scaledMaxSlew * self.DamageScale * self.BalanceScale * tick -- maximum speed
		local slewAccel = self.scaledSlewAccel * self.DamageScale * self.WeightScale * tick -- rate of approaching maximum speed, to be further modified by weight/weight limit of turret
		local maxImpulse = math.min(slewMax,slewAccel)

		local sign            = bearing < 0 and -1 or 1
		local distance        = math.abs(bearing)
		local finalAccel	  = math.Clamp(bearing,-maxImpulse,maxImpulse)
		local brakingDistance = self.slewRate^2 / math.abs(finalAccel) / 2

		--self.slewRate = math.Clamp(bearing, -slewMax, slewMax) -- old calculation, kept for reference or whatever
		if self.Active then
			self.slewRate = math.Clamp(self.slewRate + (math.abs(finalAccel) * ((distance + (self.slewRate * 2 * -sign)) >= brakingDistance and sign or -sign)), -slewMax, slewMax)

			-- This stops the "vibrating" that occurs when the aim is settling
			-- Issue arises because of the cross-tick calculation we're trying to do
			-- This stops that by seeing if the next "impulse" could stop the aim directly on the aim point, and does so
			if self.slewRate ~= 0 and (distance <= math.abs(finalAccel)) and (self.slewRate <= finalAccel) then
				self.slewRate = 0
				self.currentAngle = self.currentAngle + Angle(0, bearing / 2, 0)
			end
		elseif not self.Active and self.slewRate ~= 0 then
			self.slewRate = self.slewRate - (math.min(slewAccel,math.abs(self.slewRate)) * (self.slewRate >= 0 and 1 or -1))
		end

		if self.Active then
			debugoverlay.EntityTextAtPosition(self:GetPos(),0,"Bearing: " .. bearing,0.03)
			debugoverlay.EntityTextAtPosition(self:GetPos(),1,"Slew: " .. self.slewRate,0.03)
			debugoverlay.EntityTextAtPosition(self:GetPos(),2,"Accel: " .. finalAccel,0.03)
		end

		debugoverlay.Cross(self.rotator:LocalToWorld(self.LocalCoM),6,0.03,red,true)
		debugoverlay.Text(self.rotator:LocalToWorld(self.LocalCoM),self.HeldMass .. "kg",0.03)
		debugoverlay.Line(self.rotator:LocalToWorld(self:OBBCenter()),self.rotator:LocalToWorld(self.LocalCoM),0.03,red,true)

		debugoverlay.Cross(self.rotator:LocalToWorld(self.TotalCoM),6,0.03,green,true)
		debugoverlay.Text(self.rotator:LocalToWorld(self.TotalCoM),self.TotalMass .. "kg",0.03)
		debugoverlay.Line(self.rotator:LocalToWorld(self:OBBCenter()),self.rotator:LocalToWorld(self.TotalCoM),0.03,green,true)

		if self:GetNWFloat("turret_slew") ~= self.slewRate then self:SetNWFloat("turret_slew",self.slewRate) end

		self.currentAngle = self.currentAngle + Angle(0, self.slewRate, 0)

		self.rotator:SetAngles(self:LocalToWorldAngles(self.currentAngle))

		self:NextThink(CurTime())
		if CurTime() > self.NextCoMThink then self.NextCoMThink = CurTime() + 5 self:GetMassCenter() end
		--self.lastAng = self:GetAngles() -- Will be used for stabilization later
		return true
	end
end

do -- Overlay
	local Text = "Max: %s deg/s\nAccel: %s deg/s^2\nCurrent/Max Weight: %Gkg / %Gkg"
	function ENT:UpdateOverlayText()
		local SlewMax = math.Round(self.scaledMaxSlew * self.DamageScale * self.BalanceScale,1)
		local SlewAccel = math.Round(self.scaledSlewAccel * self.DamageScale * self.WeightScale,2)
		local MaxWeight = math.Round(self.maxWeight,1)
		local TotalWeight = math.Round(math.max(self.TotalMass - self.ACF.LegalMass,0),1)
		return Text:format(SlewMax,SlewAccel,TotalWeight,MaxWeight)
	end
end

do -- Special ACF funcs
	function ENT:ACF_OnDamage(Bullet, Trace, Volume)
		local Res = ACF.PropDamage(Bullet, Trace, Volume)

		--adjusting performance based on damage
		self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75,0.05)

		self:UpdateOverlay()

		return Res -- always must be returned
	end

	function ENT:ACF_OnRepaired() -- OldArmor, OldHealth, Armor, Health are the normal variables passed from this func
		self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75,0.05)
		self:UpdateOverlay()
	end

	--[[
		Entity				- Entity that was parented/deparented
		ConnectionStatus	- true/false if the entity is connected

	]]
	function ENT:ACF_OnParent()
		if not IsValid(self.rotator) then return end
		if CurTime() > self.NextCoMThink then self:GetMassCenter() else self.NextCoMThink = CurTime() + math.Rand(-1,2) end
	end
end
