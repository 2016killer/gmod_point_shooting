--[[
    作者: 白狼
]]

if SERVER then
    concommand.Add('pointshoot_debug_wpdata_sv', function(ply)
        local wp = ply:GetActiveWeapon()
        print(wp:GetClass())
        if not istable(wp.Primary) then return end
        print('------Primary------')
        PrintTable(wp.Primary)
        if not istable(wp.Bullet) then return end
        print('------Bullet------')
        PrintTable(wp.Bullet)
    end)
elseif CLIENT then
    concommand.Add('pointshoot_debug_wpdata_cl', function(ply)
        local wp = ply:GetActiveWeapon()
        print(wp:GetClass())
        if not istable(wp.Primary) then return end
        print('------Primary------')
        PrintTable(wp.Primary)
        if not istable(wp.Bullet) then return end
        print('------Bullet------')
        PrintTable(wp.Bullet)
    end)
end

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

    return wp.Primary
end

pointshoot.Fire = function(self, start, endpos, dir, attacker)
    dir = dir or (endpos - start):GetNormal()
    if CLIENT then
        local vm = attacker:GetViewModel()
        if not IsValid(vm) then return end
        local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
        
        if (seq == -1) then return end
        
        vm:SendViewModelMatchingSequence(seq)
        vm:SetPlaybackRate(1)

        if pointshoot.CVarsCache.ps_rpm_mode then
            pointshoot.NextPrimaryFire = RealTime() + 60 / pointshoot.CVarsCache.ps_rpm_mul / self.Primary.RPM
        else
            pointshoot.NextPrimaryFire = 0
        end
        self:EmitSound(self.Primary.Sound)
    elseif SERVER and not self.Primary.IsMelee then
        local damage = self.Primary.Damage * pointshoot.CVarsCache.ps_damage_mul
        local damagePenetration = self.Primary.Damage * pointshoot.CVarsCache.ps_damage_penetration_mul

        local bulletInfo = {
            Spread = pointshoot.zerovec,
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
        ply:DropWeapon(self, dir, dir * 5000)
    end
end


pointshoot.noscriptedgunsPrimary = {
	['weapon_pistol'] = {
		RPM = 600 * 1.5,
		Damage = 10,
        Force = 1,
        Sound = 'Weapon_Pistol.Single',
	},
	['weapon_357'] = {
		RPM = 300 * 1.5,
		Damage = 60,
        Force = 25,
        Sound = 'Weapon_357.Single',
	},
	['weapon_ar2'] = {
		RPM = 600 * 1.5,
		Damage = 20,
        Force = 1,
        Sound = 'Weapon_AR2.Single',
	},
	['weapon_crossbow'] = {
		RPM = 120 * 1.5,
		Damage = 150,
        Force = 50,
        Sound = 'Weapon_Crossbow.Single',
	},
	['weapon_shotgun'] = {
		RPM = 180 * 1.5,
		Damage = 45,
        Force = 1000,
        Sound = 'Weapon_Shotgun.Single',
        Num = 8,
	},
	['weapon_smg1'] = {
		RPM = 1000 * 1.5,
		Damage = 6,
        Force = 1,
        Sound = 'Weapon_SMG1.Single',
	},
    ['weapon_crowbar'] = {
        RPM = 180 * 1.5,
        Damage = 0,
        Force = 10000,
        Sound = 'Weapon_Crowbar.Single',
        IsMelee = true,
    }
}
