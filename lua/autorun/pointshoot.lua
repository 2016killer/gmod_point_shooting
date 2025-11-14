--[[
    作者: 白狼
]]

pointshoot = pointshoot or {}
pointshoot.Marks = {}
pointshoot.OriginWeapon = {}
local pointshoot = pointshoot

-- ============= 时间控制 =============
function pointshoot:TimeScaleFadeIn(target, duration)
	if CLIENT then return end
    if timer.Exists('pointshoot_timescale') then
        timer.Remove('pointshoot_timescale')
    end

    local StartTime = CurTime()
    local StartScale = game.GetTimeScale()
    timer.Create('pointshoot_timescale', 0, 0, function()
        local dt = CurTime() - StartTime

        if dt >= duration then
            timer.Remove('pointshoot_timescale')
            game.SetTimeScale(target)
        else
            game.SetTimeScale(
                Lerp(
                    math.Clamp(dt / duration, 0, 1), 
                    StartScale,
                    target
                )
            )
        end
    end)
end

-- ============= 标记数据处理 =============
function pointshoot:GetMarkPos(mark)
    local _, lpos, ent, _ = unpack(mark)
    if not isbool(ent) and not IsValid(ent) then
        return nil
    elseif not isbool(ent) then
        return ent:LocalToWorld(lpos)
    else
        return lpos
    end
end

function pointshoot:GetMarkType(mark) return mark[1] end
function pointshoot:GetMarkSize(mark) return mark[4] end
function pointshoot:SetMarkSize(mark, size) mark[4] = size end

function pointshoot:PackMark(tr)
    return {
        tr.HitGroup == HITGROUP_HEAD,
        IsValid(tr.Entity) and tr.Entity:WorldToLocal(tr.HitPos) or tr.HitPos,
        IsValid(tr.Entity) and tr.Entity or false,
        0
    }
end

-- ============= 执行请求处理 =============
function pointshoot:ExecuteEffect(ply)
    if SERVER then

    elseif CLIENT then
        surface.PlaySound('hitman/execute.mp3')
    end
end

if SERVER then
    util.AddNetworkString('PointShootExecute')
elseif CLIENT then
    net.Receive('PointShootExecute', function()
        pointshoot:Execute()
    end)
end

function pointshoot:Execute(ply, marks)
    self:ExecuteEffect(ply)
    if SERVER then
        ply:SelectWeapon(self.OriginWeapon[ply:EntIndex()] or 'tfa_silverballer_f')

        net.Start('PointShootExecute')
        net.Send(ply)
    elseif CLIENT then

    end
    PrintTable(self.Marks)
end


-- ============= 鼠标控制 =============
if CLIENT then
    local target = nil
    local duration = 0
    local timer = 0
    local wp = nil
    hook.Add('InputMouseApply', 'pointshoot.aim', function(cmd, x, y, ang)
        if not target or not IsValid(wp) then 
            return 
        end
        
        timer = timer + RealFrameTime()

        local pos = pointshoot:GetMarkPos(target)
        if not pos then
            target = nil
            hook.Run('PointShootAimFinish', wp, nil)
            return
        end

        local targetDir = (pos - EyePos()):GetNormal()
        local origin = cmd:GetViewAngles()
        local rate = math.Clamp(timer / duration, 0, 1) 
        
        cmd:SetViewAngles(LerpAngle(rate, origin, targetDir:Angle()))

        if rate == 1 or origin:Forward():Dot(targetDir) > 0.9995 then
            hook.Run('PointShootAimFinish', wp, targetDir)
            target, duration, timer = nil, 0, 0
        end
    end)

    function pointshoot:Aim(wp, mark, dura, timemode)
        wp = wp
        duration = math.max(dura, 0.01)
        realTimeMode = timemode or true
        timer = 0
        target = mark
    end
end

// function pointshoot:CTSShoot(count)
// 	if SERVER then
// 		if not istable(self.Marks) or #self.Marks < 1 then
// 			return
// 		end
// 		local len = #self.Marks
// 		for i = len, math.max(len - count + 1, 1), -1 do
// 			self:ServerFire(self.Marks[i])
// 			table.remove(self.Marks, i)
// 		end
// 	end
// end

function pointshoot:AutoAim(wp)
	if SERVER then return end

	-- 瞄准、射击
    if not self.Marks or #self.Marks < 1 then
        self:CallDoubleEnd('CTSFinish')
        return
    end

    if self.aiming or not self:CheckFireAble() then
        return
    end

    self:Aim(self.Marks[#self.Marks], 0.1, true)
    self.aiming = true

	return true
end


// hook.Add('PointShootAimFinish', 'pointshoot.fire', function(wp, targetDir)
// 	if not IsValid(wp) then
// 		return
// 	end
// 	wp.aiming = false

// 	wp:ClientFire(targetDir)
// 	table.remove(wp.Marks, #wp.Marks)
// 	wp.shootCount = wp.shootCount + 1
	
// 	if #wp.Marks < 1 or (wp.drawtime - wp.fireTime >= 0.25 and wp.shootCount > 0) then
// 		wp.fireTime = wp.drawtime
// 		wp:CallDoubleEnd('CTSShoot', wp.shootCount)
// 		wp.shootCount = 0
// 	end

// 	wp:SetNextPrimaryFire(RealTime() + 0.05)
// end)

function pointshoot:ServerFire(wp, mark)
	if not IsValid(wp) then
		return
	end

	local endpos = self:GetMarkPos(mark)
	if not endpos then
		return
	end
	local owner = wp:GetOwner()
	if not IsValid(owner) then
		return
	end

	local start = owner:EyePos()
	local bulletInfo = {
		Spread = Vector(0, 0, 0),
		Force = 1000,
		Damage = 10000,
		Num = 1,
		Tracer = 0,
		Attacker = owner,
		Inflictor = self,
		Damage = 1000,
		Dir = (endpos - start):GetNormal(),
		Src = start
	}

	wp:FireBullets(bulletInfo)
	wp:SetClip1(wp:Clip1() - 1)
end

function pointshoot:ClientFire(dir, rate, index)
	if not dir then return end

	local vm = self:GetOwner():GetViewModel(index)
	
	if not IsValid(vm) then return end
	
	local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
	
	if (seq == -1) then return end
	
	vm:SendViewModelMatchingSequence(seq)
	vm:SetPlaybackRate(rate or 1)

	self:EmitSound('Weapon_Pistol.Single')
end


function pointshoot:WeaponParse(wp)
	if not IsValid(wp) or wp:Clip1() <= 0 then return end

	local class = wp:GetClass()
	local isscripted = wp:IsScripted()
	if not isscripted then
		return self.noscriptedguns[class]
	else
		local istfa = weapons.IsBasedOn(class, 'tfa_gun_base')
	end
end


pointshoot.noscriptedguns = {
	['weapon_pistol'] = {
		interval = 0.1,
		Damage = 10
	},
	['weapon_357'] = {
		interval = 0.3,
		Damage = 60
	},
	['weapon_ar2'] = {
		interval = 0.05,
		Damage = 20
	},
	['weapon_crossbow'] = {
		interval = 0.5,
		Damage = 150,
	},
	['weapon_shotgun'] = {
		interval = 0.5,
		Damage = 45,
	},
	['weapon_smg1'] = {
		interval = 0.01,
		Damage = 6,
	},
}

