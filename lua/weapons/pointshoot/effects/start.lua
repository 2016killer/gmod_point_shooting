local function filter(ent)
	if ent:GetOwner() == LocalPlayer() or ent:GetParent() == LocalPlayer() then
		return nil
	end

	local class = ent:GetClass()

	if class == 'npc_grenade_frag' then
		if IsValid(ent.psss_skin) then
			ent.psss_skin:Remove()
		end

		local grenade = ClientsideModel(ent:GetModel())
		grenade:SetPos(ent:GetPos())
		grenade:SetAngles(ent:GetAngles())
		grenade:SetParent(ent)

		ent.psss_skin = grenade

		ent:CallOnRemove('sixthsense_grenade', function() if IsValid(grenade) then grenade:Remove() end end)

		return 0, grenade
	end

	if ent:IsNPC() then
		if ent:LookupBone('ValveBiped.Bip01_Head1') then
			if IsValid(ent.psss_skin) then
				ent.psss_skin:Remove()
			end

			local skeleton = ClientsideModel('models/player/skeleton.mdl', RENDERGROUP_OTHER)
			skeleton:SetParent(ent)
			skeleton:AddEffects(EF_BONEMERGE)
			skeleton:SetNoDraw(true)

			ent.psss_skin = skeleton

			ent:CallOnRemove('sixthsense_skeleton', function() if IsValid(skeleton) then skeleton:Remove() end end)

			return 0, skeleton
		else
			return 0
		end
	end

	if ent:GetMaxHealth() > 2 then
		return 1
	end

	return nil
end

function SWEP:StartEffect(ply)
	if SERVER then
		pointshoot:TimeScaleFadeIn(0, 0.1)
	elseif CLIENT then
		surface.PlaySound('hitman/start.mp3')
		self:ScreenFlash(150, 0, 0.2)

		local succ, err = pcall(sixthsense.Start, sixthsense, LocalPlayer(), 500, 0.1, 0.5, 30, false, filter)
		if not succ then
			print('[PointShooting]: sixthsense.Start failed:', err)
		end

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