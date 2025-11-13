function SWEP:ParticleEffect()
    local center = self:GetPos()
    local emitter = ParticleEmitter(center)
    
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

    emitter:Finish()
end

function SWEP:EndBulletTrail()
    if IsValid(self.emitter) then
        self.emitter:Finish()
    end
end

function SWEP:AddBulletTrail(start, endpos, width, len, speed, dieTime)
    if not IsValid(self.emitter) then
        self.emitter = ParticleEmitter(self:GetPos())
    end

    local center = self:GetPos()
    local dir = (endpos - start):GetNormal()
 
    local part = emitter:Add('models/props_c17/frostedglass_01a', start)
    if part then
        part:SetDieTime(dieTime or 0.5)

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
