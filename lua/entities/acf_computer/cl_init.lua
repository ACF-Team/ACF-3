DEFINE_BASECLASS("acf_base_simple") -- Required to get the local BaseClass

include("shared.lua")

language.Add("Cleanup_acf_computer", "ACF Computers")
language.Add("Cleaned_acf_computer", "Cleaned up all ACF Computers")
language.Add("SBoxLimit__acf_computer", "You've reached the ACF Computer limit!")

local ACF        = ACF
local Classes    = ACF.Classes
local Clock      = ACF.Utilities.Clock
local Components = Classes.Components

function ENT:Initialize(...)
	BaseClass.Initialize(self, ...)

	self:Update()
end

function ENT:Update()
	local Id = self:GetNW2String("ID")
	local Class = Classes.GetGroup(Components, Id)
	local Data = Class.Lookup[Id]

	if self.OnLast then
		self:OnLast()
	end

	self.OnUpdate = Data.OnUpdateCL or Class.OnUpdateCL
	self.OnLast = Data.OnLastCL or Class.OnLastCL
	self.OnThink = Data.OnThinkCL or Class.OnThinkCL
	self.OnDraw = Data.OnDrawCL or Class.OnDrawCL

	if self.OnUpdate then
		self:OnUpdate(Class, Data)
	end
end

function ENT:Draw(...)
	BaseClass.Draw(self, ...)

	if self.OnDraw then
		self:OnDraw()
	end
end

function ENT:Think(...)
	self:NextThink(Clock.CurTime)

	if self.OnThink then
		self:OnThink()
	end

	BaseClass.Think(self, ...)

	return true
end
