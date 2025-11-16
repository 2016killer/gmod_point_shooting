if SERVER then return end
pointshoot = pointshoot or {}
pointshoot.DrawPower = function()
	

end


hook.Add('PlayerPostThink', 'pointshoot.power', function()
	if not LocalPlayer():Alive() or LocalPlayer():InVehicle() then
		return
	end
end)