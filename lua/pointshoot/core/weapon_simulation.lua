--[[
    作者: 白狼
]]

pointshoot = pointshoot or {}
pointshoot.zerovec = Vector(0, 0, 0)

function pointshoot:WeaponParse(wp)
    if not IsValid(wp) then 
        return false
    end

    -- 原版武器, 查表
    if not wp.Primary then
        wp.Primary = self.noscriptedgunsPrimary[wp:GetClass()]
        return wp.Primary
    end

    if not istable(wp.Primary) then
        return
    end

    -- MWB 武器
    if istable(wp.Bullet) then
        wp.Primary.Damage = istable(wp.Bullet.Damage) and wp.Bullet.Damage[1] or nil
        wp.Primary.Force = wp.Bullet.PhysicsMultiplier
        wp.Primary.IsMelee = false
        wp.Primary.Num = wp.Bullet.NumBullets
    end

    wp.Primary.Damage = wp.Primary.Damage or 0
    wp.Primary.Force = wp.Primary.Force or 0
    wp.Primary.Num = wp.Primary.Num or 0
    wp.Primary.Sound = wp.Primary.Sound or ''
    wp.Primary.ActPrimary = wp.Primary.ActPrimary or ACT_VM_PRIMARYATTACK
    wp.Primary.ActDeploy = wp.Primary.ActDeploy or ACT_VM_DEPLOY
    wp.Primary.Spread = isvector(wp.Primary.Spread) and wp.Primary.Spread or pointshoot.zerovec
        
    return wp.Primary
end

pointshoot.SetAmmo = function(self, ply)

end

pointshoot.GetAmmo = function(self, ply)
    if not self.Primary.IsMelee and not self.Primary.IsGrenade then
        return self:Clip1()
    elseif self.Primary.IsGrenade then
        return ply:GetAmmoCount(self:GetPrimaryAmmoType() or 10)
    else
        return 1
    end
end


pointshoot.Fire = function(self, start, endpos, dir, attacker)
    dir = dir or (endpos - start):GetNormal()
    if CLIENT then
        if pointshoot.CVarsCache.ps_rpm_mode then
            pointshoot.NextPrimaryFire = RealTime() + 60 / pointshoot.CVarsCache.ps_rpm_mul / self.Primary.RPM
        else
            pointshoot.NextPrimaryFire = 0
        end

        if self.Primary.Sound then
            self:EmitSound(self.Primary.Sound)
        end

        local vm = attacker:GetViewModel()
        if not IsValid(vm) then return end
        local seq = vm:SelectWeightedSequence(self.Primary.ActPrimary)
        
        if (seq == -1) then return end
        
        vm:SendViewModelMatchingSequence(seq)
        vm:SetPlaybackRate(1)

    elseif SERVER and not self.Primary.IsMelee and not self.Primary.IsGrenade then
        local damage = self.Primary.Damage * pointshoot.CVarsCache.ps_damage_mul
        local damagePenetration = self.Primary.Damage * pointshoot.CVarsCache.ps_damage_penetration_mul

        local bulletInfo = {
            Spread = self.Primary.Spread,
            Force = self.Primary.Force,
            Num = self.Primary.Num,
            Tracer = 0,

            Attacker = attacker,
            Inflictor = self,

            Dir = (endpos - start):GetNormal(),
        }

        bulletInfo.Src = start
        bulletInfo.Damage = damage
        self:FireBullets(bulletInfo)
        bulletInfo.Damage = damagePenetration
        bulletInfo.Src = endpos
        self:FireBullets(bulletInfo)
    elseif SERVER and self.Primary.IsMelee then
        attacker:DropWeapon(self)

        local ent = ents.Create('pointshoot_melee')
        ent:SetPos(start + dir * 100)
        ent:SetAngles(attacker:EyeAngles())
        ent:Bind(self)
        ent:Spawn()

        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(dir * 2000)
        end
    elseif SERVER and self.Primary.IsGrenade then
        local grenade = ents.Create('npc_grenade_frag')
        grenade:SetPos(start + dir * 20)
        grenade:SetAngles(attacker:EyeAngles())
        grenade:SetSaveValue('m_hThrower', attacker)
        grenade:Spawn()

        grenade:Fire('SetTimer', 0.5, 0)

        local phys = grenade:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(dir * 2000)
        end     
    end
end


