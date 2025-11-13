local duration = 0
local alpha = 0
local da = 0 
local startTime = nil
local function DrawFlash(self)
    if not startTime then 
        return 
    end

    local dt = self.drawdt
    if self.drawtime - startTime >= duration then
        startTime = nil
        return
    end

    alpha = math.Clamp(alpha + dt * da, 0, 255)

    surface.SetDrawColor(255, 255, 255, alpha)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end

table.insert(SWEP.DrawHUDs, DrawFlash)

function SWEP:ScreenFlash(startalpha, targetalpha, dura)
    duration = dura
    alpha = startalpha
    da = targetalpha - startalpha / dura
    startTime = self.drawtime
end



