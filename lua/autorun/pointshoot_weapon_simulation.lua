--[[
    作者: 白狼
]]

pointshoot = pointshoot or {}

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
            Force = nil,
            Damage = wp.ps_wpdata.Damage,
            Num = 1,
            Tracer = 0,

            Attacker = ply,
            Inflictor = wp,

            Dir = (endpos - start):GetNormal(),
            Src = start
        }

        wp:FireBullets(bulletInfo)
        bulletInfo.Damage = wp.ps_wpdata.Damage * 1
        bulletInfo.Src = endpos
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

