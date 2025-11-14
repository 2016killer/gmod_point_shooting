function pointshoot:ParticleEffect()   
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

function pointshoot:ClearParticle()
    if IsValid(self.emitter) then
        self.emitter:Finish()
    end
end

