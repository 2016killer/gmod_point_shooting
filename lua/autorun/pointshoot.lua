--[[
    作者: 白狼
]]

pointshoot = pointshoot or {}
pointshoot.Marks = {}
pointshoot.OriginWeaponClass = SERVER and {} or nil
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
    if SERVER then
        ply:SelectWeapon(self:GetWeapon(ply))

        net.Start('PointShootExecute')
        net.Send(ply)
    elseif CLIENT then
        self.aiming = false
        self.shootCount = 0
        self.fireSyncTime = RealTime()
        hook.Add('Think', 'pointshoot.autoaim', function()
            self:AutoAim()
        end)
    end
    self:ExecuteEffect(ply)
    // PrintTable(self.Marks)
end


-- ============= 鼠标控制 =============
function pointshoot:GetWeapon(ply)
    if SERVER then
        local idx = ply:EntIndex()
        local class = self.OriginWeaponClass[idx] or ply:GetNWString('PSDWeapon', 'weapon_pistol')
        local wp = ply:GetWeapon(class)

        if IsValid(wp) then
            return wp, class
        else
            return nil
        end
    elseif CLIENT then
        local class = self.OriginWeaponClass or ply:GetNWString('PSDWeapon', 'weapon_pistol')
        local wp = ply:GetWeapon(class)

        if IsValid(wp) then
            return wp, class
        else
            return nil
        end
    end
end