-- ============= 鼠标控制 =============
if CLIENT then
    local target = nil
    local duration = 0
    local timer = 0
    function pointshoot:InputMouseApply(cmd, x, y, ang)
        if not target then 
            return 
        end

        timer = timer + RealFrameTime()

        local pos = pointshoot:GetMarkPos(target)
        if not pos then
            target = nil
            hook.Run('PointShootAimFinish', nil, nil)
            return
        end

        local targetDir = (pos - LocalPlayer():EyePos()):GetNormal()
        local origin = cmd:GetViewAngles()
        local rate = math.Clamp(timer / duration, 0, 1) 
        rate = origin:Forward():Dot(targetDir) > 0.9995 and 1 or rate
        
        cmd:SetViewAngles(LerpAngle(rate, origin, targetDir:Angle()))

        if rate == 1 then
            hook.Run('PointShootAimFinish', pos, targetDir)
            target, duration, timer = nil, 0, 0
        end
    end

    function pointshoot:Aim(mark, dura)
        duration = math.max(dura, 0.01)
        timer = 0
        target = mark
    end

    function pointshoot:AutoAim()
        if not self.Marks or #self.Marks < 1 or 
           not IsValid(LocalPlayer():GetActiveWeapon()) or 
           not LocalPlayer():Alive() or LocalPlayer():InVehicle() 
        then
            self:DisableAim()
            self:CallDoubleEnd('CTSFinish', LocalPlayer())
            return
        end

        local mark = self.Marks[#self.Marks]
        if self.aiming == mark then
            return
        end

        self.aiming = mark
        self:Aim(mark, self.CVarsCache.ps_aim_cost)
        

        return true
    end

    function pointshoot:AimFinish(pos, dir)
        self.aiming = false
        if self.NextPrimaryFire > RealTime() then
            return
        end

        
        table.remove(self.Marks, #self.Marks)
        self.shootCount = self.shootCount + 1
        
        if #self.Marks < 1 or (RealTime() - self.fireSyncTime >= 0.5 and self.shootCount > 0) then
            self.fireSyncTime = RealTime()
        
            net.Start('PointShootFireSync')
                net.WriteInt(self.shootCount, 32)
            net.SendToServer()

            self.shootCount = 0
        end

        local wp = LocalPlayer():GetActiveWeapon()
        local wpdata = self:WeaponParse(wp)
        
        if not pos or not wpdata or self.GetAmmo(wp, LocalPlayer()) < 1 then 
            return
        end
                
        self.Fire(wp, LocalPlayer():EyePos(), pos, dir, LocalPlayer())
    end
    

    function pointshoot:EnableAim()
        self.aiming = false
        self.shootCount = 0
        self.fireSyncTime = 0
        self.NextPrimaryFire = 0

        hook.Add('InputMouseApply', 'pointshoot.autoaim', function(cmd, x, y, ang) self:InputMouseApply(cmd, x, y, ang) end)
        hook.Add('Think', 'pointshoot.autoaim', function() self:AutoAim() end)
        hook.Add('PointShootAimFinish', 'pointshoot.autoaim', function(pos, dir) self:AimFinish(pos, dir) end)
    end

    function pointshoot:DisableAim()
        hook.Remove('InputMouseApply', 'pointshoot.autoaim')
        hook.Remove('Think', 'pointshoot.autoaim')
        hook.Remove('PointShootAimFinish', 'pointshoot.autoaim')
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

        local len = #marks
        if not istable(marks) or len < 1 then return end
        
        local start = ply:EyePos()
        local wp = ply:GetActiveWeapon()
        local wpdata = self:WeaponParse(wp)

        if not wpdata then 
            for i = len, math.max(len - count + 1, 1), -1 do
                table.remove(marks, i)
            end
        else
            for i = len, math.max(len - count + 1, 1), -1 do
                local mark = marks[i]
                table.remove(marks, i)

                local endpos = pointshoot:GetMarkPos(mark)
                if endpos then 
                    self.Fire(wp, start, endpos, nil, ply)
                end
            end
        end
    end
end

pointshoot.noscriptedgunsPrimary = {
	['weapon_pistol'] = {
		RPM = 800,
		Damage = 10,
        Force = 1,
        Sound = 'Weapon_Pistol.Single'
	},
	['weapon_357'] = {
		RPM = 300,
		Damage = 60,
        Force = 25,
        Sound = 'Weapon_357.Single',
	},
	['weapon_ar2'] = {
		RPM = 600,
		Damage = 20,
        Force = 1,
        Sound = 'Weapon_AR2.Single',
	},
	['weapon_crossbow'] = {
		RPM = 180,
		Damage = 150,
        Force = 50,
        Sound = 'Weapon_Crossbow.Single',
	},
	['weapon_shotgun'] = {
		RPM = 280,
		Damage = 45,
        Force = 1000,
        Sound = 'Weapon_Shotgun.Single',
        Spread = Vector(0.05, 0.05, 0),
        Num = 8,
	},
	['weapon_smg1'] = {
		RPM = 1000,
		Damage = 6,
        Force = 1,
        Sound = 'Weapon_SMG1.Single',
	},
    ['weapon_crowbar'] = {
        RPM = 999,
        Damage = 0,
        Force = 2000,
        Sound = 'Weapon_Crowbar.Single',
        IsMelee = true,
    },
    ['weapon_stunstick'] = {
        RPM = 999,
        Damage = 0,
        Force = 2000,
        Sound = 'Weapon_Stunstick.Single',
        IsMelee = true,
    },

    ['weapon_frag'] = {
        RPM = 300,
        Damage = 0,
        Force = 500,
        IsGrenade = true,
        ActPrimary = ACT_VM_THROW,
        ActDeploy = ACT_VM_DEPLOY,
    },
}