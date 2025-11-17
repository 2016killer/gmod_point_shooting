pointshoot = pointshoot or {}
local zerovec = Vector(0, 0, 0)

function pointshoot:WeaponParse(wp)
    if not IsValid(wp) then 
        return false
    end

    -- 原版武器, 查表
    if not wp.Primary then
        wp.Primary = self.noscriptedgunsPrimary[wp:GetClass()]
    end

    if not istable(wp.Primary) then
        return
    end

    -- TFA 武器
    if istable(wp.Bullet) then
        wp.Primary.Damage = istable(wp.Bullet.Damage) and wp.Bullet.Damage[1] or nil
        wp.Primary.Force = wp.Bullet.PhysicsMultiplier
        wp.Primary.IsMelee = false
        wp.Primary.Num = wp.Bullet.NumBullets
        wp.PlayAttackAnim = wp.PlayAttackAnim or pointshoot.TFAPlayAttackAnim
    end

    wp.Primary.Damage = wp.Primary.Damage or 0
    wp.Primary.Force = wp.Primary.Force or 0
    wp.Primary.Num = wp.Primary.Num or 0
    wp.Primary.Sound = wp.Primary.Sound or ''
    wp.Primary.ActPrimary = wp.Primary.ActPrimary or ACT_VM_PRIMARYATTACK
    wp.Primary.ActDeploy = wp.Primary.ActDeploy or ACT_VM_DEPLOY
    wp.Primary.Spread = isvector(wp.Primary.Spread) and wp.Primary.Spread or pointshoot.zerovec
    wp.Primary.Recoil = wp.Primary.Recoil or 1
    wp.MuzzleFlashCustom = wp.MuzzleFlashCustom or pointshoot.emptyfunc
    wp.MakeShell = wp.MakeShell or pointshoot.emptyfunc
    wp.MuzzleSmoke = wp.MuzzleSmoke or pointshoot.emptyfunc
    wp.PlayAttackAnim = wp.PlayAttackAnim or pointshoot.PlayAttackAnim

    return wp.Primary
end


local function TFAGunGetRPM(self)
    return self.Primary.RPM
end

local function TFAGunPlayAttackAnim(self, ply)
    self:MuzzleFlashCustom()
    self:MakeShell()
    self:MuzzleSmoke()
    self:EmitSound(self.Primary.Sound or '')
    pointshoot:SetRecoil(-5 * math.abs(self.Primary.Recoil or 1), 0, 0)

    local vm = ply:GetViewModel()
    if not IsValid(vm) then return end
    local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
    if (seq == -1) then return end
    vm:SendViewModelMatchingSequence(seq)
    vm:SetPlaybackRate(1)
end

local function TFAGunDecrClip(self, ply)
    self:SetClip1(math.max(0, self:Clip1() - 1))
end

local function TFAGunGetClip(self, ply)
    return self:Clip1()
end

local function TFAGunGetBulletInfo(self, ply, start, endpos, dir)
    return {
        Damage = self.Primary.Damage,
        Spread = isvector(self.Primary.Spread) and self.Primary.Spread or Vector(self.Primary.Spread, self.Primary.Spread, 0),
        Force = self.Primary.Force,
        Num = self.Primary.Num,
        Tracer = 0
    }
end


pointshoot.WhiteListBase['tfa_gun_base'] = pointshoot.WhiteListBase['tfa_gun_base'] or {
    GetRPM = TFAGunGetRPM,
    PlayAttackAnim = TFAGunPlayAttackAnim,
    GetBulletInfo = TFAGunGetBulletInfo,
    DecrClip = TFAGunDecrClip,
    GetClip = TFAGunGetClip,
}

TFAGunGetRPM = nil
TFAGunPlayAttackAnim = nil
TFAGunGetBulletInfo = nil
TFAGunDecrClip = nil
TFAGunGetClip = nil
