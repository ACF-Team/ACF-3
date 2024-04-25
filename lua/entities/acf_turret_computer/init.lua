AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Local Vars

local ACF			= ACF
local Contraption	= ACF.Contraption
local Classes		= ACF.Classes
local Utilities		= ACF.Utilities
local Sounds		= Utilities.Sounds
local Clock			= Utilities.Clock
local HookRun		= hook.Run

do	-- Spawn and Update funcs
	local WireIO	= Utilities.WireIO
	local Entities	= Classes.Entities
	local Turrets	= Classes.Turrets

	local Inputs	= {
		"Calculate (Starts the simulation, continues calculating if capable while enabled.)",
		"Position (The position to calculate a trajectory for.) [VECTOR]",
		"Velocity (The relative velocity to include in the calculation.) [VECTOR]",
	}

	local Outputs	= {
		"Angle (Angle the gun should point in to hit the target) [ANGLE]",
		"Flight Time (The estimated time of arrival for the current round to hit the target.)",
		"Entity (The computer itself.) [ENTITY]"
	}

	local function VerifyData(Data)
		if not Data.Computer then Data.Computer = Data.Id end

		local Class = Classes.GetGroup(Turrets, Data.Computer)

		if not Class then
			Class = Turrets.Get("4-Computer")

			Data.Destiny		= "Computers"
			Data.Computer		= "DIR-BalComp"
		end

		local Computer = Turrets.GetItem(Class.ID, Data.Computer)

		if not Computer then
			Computer = Turrets.GetItem(Class.ID, "DIR-BalComp")
		end

		Data.ID		= Computer.ID
	end

	------------------

	local function UpdateComputer(Entity, Data, Class, Computer)
		Entity.Name			= Computer.Name
		Entity.ShortName	= Computer.ID
		Entity.EntType		= Class.Name
		Entity.ClassData	= Class
		Entity.Class		= Class.ID
		Entity.Computer		= Data.Computer
		Entity.Active		= true

		Entity.ComputerInfo	= Computer.ComputerInfo
		Entity.Status		= ""

		Entity:HaltSimulation()

		Entity.NextRun		= Clock.CurTime

		WireIO.SetupInputs(Entity, Inputs, Data, Class, Computer)
		WireIO.SetupOutputs(Entity, Outputs, Data, Class, Computer)

		Entity:SetNWString("WireName","ACF " .. Entity.Name)
		Entity:SetNWString("Class", Entity.Class)

		WireLib.TriggerOutput(Entity, "Entity", Entity)

		for _,v in ipairs(Entity.DataStore) do
			Entity[v] = Data[v]
		end

		ACF.Activate(Entity, true)

		Entity.DamageScale	= math.max((Entity.ACF.Health / (Entity.ACF.MaxHealth * 0.75)) - 0.25 / 0.75,0)

		local Mass = Computer.Mass
		Contraption.SetMass(Entity, Mass)
	end

	function MakeACF_BallisticComputer(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class = Classes.GetGroup(Turrets,Data.Computer)
		local Limit	= Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return end

		local Computer	= Turrets.GetItem(Class.ID, Data.Computer)

		local CanSpawn	= HookRun("ACF_PreEntitySpawn", "acf_turret_computer", Player, Data, Class, Computer)

		if CanSpawn == false then return end

		local Entity = ents.Create("acf_turret_computer")

		if not IsValid(Entity) then return end

		Player:AddCleanup(Class.Cleanup, Entity)
		Player:AddCount(Limit, Entity)

		Entity.ACF				= {}

		Contraption.SetModel(Entity, Computer.Model)

		Entity:SetPlayer(Player)
		Entity:SetAngles(Angle)
		Entity:SetPos(Pos)
		Entity:Spawn()


		Entity.Owner			= Player
		Entity.DataStore		= Entities.GetArguments("acf_turret_computer")

		UpdateComputer(Entity, Data, Class, Computer)

		Entity:UpdateOverlay(true)

		HookRun("ACF_OnEntitySpawn", "acf_turret_computer", Entity, Data, Class, Computer)

		ACF.CheckLegal(Entity)

		return Entity
	end

	Entities.Register("acf_turret_computer", MakeACF_BallisticComputer, "Computer")

	function ENT:Update(Data)
		VerifyData(Data)

		local Class = Classes.GetGroup(Turrets, Data.Computer)
		local Computer	= Turrets.GetItem(Class.ID, Data.Computer)
		local OldClass	= self.ClassData

		local CanUpdate, Reason	= HookRun("ACF_PreEntityUpdate", "acf_turret_computer", self, Data, Class, Computer)

		if CanUpdate == false then return CanUpdate, Reason end

		HookRun("ACF_OnEntityLast", "acf_turret_computer", self, OldClass)

		ACF.SaveEntity(self)

		UpdateComputer(self, Data, Class, Computer)

		ACF.RestoreEntity(self)

		HookRun("ACF_OnEntityUpdate", "acf_turret_computer", self, Data, Class, Computer)

		self:UpdateOverlay(true)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		--self:UpdateTurretMass()

		return true, "Computer updated successfully!"
	end
end

do	-- Metamethods and other important stuff
	do	-- Overlay stuff
		function ENT:UpdateOverlayText()
			local Status = ""
			if IsValid(self.Gun) then
				Status = "Linked to " .. tostring(self.Gun)
			else
				Status = "Not linked to a gun!"
			end

			if self.Status then
				Status = Status .. "\n" .. self.Status
			end

			return Status
		end
	end

	do	-- Link/unlink
		ACF.RegisterLinkSource("acf_turret_computer", "Guns")

		-- Gun links

		ACF.RegisterClassLink("acf_turret_computer", "acf_gun",function(This,Gun)
			if IsValid(This.Gun) then return false, "This computer already has a gun linked!" end

			This.Gun	= Gun

			This:UpdateOverlay(true)

			return true, "Ballistic Computer linked successfully."
		end)

		ACF.RegisterClassUnlink("acf_turret_computer", "acf_gun", function(This, Gun)
			if not IsValid(This.Gun) then return false, "This computer doesn't have a gun linked!" end
			if This.Gun ~= Gun then return false, "This computer isn't linked to this gun!" end

			This.Gun	= nil

			This:UpdateOverlay(true)

			return true, "Ballistic Computer unlinked successfully."
		end)
	end

	do	-- Wire stuff
		ACF.AddInputAction("acf_turret_computer", "Calculate", function(Entity,Value)
			if Entity.Disabled then return end

			if tobool(Value) == true then
				Entity:StartSimulation()
			end
		end)
	end

	do	-- Simulation stuff
		-- Starts fresh simulation with fresh data
		function ENT:StartSimulation()
			if Clock.CurTime < self.NextRun then return end
			if not IsValid(self.Gun) then return end

			local Gun = self.Gun

			if Gun.State ~= "Loaded" then return end

			self.Status = "Calculating..."

			local BD = Gun.BulletData

			local LocalPosition = self.Inputs["Position"].Value - Gun:LocalToWorld(Gun.Muzzle)

			local StartAngle	= Angle(0,0,0)

			local AngleToTarget = LocalPosition:GetNormalized():Angle()
			AngleToTarget:Normalize()

			if self.ComputerInfo.HighArc then
				StartAngle = Angle(math.Clamp(Lerp(0.25,-90,AngleToTarget.p),-89,-45),AngleToTarget.y,0)
			else
				StartAngle	= Angle(AngleToTarget.p,AngleToTarget.y,0)
			end

			StartAngle:Normalize()

			debugoverlay.Line(Gun:LocalToWorld(Gun.Muzzle),Gun:LocalToWorld(Gun.Muzzle) + StartAngle:Forward() * 32,3,Color(255,0,0),true)

			self.SimData	= {
				MuzzleVel		= BD.MuzzleVel,
				DragCoef		= BD.DragCoef,
				DragDiv			= ACF.DragDiv,
				Accel			= ACF.Gravity,

				StartAngle		= StartAngle,
				Flight			= StartAngle:Forward() * BD.MuzzleVel * 39.37,
				Pos				= Vector(),
				NextPos			= Vector(),
				Error			= Vector(),
				Spread			= Gun.Spread,

				StartPos		= Gun:LocalToWorld(Gun.Muzzle),
				TargetPos		= self.Inputs["Position"].Value,
				AdjustedTargetPos	= self.Inputs["Position"].Value,
				RelativeVel		= self.Inputs["Velocity"].Value,

				FlightDistance	= 0,
				FlightTime		= 0,
				TotalTime		= 0,

				DeltaTime		= self.ComputerInfo.DeltaTime,
				EndTime			= Clock.CurTime + self.ComputerInfo.MaxThinkTime,
				LastMaxTime		= self.ComputerInfo.MaxThinkTime,
				StartTime		= Clock.CurTime
			}

			self.Thinking	= true

			self:UpdateOverlay()
		end

		-- Adjusts simulation trajectory using data from the last iteration, then restarts
		function ENT:AdjustSimulation()
			local Sim = self.SimData

			self.Thinking = false
			self.Status = "Processing..."

			self:UpdateOverlay()

			local ElapsedTime		= Clock.CurTime - Sim.StartTime

			if not self.ComputerInfo.HighArc then
				if Sim.Pos:DistToSqr(Sim.AdjustedTargetPos - Sim.StartPos) < ((((Sim.FlightDistance + (Sim.RelativeVel * ElapsedTime):Length()) / 100) * self.ComputerInfo.CalcError) ^ 2) then

					WireLib.TriggerOutput(self, "Angle", Sim.StartAngle)
					WireLib.TriggerOutput(self, "Flight Time", Sim.FlightTime)

					if self.ComputerInfo.Constant and tobool(self.Inputs["Calculate"].Value) and IsValid(self.Gun) then
						local Gun = self.Gun

						Sim.AdjustedTargetPos = Sim.TargetPos + (Sim.RelativeVel * (ElapsedTime + Sim.FlightTime))

						Sim.StartPos				= Gun:LocalToWorld(Gun.Muzzle)

						Sim.Error = Sim.Error + (Sim.AdjustedTargetPos - (Sim.StartPos + Sim.Pos))

						local LocalPosition = (Sim.TargetPos - Sim.StartPos) + Sim.Error

						local AngleToTarget = LocalPosition:GetNormalized():Angle()
						AngleToTarget:Normalize()

						local StartAngle			= Angle(AngleToTarget.p,AngleToTarget.y,0)

						self.SimData.StartAngle		= StartAngle
						self.SimData.Flight			= StartAngle:Forward() * Sim.MuzzleVel * 39.37

						self.SimData.TargetPosition	= LocalPosition
						self.SimData.StraightDistance = LocalPosition:Length()

						self.SimData.Pos			= Vector()

						self.SimData.FlightDistance	= 0
						self.SimData.FlightTime		= 0

						self.SimData.LastMaxTime	= self.ComputerInfo.MaxThinkTime
						self.SimData.EndTime		= Clock.CurTime + self.ComputerInfo.MaxThinkTime

						self.Status = "Tracking"
						self:UpdateOverlay()

						self.Thinking = true

						return true
					else
						self:HaltSimulation("Firing solution found!")

						return false
					end
				else
					Sim.AdjustedTargetPos = Sim.TargetPos + (Sim.RelativeVel * (ElapsedTime + Sim.FlightTime))

					Sim.Error = Sim.Error + (Sim.AdjustedTargetPos - (Sim.StartPos + Sim.Pos))

					local LocalPosition = (Sim.TargetPos - Sim.StartPos) + Sim.Error

					local AngleToTarget = LocalPosition:GetNormalized():Angle()
					AngleToTarget:Normalize()

					local StartAngle			= Angle(AngleToTarget.p,AngleToTarget.y,0)

					self.SimData.StartAngle		= StartAngle
					self.SimData.Flight			= StartAngle:Forward() * Sim.MuzzleVel * 39.37

					debugoverlay.Cross(Sim.StartPos + LocalPosition,3,5,Color(0,0,255),true)

					self.SimData.Pos			= Vector()

					self.SimData.FlightDistance	= 0
					self.SimData.FlightTime		= 0

					self.SimData.LastMaxTime	= self.SimData.LastMaxTime * 0.9
					self.SimData.EndTime		= math.max(self.SimData.EndTime,Clock.CurTime + self.SimData.LastMaxTime)

					self.Thinking = true

					self.Status = "Adjusting..."
					self:UpdateOverlay()

					return true
				end
			else
				if Sim.Pos:DistToSqr(Sim.AdjustedTargetPos - Sim.StartPos) < ((((Sim.FlightDistance + (Sim.RelativeVel * ElapsedTime):Length()) / 100) * self.ComputerInfo.CalcError) ^ 2) then

					WireLib.TriggerOutput(self, "Angle", Sim.StartAngle)
					WireLib.TriggerOutput(self, "Flight Time", Sim.FlightTime)

					self:HaltSimulation("Firing solution found!")

					return false
				else
					Sim.AdjustedTargetPos = Sim.TargetPos + (Sim.RelativeVel * (ElapsedTime + Sim.FlightTime))

					local CorrectLateralDistance	= Sim.StartPos:Distance2D(Sim.AdjustedTargetPos)

					local LateralDistance	= Sim.StartPos:Distance2D(Sim.StartPos + Sim.Pos)

					local ErrorDir2D	= ((Sim.TargetPos - (Sim.StartPos + Sim.Pos)) * Vector(1,1,0)):GetNormalized()
					local ErrorDist		= (Sim.StartPos + Sim.Pos):Distance2D(Sim.TargetPos)

					debugoverlay.Line(Sim.StartPos + Sim.Pos,(Sim.StartPos + Sim.Pos) + ErrorDir2D * ErrorDist, 3, Color(255,0,0), true)

					local LocalPosition = (Sim.AdjustedTargetPos - Sim.StartPos)

					local AngleToTarget = LocalPosition:GetNormalized():Angle()
					AngleToTarget:Normalize()
					local NextAngle			= -90 + (Sim.StartAngle.p - -90) * (CorrectLateralDistance / math.max(1,LateralDistance))
					if NextAngle > -25 then self:HaltSimulation("Target unable to be reached!") return false end
					AngleToTarget.p			= math.Clamp(NextAngle,-90,-25)

					local StartAngle	= Angle(AngleToTarget.p,AngleToTarget.y,0)

					self.SimData.StartAngle		= StartAngle
					self.SimData.Flight			= StartAngle:Forward() * Sim.MuzzleVel * 39.37

					debugoverlay.Cross(Sim.StartPos + LocalPosition,3,5,Color(0,0,255),true)

					self.SimData.Pos			= Vector()

					self.SimData.FlightDistance	= 0
					self.SimData.FlightTime		= 0

					self.SimData.LastMaxTime	= self.SimData.LastMaxTime * 0.9
					self.SimData.EndTime		= math.max(self.SimData.EndTime,Clock.CurTime + self.SimData.LastMaxTime)

					self.Thinking = true

					self.Status = "Adjusting..."
					self:UpdateOverlay()

					return true
				end

			end
		end

		-- Stops the simulation in its tracks and begins cooldown
		function ENT:HaltSimulation(Reason)
			self.Thinking	= false
			self.SimData	= nil

			if Reason then
				self.Status = Reason
			else
				self.Status = ""
			end

			self.NextRun = Clock.CurTime + self.ComputerInfo.Delay

			self:UpdateOverlay()
		end

		-- Actually runs the simulation, can call AdjustSimulation if it thinks the target has been reached
		function ENT:RunSimulation()
			local Sim			= self.SimData

			local DeltaTime		= Sim.DeltaTime
			local Drag			= Sim.Flight:GetNormalized() * (Sim.DragCoef * Sim.Flight:LengthSqr()) / Sim.DragDiv
			local Correction	= 0.5 * (Sim.Accel - Drag) * DeltaTime

			Sim.NextPos			= Sim.Pos + ACF.Scale * DeltaTime * (Sim.Flight + Correction)
			Sim.Flight			= Sim.Flight + (Sim.Accel - Drag) * DeltaTime

			local FlightDistance	= Sim.Pos:Distance(Sim.NextPos)

			Sim.FlightTime		= Sim.FlightTime + DeltaTime
			Sim.TotalTime		= Sim.TotalTime + DeltaTime

			debugoverlay.Line(Sim.StartPos + Sim.Pos,Sim.StartPos + Sim.NextPos,5,Color(255,0,0),true)

			local Dir = (Sim.NextPos - Sim.Pos):GetNormalized()

			if not self.ComputerInfo.HighArc then
				-- Gets the closest point in a line segment (current step of the trajectory)
				local Point = Sim.Pos + (((Sim.AdjustedTargetPos - Sim.StartPos) - Sim.Pos):Dot(Dir)) / (Dir:Dot(Dir)) * Dir

				if (Dir:Dot(Point - Sim.Pos) >= 0) and (Dir:Dot(Point - Sim.NextPos) <= 0) then

					local Ratio = (Sim.Pos:Distance(Point)) / FlightDistance

					debugoverlay.Line(Sim.StartPos + Sim.Pos,Sim.StartPos + Sim.NextPos,8,Color(0,255,0),true)
					debugoverlay.Cross(Sim.StartPos + Sim.Pos,15,8,Color(255,0,0),true)

					Sim.Pos		= Point

					Sim.FlightDistance = Sim.FlightDistance + (FlightDistance * Ratio)

					debugoverlay.Cross(Sim.StartPos + Point,15,8,Color(255,255,255),true)
					debugoverlay.Cross(Sim.StartPos + Sim.NextPos,15,8,Color(0,255,0),true)

					return self:AdjustSimulation()
				else
					Sim.FlightDistance = Sim.FlightDistance + FlightDistance
				end
			else
				local HighZ = (Sim.StartPos + Sim.Pos).z
				local LowZ	= (Sim.StartPos + Sim.NextPos).z
				local TargetZ	= Sim.AdjustedTargetPos.z

				if (HighZ >= TargetZ) and (LowZ <= TargetZ) and (Dir:Dot(Vector(0,0,-1)) >= 0) then -- Falling down and near the Z target
					local Ratio = 1 - ((TargetZ - LowZ) / (HighZ - LowZ))

					Sim.Pos		= Sim.Pos + ((Sim.NextPos - Sim.Pos) * Ratio)

					Sim.FlightDistance = Sim.FlightDistance + (FlightDistance * Ratio)

					return self:AdjustSimulation()
				else
					Sim.FlightDistance = Sim.FlightDistance + FlightDistance
				end
			end

			Sim.Pos				= Sim.NextPos
			return true
		end

		local MaxDistance = ACF.LinkDistance ^ 2
		local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"

		function ENT:Think()
			if IsValid(self.Gun) then
				if self:GetPos():DistToSqr(self.Gun:GetPos()) > MaxDistance then
					local USound = UnlinkSound:format(math.random(1, 3))

					Sounds.SendSound(self, USound, 70, 100, 1)
					Sounds.SendSound(self.Gun, USound, 70, 100, 1)
					self:Unlink(self.Gun)

					self:HaltSimulation("Gun unlinked!")

					self:NextThink(Clock.CurTime + 0.1)
					return true
				end
			else
				self:NextThink(Clock.CurTime + 0.1)
				return true
			end

			if self.Thinking == false then
				self:NextThink(Clock.CurTime + 0.1)
				return true
			else
				if Clock.CurTime > self.SimData.EndTime then
					self:HaltSimulation("Took too long!")

					self:NextThink(Clock.CurTime + 0.1)
					return true
				end
			end

			-- Run simulation

			for _ = 1,self.ComputerInfo.Bulk do
				if not self.Thinking then break end
				if not self:RunSimulation() then break end
			end

			self:NextThink(Clock.CurTime + self.ComputerInfo.ThinkTime)
			return true
		end
	end

	do	-- Dupe support
		function ENT:PreEntityCopy()
			if self.Gun then
				duplicator.StoreEntityModifier(self, "ACFGun", {self.Gun:EntIndex()})
			end

			-- Wire dupe info
			self.BaseClass.PreEntityCopy(self)
		end

		function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
			local EntMods = Ent.EntityMods

			if EntMods.ACFGun then
				self:Link(CreatedEntities[EntMods.ACFGun[1]])

				EntMods.ACFGun = nil
			end

			self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
		end
	end

	do	-- ACF Funcs
		function ENT:Enable()
			self.Active	= true
			self:HaltSimulation()
			self:UpdateOverlay()
		end

		function ENT:Disable()
			self.Active	= true
			self:HaltSimulation("Disabled")
			self:UpdateOverlay()
		end

		function ENT:ACF_PostDamage()
			self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75,0)
		end

		function ENT:ACF_OnRepaired() -- Normally has OldArmor, OldHealth, Armor, and Health passed
			self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75,0)
		end

		function ENT:SetActive(Active,Reason)
			local Trigger = (self.Active ~= Active) or (self.InactiveReason ~= Reason)
			if not Active then
				self.InactiveReason = Reason
				self.Active = false
			else
				self.InactiveReason = ""
				self.Active = true
			end

			if Trigger then self:UpdateOverlay(true) end
		end
	end
end