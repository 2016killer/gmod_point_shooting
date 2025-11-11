pointshoot = pointshoot or {}
local pointshoot = pointshoot or {}


if CLIENT then
	--------------------- 选中目标绘制
	local wireframe = Material('models/wireframe')
	hook.Add('PostDrawOpaqueRenderables', 'pointshoot.drawselect', function()
		if not pointshoot.Enabled or not pointshoot.EnableDrawSelect then
			return
		end

		if not pointshoot.Targets or not pointshoot.TargetsHitBoxBone then
			return
		end

		for i, target in ipairs(pointshoot.Targets) do
			local hitthing = pointshoot.TargetsHitBoxBone[i]

			if isvector(hitthing) then
				render.SetMaterial(wireframe)
				render.DrawSphere(hitthing, 10, 8, 8, Color(255, 255, 255, 255))
			elseif IsValid(target) then
				render.SetMaterial(wireframe)
				render.DrawSphere(target:GetBonePosition(hitthing), 
					10, 8, 8, Color(255, 255, 255, 255))
			end
		end
	end)

	--------------------- 屏闪特效
	local timecheck = 0
	hook.Add('HUDPaint', 'pointshoot.screenfade', function()
		local curtime = CurTime()
		if timecheck == curtime then
			return
		end
		timecheck = curtime

		if not pointshoot.ScreenFadeData then
			return
		end

		local ScreenFadeData = pointshoot.ScreenFadeData

		local dt = RealFrameTime()
		ScreenFadeData.Timer = ScreenFadeData.Timer + dt
		if ScreenFadeData.Timer >= ScreenFadeData.Duration then
			pointshoot.ScreenFadeData = nil
			return
		else
			local alpha = ScreenFadeData.Alpha
			local target = ScreenFadeData.Target
			alpha = alpha + dt * ScreenFadeData.Speed * ScreenFadeData.Dir

			surface.SetDrawColor(255, 255, 255, alpha)
			surface.DrawRect(0, 0, ScrW(), ScrH())
			
			ScreenFadeData.Alpha = alpha
		end
	end)

	function pointshoot:StartScreenFade(startalpha, targetalpha, duration)
		pointshoot.ScreenFadeData = {
			Alpha = startalpha,
			Target = targetalpha,
			Speed = math.abs(targetalpha - startalpha) / duration,
			Dir = targetalpha > startalpha and 1 or -1,
			Duration = duration,
			Timer = 0
		}
	end

	--------------------- 自瞄特效
	local function Smooth(x)
		if x >= 1 then return 1 end
		return -(x - 1)^2 + 1
	end

	local timercount = 0
	local function targetspop(targets, hitthings)
		table.remove(hitthings, #hitthings)
		table.remove(targets, #targets)
		timercount = 0
	end
	hook.Add('InputMouseApply', 'pointshoot.execute', function(cmd, x, y, ang)
		if not pointshoot.Enabled or not pointshoot.Executed or not pointshoot.EnableAutoAim then
			return
		end

		local targets = (pointshoot.Targets or {})
		local hitthings = (pointshoot.TargetsHitBoxBone or {})

		if #targets < 1 then
			timercount = 0
			pointshoot.EnableAutoAim = false
			pointshoot:Finish(LocalPlayer(), targets, hitthings)
			return
		end
		timercount = timercount + RealFrameTime()

		local target = targets[#targets]
		local hitthing = hitthings[#hitthings]

		local origin = cmd:GetViewAngles()
		local targetDir = nil
		if isvector(hitthing) then
			targetDir = (hitthing - EyePos()):GetNormal()
		elseif IsValid(target) then
			targetDir = (target:GetBonePosition(hitthing) - EyePos()):GetNormal()
		else
			targetspop(targets, hitthings)
			return
		end
		
		if timercount > 0.1 then
			targetspop(targets, hitthings)
			return
		end

		local rate = Smooth(timercount / 0.1)

		cmd:SetViewAngles(
			LerpAngle(
				rate, 
				origin, 
				targetDir:Angle()
			)
		)
	end)

elseif SERVER then
	--------------------- 时间缩放特效
	function pointshoot:TimeScaleFadeIn(target, duration)
		if timer.Exists('pointshoot_timescale') then
			timer.Remove('pointshoot_timescale')
		end

		self.StartTime = CurTime()
		self.StartScale = game.GetTimeScale()
		timer.Create('pointshoot_timescale', 0, 0, function()
			local dt = CurTime() - self.StartTime

			if dt >= duration then
				timer.Remove('pointshoot_timescale')
				game.SetTimeScale(target)
			else
				game.SetTimeScale(
					Lerp(
						math.Clamp(dt / duration, 0, 1), 
						self.StartScale, 
						target
					)
				)
			end
		end)
	end
end


function pointshoot:StartEffect(ply, wpclassList)
	if CLIENT then
		surface.PlaySound('hitman/start.mp3')
		local vm = ply:GetViewModel(0)
		local vm1 = ply:GetViewModel(1)

		
		self:StartScreenFade(150, 0, 0.3)
		local center = ply:GetPos()
		local emitter = ParticleEmitter(center)
		
		for i = 1, 100 do
			local rand = VectorRand()
			local part = emitter:Add('effects/spark', center + (rand - 0.5 * rand) * 500)
			local dir = VectorRand()
			local grav =  VectorRand() * 150
			if part then
				part:SetDieTime(1)

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
	elseif SERVER then
		self:TimeScaleFadeIn(0, 0.1)
	end
end

function pointshoot:FinishEffect(ply, targets, hitboxbones)
	if CLIENT then
		return
	elseif SERVER then
		self:TimeScaleFadeIn(1, 0.1)
	end
end

function pointshoot:SelectEffect(tr)
	if CLIENT then
		surface.PlaySound('hitman/select.mp3')
		self:StartScreenFade(150, 0, 0.3)
	elseif SERVER then
		return
	end
end

function pointshoot:ExecuteEffect()
	if CLIENT then
		surface.PlaySound('hitman/execute.mp3')
		self:StartScreenFade(100, 0, 0.3)
		self.EnableAutoAim = true
	elseif SERVER then
		return
	end
end