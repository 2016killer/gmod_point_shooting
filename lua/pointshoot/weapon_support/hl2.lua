local function GunGetRPM(self) 
    return self.ps_wppdata.RPM 
end

local function GunPlayAttackAnim(self, ply)
    self:EmitSound(self.ps_wppdata.Sound or '')
    pointshoot:SetRecoil(-5 * math.abs(self.ps_wppdata.Recoil), 0, 0)

    local vm = ply:GetViewModel()
    if not IsValid(vm) then return end
    local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
    if (seq == -1) then return end
    vm:SendViewModelMatchingSequence(seq)
    vm:SetPlaybackRate(1)
end

local function GunGetBulletInfo(self, ply, start, endpos, dir)
    return {
        Damage = self.ps_wppdata.Damage,
        Spread = self.ps_wppdata.Spread,
        Force = self.ps_wppdata.Force,
        Num = self.ps_wppdata.Num,
        Tracer = 0,
        Dir = (endpos - start):GetNormal(),
    }
end

local function GunGetClip(self, _) return self:Clip1() end
local function GunDecrClip(self, _) self:SetClip1(math.max(0, self:Clip1() - 1)) end

pointshoot:RegisterWhiteList('weapon_pistol', {
    RPM = 800,
    Damage = 10,
    Force = 1,
    Sound = 'Weapon_Pistol.Single',
    Recoil = 0.5,

    GetRPM = GunGetRPM,
    PlayAttackAnim = GunPlayAttackAnim,
    GetBulletInfo = GunGetBulletInfo,
    DecrClip = GunDecrClip,
    GetClip = GunGetClip,
})

pointshoot:RegisterWhiteList('weapon_357', {
    RPM = 300,
    Damage = 60,
    Force = 25,
    Sound = 'Weapon_357.Single',
    Recoil = 2,

    GetRPM = GunGetRPM,
    PlayAttackAnim = GunPlayAttackAnim,
    GetBulletInfo = GunGetBulletInfo,
    DecrClip = GunDecrClip,
    GetClip = GunGetClip,
})

pointshoot:RegisterWhiteList('weapon_ar2', {
    RPM = 600,
    Damage = 20,
    Force = 1,
    Sound = 'Weapon_AR2.Single',
    Recoil = 1,

    GetRPM = GunGetRPM,
    PlayAttackAnim = GunPlayAttackAnim,
    GetBulletInfo = GunGetBulletInfo,
    DecrClip = GunDecrClip,
    GetClip = GunGetClip,
})

pointshoot:RegisterWhiteList('weapon_crossbow', {
    RPM = 180,
    Damage = 150,
    Force = 50,
    Sound = 'Weapon_Crossbow.Single',
    Recoil = 5,

    GetRPM = GunGetRPM,
    PlayAttackAnim = GunPlayAttackAnim,
    GetBulletInfo = GunGetBulletInfo,
    DecrClip = GunDecrClip,
    GetClip = GunGetClip,
})

pointshoot:RegisterWhiteList('weapon_shotgun', {
    RPM = 280,
    Damage = 45,
    Force = 50,
    Sound = 'Weapon_Shotgun.Single',
    Spread = Vector(0.05, 0.05, 0),
    Num = 8,
    Recoil = 3,

    GetRPM = GunGetRPM,
    PlayAttackAnim = GunPlayAttackAnim,
    GetBulletInfo = GunGetBulletInfo,
    DecrClip = GunDecrClip,
    GetClip = GunGetClip,
})

pointshoot:RegisterWhiteList('weapon_smg1', {
    RPM = 1000,
    Damage = 6,
    Force = 1,
    Sound = 'Weapon_SMG1.Single',
    Recoil = 0.5,

    GetRPM = GunGetRPM,
    PlayAttackAnim = GunPlayAttackAnim,
    GetBulletInfo = GunGetBulletInfo,
    DecrClip = GunDecrClip,
    GetClip = GunGetClip,
})

GunGetRPM = nil
GunPlayAttackAnim = nil
GunGetBulletInfo = nil
GunGetClip = nil
GunDecrClip = nil


local function MeleeGetClip(self, ply)
    return 1
end

local function MeleeFireOverride(self, ply, start, endpos, dir)
    dir = dir or (endpos - start):GetNormal()

    ply:DropWeapon(self)

    local ent = ents.Create('pointshoot_melee')
    ent:SetPos(start + dir * 100)
    ent:SetAngles(ply:EyeAngles())
    ent:Bind(self)
    ent:Spawn()

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(dir * self.ps_wppdata.Force)
    end
end

pointshoot:RegisterWhiteList('weapon_crowbar', {
    Force = 2000,
    Sound = 'Weapon_Crowbar.Single',

    GetRPM = pointshoot.emptyfunc,
    PlayAttackAnim = pointshoot.emptyfunc,
    GetBulletInfo = MeleeFireOverride,
    DecrClip = pointshoot.emptyfunc,
    GetClip = MeleeGetClip,
})

pointshoot:RegisterWhiteList('weapon_stunstick', {
    Force = 2000,
    Sound = 'Weapon_Stunstick.Single',

    GetRPM = pointshoot.emptyfunc,
    PlayAttackAnim = pointshoot.emptyfunc,
    GetBulletInfo = MeleeFireOverride,
    DecrClip = pointshoot.emptyfunc,
    GetClip = MeleeGetClip
})

MeleeFireOverride = nil
MeleeGetClip = nil


local function GrenadePlayAttackAnim(self, ply)
    local vm = ply:GetViewModel()
    if not IsValid(vm) then return end
    local seq = vm:SelectWeightedSequence(ACT_VM_THROW)
    if (seq == -1) then return end
    vm:SendViewModelMatchingSequence(seq)
    vm:SetPlaybackRate(1)
end

local function GrenadeGetClip(self, ply)
    return ply:GetAmmoCount(self:GetPrimaryAmmoType() or 10)
end

local function GrenadeDecrClip(self, ply)
    local Type = self:GetPrimaryAmmoType() or 10
    local curAmmo = ply:GetAmmoCount(Type)
    ply:SetAmmo(math.max(0, curAmmo - 1), Type)
end

local function GrenadeFireOverride(self, ply, start, endpos, dir)
    dir = dir or (endpos - start):GetNormal()
    local grenade = ents.Create('npc_grenade_frag')
    grenade:SetPos(start + dir * 20)
    grenade:SetAngles(ply:EyeAngles())
    grenade:SetSaveValue('m_hThrower', ply)
    grenade:Spawn()

    grenade:Fire('SetTimer', self.ps_wppdata.Delay, 0)

    local phys = grenade:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(dir * self.ps_wppdata.Force)
    end  
end

local function GrenadeGetRPM(self)
    return self.ps_wppdata.RPM
end

pointshoot:RegisterWhiteList('weapon_frag', {
    RPM = 600,
    Force = 2000,
    Delay = 0.5,

    GetRPM = GrenadeGetRPM,
    PlayAttackAnim = GrenadePlayAttackAnim,
    GetBulletInfo = GrenadeFireOverride,
    DecrClip = GrenadeDecrClip,
    GetClip = GrenadeGetClip
})

GrenadeGetRPM = nil
GrenadePlayAttackAnim = nil
GrenadeFireOverride = nil
GrenadeDecrClip = nil
GrenadeGetClip = nil
