function pointshoot:FinishEffect()
	if SERVER then
		self:TimeScaleFadeIn(1, 0.1)
	elseif CLIENT then
		self:ClearParticle()
	end
end