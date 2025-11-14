function SWEP:StartEffect(ply)
	if SERVER then
		pointshoot:TimeScaleFadeIn(0, 0.1)
	elseif CLIENT then
		surface.PlaySound('hitman/start.mp3')
		self:ScreenFlash(150, 0, 0.2)

		local emitter = ParticleEmitter(LocalPlayer():GetPos())
		local center = LocalPlayer():GetPos()

		for i = 1, 100 do
			local rand = VectorRand()
			local part = emitter:Add('effects/spark', center + rand * 200)
			local dir = VectorRand()
			local grav =  VectorRand() * 150
			if part then
				part:SetDieTime(0.5)

				part:SetStartAlpha(255)
				part:SetEndAlpha(0) 

				part:SetStartSize(5)
				part:SetEndSize(0)

				part:SetGravity(grav)
				part:SetVelocity(dir * 500)
				part:SetAngles(dir:Angle())
			end
		end
		emitter:Finish()
		

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

if CLIENT then
	local startAlpha, targetAlpha = 0, 0
	local duration, startTime = 0, 0
	function SWEP:DrawFlash()
		if not startTime then 
			return 
		end

		local dt = self.drawtime - startTime
		if dt >= duration then
			startTime = nil
			return
		end

		surface.SetDrawColor(255, 255, 255, Lerp(dt / duration, startAlpha, targetAlpha))
		surface.DrawRect(0, 0, ScrW(), ScrH())
	end

	function SWEP:ScreenFlash(startalpha, targetalpha, dura)
		startAlpha = startalpha
		targetAlpha = targetalpha
		duration = dura
		startTime = RealTime()
	end

	table.insert(SWEP.DrawHUDs, SWEP.DrawFlash)
end