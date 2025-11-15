function SWEP:SetClip(cost)
    self.Clip = tonumber(cost) or 0
end

function SWEP:SetPowerCost(cost)
    self.Power = 1
    self.PowerCost = tonumber(cost) or 0.1
    self.PowerStartTime = RealTime()
    self.PowerTimeOutEffectLock = false
end

function SWEP:ClearPowerCost()
    self.Power = nil
    self.PowerCost = nil
    self.PowerStartTime = nil
end

function SWEP:PowerThink()
    if not self.Power then
        return
    end

    self.Power = Lerp((RealTime() - self.PowerStartTime) * self.PowerCost, 1, 0)

    if not self.PowerTimeOutEffectLock and self.Power <= self.PowerCost then
        self:PowerTimeOutEffect()
        self.PowerTimeOutEffectLock = true
    end

    return self.Power <= 0 
end


function SWEP:DrawPower()
    if not self.Power then
        return
    end

    local scrW, scrH = ScrW(), ScrH()
    local alpha = math.Clamp((RealTime() - self.PowerStartTime) * 0.5, 0, 1)
    local w, h = scrW * 0.2, scrH * 0.05
    local x = (scrW - w) * 0.5
    local y = scrH - 2 * h


    surface.SetFont('DermaLarge')
	surface.SetTextColor(255, 255, 255)
	surface.SetTextPos(x + 0.5 * w - 20, y - 50) 
	surface.DrawText(self.Clip)

	surface.SetDrawColor(170, 170, 170, alpha * 255)
	surface.DrawOutlinedRect(x, y, w, h)
    surface.SetDrawColor(255, 255, 0, alpha * 100)
    surface.DrawRect(x, y, w * self.Power, h)
end

function SWEP:PowerTimeOutEffect()
    surface.PlaySound('hitman/clock.mp3')
end


table.insert(SWEP.DrawHUDs, SWEP.DrawPower)