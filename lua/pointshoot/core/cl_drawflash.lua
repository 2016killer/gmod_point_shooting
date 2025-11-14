local startAlpha, targetAlpha = 0, 0
local duration, startTime = 0, 0
function pointshoot:DrawFlash()
    if not startTime then 
        return 
    end

    local dt = self.drawtime - startTime
    if dt >= duration then
        startTime = nil
        return
    end

    surface.SetDrawColor(255, 255, 255, Lerp(dt / duration, startAlpha, targetAlpha))
    surface.DrawRect(0, 0, ScrW(), ScrH())
end

function pointshoot:ScreenFlash(startalpha, targetalpha, dura)
    startAlpha = startalpha
    targetAlpha = targetalpha
    duration = dura
    startTime = RealTime()
end



