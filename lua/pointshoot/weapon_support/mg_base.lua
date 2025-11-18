local pointshoot = pointshoot
local zerovec = Vector(0, 0, 0)

local function MWBGetDeployDuration(self, ply) 
    return self:GetAnimLength('Draw')
end

local function MWBGunGetRPM(self)
    return self.Primary.RPM
end

local function MWBGunPlayAttackAnim(self, ply)
    if CLIENT then 
        pointshoot:SetRecoil(-5 * math.abs(self.Primary.Recoil or 1), 0, 0)
    end
    if not IsValid(self:GetViewModel()) then return end 
    self:GetViewModel():PlayAnimation('Fire', true) -- fuck you
    self:SetNextPrimaryFire(0)
    self:EmitSound(self.Primary.Sound or '')
end

local function MWBGunDecrClip(self, ply)
    self:SetClip1(math.max(0, self:Clip1() - 1))
end

local function MWBGunGetClip(self, ply)
    return self:Clip1()
end

local function MWBGunGetBulletInfo(self, ply, start, endpos, dir)
    if not self.Bullet then return end

    return {
        Damage = istable(self.Bullet.Damage) and self.Bullet.Damage[1] or nil,
        Spread = self.Primary.Spread or zerovec,
        Force = self.Bullet.PhysicsMultiplier,
        Num = self.Bullet.NumBullets,
        Tracer = 0
    }
end


pointshoot:RegisterWhiteListBase('mg_base', {
    Modify = MWBModify,
    GetDeployDuration = MWBGetDeployDuration,
    GetRPM = MWBGunGetRPM,
    PlayAttackAnim = MWBGunPlayAttackAnim,
    GetBulletInfo = MWBGunGetBulletInfo,
    DecrClip = MWBGunDecrClip,
    GetClip = MWBGunGetClip,
})

MWBGunGetRPM = nil
MWBGunPlayAttackAnim = nil
MWBGunGetBulletInfo = nil
MWBGunDecrClip = nil
MWBGunGetClip = nil

MWBGetDeployDuration = nil