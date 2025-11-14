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
        pointshoot:TimeScaleFadeIn(0.3, 0.1)
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
        ply:SelectWeapon(self:GetOriginWeapon(ply))
        if not self.Marks[ply:EntIndex()] or #self.Marks[ply:EntIndex()] < 1 then 
            game.SetTimeScale(1)
            return 
        end

        net.Start('PointShootExecute')
        net.Send(ply)
    elseif CLIENT then
        if #self.Marks < 0 then return end
        local wp = self:GetOriginWeapon(LocalPlayer())
        if not IsValid(wp) then return end
        wp:SetNextPrimaryFire(0)

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


function pointshoot:FinishEffect(ply)
    if SERVER then
        game.SetTimeScale(1)
        timer.Simple(0.5, function()
            game.SetTimeScale(0.1)
            timer.Simple(0.2, function()
                game.SetTimeScale(1)
            end)
        end)
    elseif CLIENT then
        return
    end
end

-- ============= 鼠标控制 =============
function pointshoot:GetOriginWeapon(ply)
    if SERVER then
        local idx = ply:EntIndex()
        local class = self.OriginWeaponClass[idx] or ''
        local wp = ply:GetWeapon(class)

        if IsValid(wp) then
            return wp, class
        else
            return nil
        end
    elseif CLIENT then
        local class = self.OriginWeaponClass or ''
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
        if not LocalPlayer():Alive() or LocalPlayer():InVehicle() then
            hook.Remove('Think', 'pointshoot.autoaim')
            net.Start('PointShootFinish')
            net.SendToServer()
            self:FinishEffect(LocalPlayer())
            return
        end

        -- 瞄准、射击
        if not self.Marks or #self.Marks < 1 then
            hook.Remove('Think', 'pointshoot.autoaim')
            net.Start('PointShootFinish')
            net.SendToServer()
            self:FinishEffect(LocalPlayer())
            return
        end

        local wp = pointshoot:GetOriginWeapon(LocalPlayer())
        if self.aiming or (IsValid(wp) and wp:GetNextPrimaryFire() > RealTime()) then
            return
        end

        self:Aim(self.Marks[#self.Marks], 0.3)
        self.aiming = true

        return true
    end

    hook.Add('PointShootAimFinish', 'pointshoot.fire', function(targetDir)
        local self = pointshoot
        self.aiming = false

        if not LocalPlayer():Alive() or LocalPlayer():InVehicle() then
            return
        end

        local wp = self:GetOriginWeapon(LocalPlayer())
        if IsValid(wp) then 
            local wpdata = wp.ps_wpdata
            if istable(wpdata) then wpdata.FireHandle(wp, mark) end
        end
        
        table.remove(self.Marks, #self.Marks)
        self.shootCount = self.shootCount + 1
        
        if #self.Marks < 1 or (RealTime() - self.fireSyncTime >= 0.5 and self.shootCount > 0) then
            self.fireSyncTime = RealTime()
        
            net.Start('PointShootFireSync')
                net.WriteInt(self.shootCount, 32)
            net.SendToServer()

            self.shootCount = 0
            if #self.Marks < 1 then wp:SetNextPrimaryFire(0) end
        end
    end)

elseif SERVER then
    util.AddNetworkString('PointShootFinish')
    util.AddNetworkString('PointShootFireSync')

    net.Receive('PointShootFireSync', function(len, ply)
        local count = net.ReadInt(32)
        pointshoot:FireSync(ply, count)
    end)

    net.Receive('PointShootFinish', function(len, ply)
        pointshoot:FinishEffect(ply)
    end)

    function pointshoot:FireSync(ply, count)
        local idx = ply:EntIndex()
        local marks = self.Marks[idx]
        local wp = self:GetOriginWeapon(ply)
        if not IsValid(wp) or not wp.ps_wpdata then return end
        

        local len = #marks
        if not istable(marks) or len < 1 then
            return
        end
        
        for i = len, math.max(len - count + 1, 1), -1 do
            wp.ps_wpdata.FireHandle(wp, marks[i])
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
            FireHandle = pointshoot.TFAFire
        }
    end
end

pointshoot.DefaultFire = function(wp, mark)
    if not IsValid(wp) then return end
    local ply = wp:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if wp:Clip1() <= 0 then return end

    if CLIENT then
        local vm = ply:GetViewModel()
        
        if not IsValid(vm) then return end
        
        local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
        
        if (seq == -1) then return end
        
        vm:SendViewModelMatchingSequence(seq)
        vm:SetPlaybackRate(1)

        wp:EmitSound(wp.ps_wpdata.Sound)
        wp:SetNextPrimaryFire(RealTime() + 1 / wp.ps_wpdata.RPM * 60)
    elseif SERVER then
        local endpos = pointshoot:GetMarkPos(mark)
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
    end
end

pointshoot.MeleeFire = function(wp, mark)
    if not IsValid(wp) then return end
    local ply = wp:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() then return end

    if CLIENT then
        local vm = ply:GetViewModel()
        
        if not IsValid(vm) then return end
        
        local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
        
        if (seq == -1) then return end
        
        vm:SendViewModelMatchingSequence(seq)
        vm:SetPlaybackRate(1)

        wp:EmitSound(wp.ps_wpdata.Sound)
    elseif SERVER then
        local endpos = self:GetMarkPos(mark)
        if not endpos then
            return
        end
        local start = ply:EyePos()
        local dir = (endpos - start):GetNormal()
        ply:DropWeapon(wp, dir, dir * 5000)
    end
end

pointshoot.TFAFire = function(wp, mark)
    if not IsValid(wp) then return end
    local ply = wp:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if wp:Clip1() <= 0 then return end

    if CLIENT then
        wp:SetNextPrimaryFire(0)
        wp:PrimaryAttack()
        wp:SetNextPrimaryFire(RealTime() + 1 / wp.Primary.RPM * 60)
        wp:EmitSound(wp.Primary.Sound)
    elseif SERVER then
        // local endpos = pointshoot:GetMarkPos(mark)
        // if not endpos then
        //     return
        // end
        // local start = ply:EyePos()
        // local dir = (endpos - start):GetNormal()
        // ply:DropWeapon(wp, dir, dir * 5000)
    end
end


pointshoot.noscriptedguns = {
	['weapon_pistol'] = {
		RPM = 600,
		Damage = 10,
        Sound = 'Weapon_Pistol.Single',
        FireHandle = pointshoot.DefaultFire,
        SoundClear = pointshoot.DefaultSoundClear,
	},
	['weapon_357'] = {
		RPM = 300,
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
		RPM = 180,
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
        RPM = 180,
        Damage = 0,
        Sound = 'Weapon_Crowbar.Single',
        FireHandle = pointshoot.MeleeFire,
    }
}


if SERVER then
    util.AddNetworkString('PointShootWeaponParse')
elseif CLIENT then
    net.Receive('PointShootWeaponParse', function()
        local class = net.ReadString()
        local wp = LocalPlayer():GetWeapon(class)
        if not IsValid(wp) then
            return
        end
        pointshoot.OriginWeaponClass = class

        local wpdata = pointshoot:WeaponParse(wp) or pointshoot.noscriptedguns['weapon_crowbar']
        wp.ps_wpdata = wpdata
    end)
end
if SERVER then
    hook.Add('PlayerSwitchWeapon', 'pointshoot.weapon.parse', function(ply, oldwp, newwp)
        if not IsValid(oldwp) or oldwp:GetClass() == 'pointshoot'then
            return
        end

        if not IsValid(newwp) or newwp:GetClass() ~= 'pointshoot' then
            return
        end

        local wpdata = pointshoot:WeaponParse(oldwp)
        if not wpdata then
            return true
        end
    
        oldwp.ps_wpdata = wpdata
        pointshoot.OriginWeaponClass[ply:EntIndex()] = oldwp:GetClass()
    
        net.Start('PointShootWeaponParse')
            net.WriteString(oldwp:GetClass())
        net.Send(ply)
    end)

    concommand.Add('pointshoot', function(ply, cmd, args)
        local pswp = ents.Create('pointshoot')
        pswp:SetPos(ply:GetPos())
        pswp:Spawn()
        ply:PickupWeapon(pswp)
        ply:SelectWeapon(pswp)
    end)

end

