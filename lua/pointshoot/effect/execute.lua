function pointshoot:ExecuteEffect(ply)
	if SERVER then
		self:TimeScaleFadeIn(0.3, 0)
	elseif CLIENT then
		surface.PlaySound('hitman/execute.mp3')
	end
end