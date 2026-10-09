local function Init(Entity)
	Entity.Receivers          = {}  -- LWR/RWRs
	Entity.ReceiverDirections = {}  -- LWS/RWS receiver angles
	Entity.ReceiverDetecteds  = {}  -- LWS/RWS receiver detected states
end

-- Receiver related
do
	function ENT:ProcessReceivers(SelfTbl)
		for Receiver, _ in pairs(SelfTbl.Receivers) do
			if IsValid(Receiver) then
				local Detected = Receiver.Outputs.Detected.Value
				local Direction = Receiver.Outputs.Direction.Value
				if (SelfTbl.ReceiverDetecteds[Receiver] ~= Detected or SelfTbl.ReceiverDirections[Receiver] ~= Direction) then
					SelfTbl.ReceiverDirections[Receiver] = Direction
					SelfTbl.ReceiverDetecteds[Receiver] = Detected
					if Detected == 0 then return end
					net.Start("ACF_Controller_Receivers")
					net.WriteEntity(self)
					net.WriteEntity(Receiver)
					net.WriteVector(Direction)
					net.Send(self.Driver)
				end
			end
		end
	end
end

ACF.RegisterControllerLink("acf_receiver", {
	Field = "Receivers",
	Single = false,
})

return Init