if CLIENT then
    local target = nil
    local duration = 0
    local timer = 0
    hook.Add('InputMouseApply', 'pointshoot.aim', function(cmd, x, y, ang)
        if not target then 
            return 
        end

        timer = timer + RealFrameTime()

        local pos = pointshoot:GetMarkPos(target)
        if not pos then
            target = nil
            hook.Run('PointShootAimFinish', nil)
            return
        end

        local targetDir = (pos - EyePos()):GetNormal()
        local origin = cmd:GetViewAngles()
        local rate = math.Clamp(timer / duration, 0, 1) 
        
        cmd:SetViewAngles(LerpAngle(rate, origin, targetDir:Angle()))

        if rate == 1 or origin:Forward():Dot(targetDir) > 0.9995 then
            hook.Run('PointShootAimFinish', targetDir)
            target, duration, timer = nil, 0, 0
        end
    end)

    function pointshoot:Aim(mark, dura)
        duration = math.max(dura, 0.01)
        timer = 0
        target = mark
    end

    function pointshoot:AutoAim()
        -- 瞄准、射击
        if not self.Marks or #self.Marks < 1 then
            hook.Remove('Think', 'pointshoot.autoaim')
            return
        end

        local wp = pointshoot:GetWeapon(LocalPlayer())
        if not wp then 
            return 
        end

        if self.aiming or wp:GetNextPrimaryFire() > RealTime() then
            return
        end

        self:Aim(self.Marks[#self.Marks], 1)
        self.aiming = true

        return true
    end

    hook.Add('PointShootAimFinish', 'pointshoot.fire', function(targetDir)
        local self = pointshoot
        self.aiming = false

        local wp = LocalPlayer():GetWeapon(self.OriginWeaponClass or 'weapon_pistol')
        self:ClientFire(wp, targetDir)
        table.remove(self.Marks, #self.Marks)
        self.shootCount = self.shootCount + 1
        
        if #self.Marks < 1 or (RealTime() - self.fireSyncTime >= 0.5 and self.shootCount > 0) then
            self.fireSyncTime = RealTime()
        
            net.Start('PointShootFireSync')
                net.WriteInt(self.shootCount, 32)
            net.SendToServer()

            self.shootCount = 0
        end
    end)

    function pointshoot:ClientFire(wp)
        if not IsValid(wp) then 
            return 
        end

        local vm = LocalPlayer():GetViewModel()
        
        if not IsValid(vm) then return end
        
        local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
        
        if (seq == -1) then return end
        
        vm:SendViewModelMatchingSequence(seq)
        vm:SetPlaybackRate(1)

        wp:EmitSound('Weapon_Pistol.Single')
    end
elseif SERVER then
    util.AddNetworkString('PointShootFireSync')
    net.Receive('PointShootFireSync', function(len, ply)
        local count = net.ReadInt(32)
        pointshoot:FireSync(ply, count)
    end)

    function pointshoot:FireSync(ply, count)
        local idx = ply:EntIndex()
        local marks = self.Marks[idx]
        local wp = ply:GetActiveWeapon()

        local len = #marks
        if not istable(marks) or len < 1 then
            return
        end
        
        for i = len, math.max(len - count + 1, 1), -1 do
            self:ServerFire(ply, wp, marks[i])
            table.remove(marks, i)
        end
    end
end


function pointshoot:WeaponParse(wp)
    if not IsValid(wp) or wp:Clip1() <= 0 then 
        return 
    end

    local class = wp:GetClass()
    local isscripted = wp:IsScripted()
    if not isscripted then
        return self.noscriptedguns[class]
    else
        local istfa = weapons.IsBasedOn(class, 'tfa_gun_base')
        return {
            RPM = wp.Primary.RPM,
            Damage = wp.Primary.Damage,
            FireHandle = wp.PrimaryAttack,
            NextPrimaryFire = wp:GetNextPrimaryFire()
        }
    end
end

function pointshoot:TFAFire(ply, wp, mark)
    if CLIENT then
        if not IsValid(wp) then 
            return 
        end

        wp:PrimaryAttack()
    elseif SERVER then

    end
end

function pointshoot:DefaultFire(ply, wp, mark)
    if CLIENT then
        if not IsValid(wp) then 
            return 
        end

        local vm = ply:GetViewModel()
        
        if not IsValid(vm) then return end
        
        local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
        
        if (seq == -1) then return end
        
        vm:SendViewModelMatchingSequence(seq)
        vm:SetPlaybackRate(1)

        wp:EmitSound(wp.ps_wpdata.Sound)
    elseif SERVER then
        if not IsValid(wp) then
            return
        end

        local endpos = self:GetMarkPos(mark)
        if not endpos then
            return
        end

        local start = ply:EyePos()
        local bulletInfo = {
            Spread = Vector(0, 0, 0),
            Force = 1000,
            Damage = wp.ps_wpdata.Damage,
            Num = 1,
            Tracer = 0,

            Attacker = ply,
            Inflictor = wp,

            Dir = (endpos - start):GetNormal(),
            Src = start
        }

        wp:FireBullets(bulletInfo)
        wp:SetClip1(wp:Clip1() - 1)
    end
end

function pointshoot:MeleeFire(ply, wp, mark)
    if CLIENT then
        if not IsValid(wp) then 
            return 
        end

        local vm = ply:GetViewModel()
        
        if not IsValid(vm) then return end
        
        local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
        
        if (seq == -1) then return end
        
        vm:SendViewModelMatchingSequence(seq)
        vm:SetPlaybackRate(1)

        wp:EmitSound(wp.ps_wpdata.Sound)
    elseif SERVER then
        if not IsValid(wp) then
            return
        end

        local endpos = self:GetMarkPos(mark)
        if not endpos then
            return
        end
        local start = ply:EyePos()
        local dir = (endpos - start):GetNormal()
        ply:DropWeapon(wp, dir, dir * 5000)
    end
end


pointshoot.noscriptedguns = {
	['weapon_pistol'] = {
		RPM = 600,
		Damage = 10,
        Sound = 'Weapon_Pistol.Single',
        FireHandle = pointshoot.DefaultFire,
	},
	['weapon_357'] = {
		RPM = 180,
		Damage = 60,
        Sound = 'Weapon_357.Single',
        FireHandle = pointshoot.DefaultFire,
	},
	['weapon_ar2'] = {
		RPM = 1200,
		Damage = 20,
        Sound = 'Weapon_AR2.Single',
        FireHandle = pointshoot.DefaultFire,
	},
	['weapon_crossbow'] = {
		RPM = 120,
		Damage = 150,
        Sound = 'Weapon_Crossbow.Single',
        FireHandle = pointshoot.DefaultFire,
	},
	['weapon_shotgun'] = {
		RPM = 120,
		Damage = 45,
        Sound = 'Weapon_Shotgun.Single',
        FireHandle = pointshoot.DefaultFire,
	},
	['weapon_smg1'] = {
		RPM = 6000,
		Damage = 6,
        Sound = 'Weapon_SMG1.Single',
        FireHandle = pointshoot.DefaultFire,
	},
    ['weapon_crowbar'] = {
        RPM = 6000,
        Damage = 0,
        Sound = 'Weapon_Crowbar.Single',
        FireHandle = pointshoot.MeleeFire,
    }
}

function pointshoot:Start(ply)
    local wp = ply:GetActiveWeapon()
    if not IsValid(wp) then
        return
    end

end