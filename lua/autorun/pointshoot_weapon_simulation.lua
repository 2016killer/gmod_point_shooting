--[[
    作者: 白狼
]]

pointshoot = pointshoot or {}
pointshoot.zerovec = Vector(0, 0, 0)


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

pointshoot.DefaultFire = function(self, start, endpos, dir, attacker)
    dir = dir or (endpos - start):GetNormal()
    if CLIENT then
        local vm = attacker:GetViewModel()
        if not IsValid(vm) then return end
        local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
        
        if (seq == -1) then return end
        
        vm:SendViewModelMatchingSequence(seq)
        vm:SetPlaybackRate(1)

        self:EmitSound(self.ps_wpdata.Sound)
        
        if pointshoot.CVarsCache.ps_rpm_mode then
            self:SetNextPrimaryFire(RealTime() + 60 / pointshoot.CVarsCache.ps_rpm_mul / self.ps_wpdata.RPM)
        else
            self:SetNextPrimaryFire(0) 
        end

    elseif SERVER then
        local damage = self.ps_wpdata.Damage * pointshoot.CVarsCache.ps_damage_mul
        local damagePenetration = self.ps_wpdata.Damage * pointshoot.CVarsCache.ps_damage_penetration_mul

        local bulletInfo = {
            Spread = pointshoot.zerovec,
            Force = self.ps_wpdata.Force,
            Num = self.ps_wpdata.Num,
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
    end
end

pointshoot.MeleeFire = function(self, start, endpos, dir, attacker)
    dir = dir or (endpos - start):GetNormal()
    if CLIENT then

    elseif SERVER then
        ply:DropWeapon(self, dir, dir * 5000)
    end
end

pointshoot.TFAFire = function(self, start, endpos, dir, attacker)
    dir = dir or (endpos - start):GetNormal()
    if CLIENT then
        self:SetNextPrimaryFire(0)
        self:PrimaryAttack()
        if pointshoot.CVarsCache.ps_rpm_mode then
            self:SetNextPrimaryFire(RealTime() + 60 / pointshoot.CVarsCache.ps_rpm_mul / self.Primary.RPM)
        else
            self:SetNextPrimaryFire(0)
        end
        self:EmitSound(self.Primary.Sound)
    elseif SERVER then
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
    end
end


pointshoot.noscriptedguns = {
	['weapon_pistol'] = {
		RPM = 600 * 1.5,
		Damage = 10,
        Force = 1,
        Sound = 'Weapon_Pistol.Single',
        FireHandle = pointshoot.DefaultFire,
        SoundClear = pointshoot.DefaultSoundClear,
	},
	['weapon_357'] = {
		RPM = 300 * 1.5,
		Damage = 60,
        Force = 25,
        Sound = 'Weapon_357.Single',
        FireHandle = pointshoot.DefaultFire,
	},
	['weapon_ar2'] = {
		RPM = 600 * 1.5,
		Damage = 20,
        Force = 1,
        Sound = 'Weapon_AR2.Single',
        FireHandle = pointshoot.DefaultFire,
	},
	['weapon_crossbow'] = {
		RPM = 120 * 1.5,
		Damage = 150,
        Force = 50,
        Sound = 'Weapon_Crossbow.Single',
        FireHandle = pointshoot.DefaultFire,
	},
	['weapon_shotgun'] = {
		RPM = 180 * 1.5,
		Damage = 45,
        Force = 1000,
        Sound = 'Weapon_Shotgun.Single',
        FireHandle = pointshoot.DefaultFire,
        Num = 8,
	},
	['weapon_smg1'] = {
		RPM = 1000 * 1.5,
		Damage = 6,
        Force = 1,
        Sound = 'Weapon_SMG1.Single',
        FireHandle = pointshoot.DefaultFire,
	},
    ['weapon_crowbar'] = {
        RPM = 180 * 1.5,
        Damage = 0,
        Force = 10000,
        Sound = 'Weapon_Crowbar.Single',
        FireHandle = pointshoot.MeleeFire,
        IsMelee = true,
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
        
        if not pointshoot.CVarsCache.ps_inf_power then
            newwp:CallOnClient('SetPowerCost', pointshoot.CVarsCache.ps_power_cost)
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

