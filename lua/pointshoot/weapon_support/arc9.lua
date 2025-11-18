local zerovec = Vector(0, 0, 0)

local function ARC9GetDeployDuration(self, ply) 
    local vm = ply:GetViewModel()
    if not IsValid(vm) then return 0 end

    local seq = vm:SelectWeightedSequence(ACT_VM_DRAW)
    if (seq == -1) then return 0 end

    return math.Clamp(vm:SequenceDuration(seq), 0, 5)
end


local function ARC9GunGetRPM(self)
    return self:GetProcessedValue("RPM") or 999
end


local function ACR9DoEject(self, index, attachment)
    // if !IsFirstTimePredicted() then return end
    local processedValue = self.GetProcessedValue

    -- if self:GetProcessedValue("NoShellEject") then return end

    local eject_qca = attachment or self:GetQCAEject()

    local data = EffectData()
    data:SetEntity(self)
    data:SetAttachment(eject_qca)
    data:SetFlags(index or 0)

    for i = 1, processedValue(self, "ShellEffectCount", true) do
        util.Effect(processedValue(self, "ShellEffect", true) or "ARC9_shelleffect", data, true)
    end
end

local function ARC9GunDoEffects(self)
    // if !IsFirstTimePredicted() then return end
    if self:GetProcessedValue("NoMuzzleEffect", true) then return end

    local muzz_qca = self:GetQCAMuzzle()

    local data = EffectData()
    data:SetEntity(self)
    data:SetAttachment(muzz_qca)
    data:SetSurfaceProp(self:GetNthShot() % 2) -- hopefully nobody uses this on a muzzle effect

    local muzzle = "arc9_muzzleeffect"

    local muzefect = self:GetProcessedValue("MuzzleEffect", true)

    if !self:GetProcessedValue("MuzzleParticle", true) and muzefect then
        muzzle = muzefect
        data:SetScale(1)
        data:SetFlags(0)
        data:SetEntity(self:GetVM())
    end

    util.Effect(muzzle, data, true)

    if IsValid(self.ActiveAfterShotPCF) then
        self.ActiveAfterShotPCF:StopEmission()
    end
end

local function ARC9GunPlayAttackAnim(self, ply)
    if CLIENT then pointshoot:SetRecoil(-5 * math.abs(self.Recoil or 1), 0, 0) end

    self:DoShootSounds()
    // self:DoEffects()
    // self:DoEject()
    ARC9GunDoEffects(self)
    ACR9DoEject(self)
    

    local vm = ply:GetViewModel()
    if not IsValid(vm) then return end
    local seq = vm:SelectWeightedSequence(ACT_VM_PRIMARYATTACK)
    if (seq == -1) then return end

    vm:SendViewModelMatchingSequence(seq)
end

local function ARC9GunDecrClip(self, ply)
    self:SetClip1(math.max(0, self:Clip1() - 1))
end

local function ARC9GunGetClip(self, ply)
    return self:Clip1()
end

local function ARC9GunGetBulletInfo(self, ply, start, endpos, dir)
    local num = math.max(0, self:GetProcessedValue("Num") or 0)
    local isshotgun = num > 1
    local spread = self:GetProcessedValue("Spread") or 0
    spread = isvector(spread) and spread or Vector(spread, spread, 0)
    // print(num, isshotgun, spread)
    
    return {
        Damage = self:GetDamageAtRange((endpos - start):Length()),
        Spread = isshotgun and spread or zerovec,
        Force = self.Force,
        Num = num,
        Tracer = 0
    }
end

pointshoot:RegisterWhiteListBase('arc9_base', {
    GetDeployDuration = ARC9GetDeployDuration,
    GetRPM = ARC9GunGetRPM,
    PlayAttackAnim = ARC9GunPlayAttackAnim,
    GetBulletInfo = ARC9GunGetBulletInfo,
    DecrClip = ARC9GunDecrClip,
    GetClip = ARC9GunGetClip,
})

ARC9GunGetRPM = nil
ARC9GunPlayAttackAnim = nil
ARC9GunGetBulletInfo = nil
ARC9GunDecrClip = nil
ARC9GunGetClip = nil

ARC9GetDeployDuration = nil