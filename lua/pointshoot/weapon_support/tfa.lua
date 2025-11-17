local zerovec = Vector(0, 0, 0)

local function TFAMeleeGetClip(self, ply)
    return 1
end

local function TFAMeleeGetBulletInfo(self, ply, start, endpos, dir)
    dir = dir or (endpos - start):GetNormal()

    ply:DropWeapon(self)

    local ent = ents.Create('pointshoot_melee')
    ent:SetPos(start + dir * 100)
    ent:SetAngles(ply:EyeAngles())
    ent:Bind(self)
    ent:Spawn()

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(dir * 2000)
    end 
end


pointshoot:RegisterWhiteListBase('tfa_melee_base', {
    GetRPM = pointshoot.emptyfunc,
    PlayAttackAnim = pointshoot.emptyfunc,
    GetBulletInfo = TFAMeleeGetBulletInfo,
    DecrClip = pointshoot.emptyfunc,
    GetClip = TFAMeleeGetClip,
})

pointshoot:RegisterWhiteListBase('tfa_bash_base', {
    GetRPM = pointshoot.emptyfunc,
    PlayAttackAnim = pointshoot.emptyfunc,
    GetBulletInfo = TFAMeleeGetBulletInfo,
    DecrClip = pointshoot.emptyfunc,
    GetClip = TFAMeleeGetClip,
})

pointshoot:RegisterWhiteListBase('tfa_sword_advanced_base', {
    GetRPM = pointshoot.emptyfunc,
    PlayAttackAnim = pointshoot.emptyfunc,
    GetBulletInfo = TFAMeleeGetBulletInfo,
    DecrClip = pointshoot.emptyfunc,
    GetClip = TFAMeleeGetClip,
})

TFAMeleeGetRPM = nil
TFAMeleePlayAttackAnim = nil
TFAMeleeGetBulletInfo = nil
TFAMeleeDecrClip = nil
TFAMeleeGetClip = nil


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

pointshoot:RegisterWhiteListBase('tfa_gun_base', {
    GetRPM = TFAGunGetRPM,
    PlayAttackAnim = TFAGunPlayAttackAnim,
    GetBulletInfo = TFAGunGetBulletInfo,
    DecrClip = TFAGunDecrClip,
    GetClip = TFAGunGetClip,
})

TFAGunGetRPM = nil
TFAGunPlayAttackAnim = nil
TFAGunGetBulletInfo = nil
TFAGunDecrClip = nil
TFAGunGetClip = nil
