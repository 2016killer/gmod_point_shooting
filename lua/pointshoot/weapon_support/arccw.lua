local zerovec = Vector(0, 0, 0)

local function ARCCWGetDeployDuration(self, ply) 
    local vm = ply:GetViewModel()
    if not IsValid(vm) then return 0 end

    local seq = vm:SelectWeightedSequence(ACT_VM_DRAW)
    if (seq == -1) then return 0 end

    return math.Clamp(vm:SequenceDuration(seq), 0, 5)
end


local function ARCCWGunGetRPM(self)
    return math.Round(60 / self:GetFiringDelay())
end

local function ARCCWGunPlayAttackAnim(self, ply)
    if CLIENT then pointshoot:SetRecoil(-5 * math.abs(self.Recoil or 1), 0, 0) end

    self:DoShootSound()
    self:DoShellEject()
    self:DoEffects()

    local vm = ply:GetViewModel()
    if not IsValid(vm) then return end
    local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
    if (seq == -1) then return end

    vm:SendViewModelMatchingSequence(seq)
end

local function ARCCWGunDecrClip(self, ply)
    self:SetClip1(math.max(0, self:Clip1() - 1))
end

local function ARCCWGunGetClip(self, ply)
    return self:Clip1()
end

local function ARCCWGunGetBulletInfo(self, ply, start, endpos, dir)
    local isshotgun = self:GetIsShotgun()
    local spread = ArcCW.MOAToAcc * self:GetBuff("AccuracyMOA")
    // print(isshotgun, spread)
    return {
        Damage = self.Damage,
        Spread = isshotgun and Vector(spread, spread, 0) or zerovec,
        Force = self.Force,
        Num = self.Num,
        Tracer = 0
    }
end

pointshoot:RegisterWhiteListBase('arccw_base', {
    GetDeployDuration = ARCCWGetDeployDuration,
    GetRPM = ARCCWGunGetRPM,
    PlayAttackAnim = ARCCWGunPlayAttackAnim,
    GetBulletInfo = ARCCWGunGetBulletInfo,
    DecrClip = ARCCWGunDecrClip,
    GetClip = ARCCWGunGetClip,
})

ARCCWGunGetRPM = nil
ARCCWGunPlayAttackAnim = nil
ARCCWGunGetBulletInfo = nil
ARCCWGunDecrClip = nil
ARCCWGunGetClip = nil

ARCCWGetDeployDuration = nil