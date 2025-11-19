function SWEP:ClearPowerCost()
    self.Power = nil
    self.PowerCost = nil
end

function SWEP:PowerThink()
    if not self.Power or not self.PowerCost then
        return
    end

    local dt = self.drawdt or RealFrameTime()
    self.Power = self.Power - math.abs(dt * self.PowerCost)

    if not self.PowerTimeOutEffectLock and self.Power <= self.PowerCost then
        self:PowerTimeOutEffect()
        self.PowerTimeOutEffectLock = true
    end

    return self.Power <= 0 
end


function SWEP:DrawPower()
    if not self.Power or not self.PowerCost then
        return
    end

    local scrW, scrH = ScrW(), ScrH()
    local w, h = scrW * 0.2, 20
    local x = (scrW - w) * 0.5
    local y = scrH - 3 * h


    surface.SetFont('DermaLarge')
	surface.SetTextColor(255, 255, 255)
	surface.SetTextPos(x, y - h - h) 
	surface.DrawText(self.Clip)

	surface.SetDrawColor(170, 170, 170, 255)
	surface.DrawOutlinedRect(x, y, w, h)
    surface.SetDrawColor(255, 255, 0, 100)
    surface.DrawRect(x, y, w * self.Power, h)
end

function SWEP:PowerTimeOutEffect()
    surface.PlaySound('hitman/clock.mp3')
end


table.insert(SWEP.DrawHUDs, SWEP.DrawPower)