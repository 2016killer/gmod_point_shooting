local zerovec = Vector(0, 0, 0)

local function CW2GetDeployDuration(self, ply) 
    local vm = ply:GetViewModel()
    if not IsValid(vm) then return 0 end

    local seq = vm:SelectWeightedSequence(ACT_VM_DRAW)
    if (seq == -1) then return 0 end

    return math.Clamp(vm:SequenceDuration(seq) * 0.5, 0, 5)
end

local function CW2GunGetRPM(self)
    return 60 / (self.FireDelay or 0.1)
end

local function CW2GunPlayAttackAnim(self, ply)
    if CLIENT then pointshoot:SetRecoil(-5 * math.abs(self.Recoil or 1), 0, 0) end

    self:EmitSound(self:getFireSound() or '')
    self:sendWeaponAnim('fire', self.FireAnimSpeed)
    self:makeFireEffects()
end

local function CW2GunDecrClip(self, ply)
    self:SetClip1(math.max(0, self:Clip1() - 1))
end

local function CW2GunGetClip(self, ply)
    return self:Clip1()
end

local function CW2GunGetBulletInfo(self, ply, start, endpos, dir)
    return {
        Damage = self.Damage,
        Spread = zerovec,
        Force = 1,
        Num = 1,
        Tracer = 0
    }
end

pointshoot:RegisterWhiteListBase('cw_base', {
    GetDeployDuration = CW2GetDeployDuration,
    GetRPM = CW2GunGetRPM,
    PlayAttackAnim = CW2GunPlayAttackAnim,
    GetBulletInfo = CW2GunGetBulletInfo,
    DecrClip = CW2GunDecrClip,
    GetClip = CW2GunGetClip,
})

CW2GunGetRPM = nil
CW2GunPlayAttackAnim = nil
CW2GunGetBulletInfo = nil
CW2GunDecrClip = nil
CW2GunGetClip = nil

CW2GetDeployDuration = nil