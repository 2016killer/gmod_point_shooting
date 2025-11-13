function SWEP:ParticleEffect()   
    if not IsValid(self.emitter) then
        self.emitter = ParticleEmitter(self:GetPos())
    end
    local emitter = self.emitter
    local center = self:GetPos()

    for i = 1, 100 do
        local rand = VectorRand()
        local part = emitter:Add('effects/spark', center + rand * 200)
        local dir = VectorRand()
        local grav =  VectorRand() * 150
        if part then
            part:SetDieTime(0.5)

            part:SetStartAlpha(255)
            part:SetEndAlpha(0) 

            part:SetStartSize(5)
            part:SetEndSize(0)

            part:SetGravity(grav)
            part:SetVelocity(dir * 500)
            part:SetAngles(dir:Angle())
        end
    end
end

function SWEP:ClearParticle()
    if IsValid(self.emitter) then
        self.emitter:Finish()
    end
end

function SWEP:AddBulletTrail(start, endpos, width, len, speed)
    if not IsValid(self.emitter) then
        self.emitter = ParticleEmitter(self:GetPos())
    end
    local dieTime = math.min(10, start:Distance(endpos) / speed)
    local emitter = self.emitter
    local center = self:GetPos()
    local dir = (endpos - start):GetNormal()
 
    local part = emitter:Add('models/props_c17/frostedglass_01a', start)
    if part then
        part:SetDieTime(dieTime)

        part:SetStartAlpha(255)
        part:SetEndAlpha(255) 

        part:SetStartSize(width)
        part:SetEndSize(width)

        part:SetStartLength(len)
        part:SetEndLength(0)

        part:SetVelocity(dir * speed)
        part:SetAngles(dir:Angle())
    end
end
