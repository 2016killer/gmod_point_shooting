function SWEP:Particle()
    local center = self:GetPos()
    local emitter = ParticleEmitter(center)
    
    for i = 1, 100 do
        local rand = VectorRand()
        local part = emitter:Add('effects/spark', center + (rand - 0.5 * rand) * 500)
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
