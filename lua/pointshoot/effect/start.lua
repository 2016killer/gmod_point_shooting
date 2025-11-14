function pointshoot:StartEffect(ply)
	if SERVER then
		self:TimeScaleFadeIn(0, 0.07)
	elseif CLIENT then
		surface.PlaySound('hitman/start.mp3')
		self:ParticleEffect(ply)
		self:ScreenFlash(150, 0, 0.2)

		sixthsense:Start(LocalPlayer(), 500, 0.1, 0.5, 30, nil)
		sixthsense.enable = false
		
		for i = #sixthsense.entqueue, 1, -1 do
			local ent = sixthsense.entqueue[i]
			if not ent:IsNPC() then
				table.remove(sixthsense.entqueue, i)
				continue
			end
			if ent:LookupBone('ValveBiped.Bip01_Head1') then
				local skeleton = ClientsideModel('models/player/skeleton.mdl', RENDERGROUP_OTHER)
				skeleton:SetParent(ent)
				skeleton:AddEffects(EF_BONEMERGE)
				skeleton:SetNoDraw(true)
				skeleton.remove = true
				sixthsense.entqueue[i] = skeleton
			end
		end
		local skeletonList = sixthsense.entqueue
		timer.Simple(2, function()
			for i, skeleton in pairs(skeletonList) do
				if not IsValid(skeleton) or not skeleton.remove then
					continue
				end
				skeleton:Remove()
			end
		end)
		sixthsense.enable = true
		surface.PlaySound('dishonored/darkvision_scan.wav')
	end
end