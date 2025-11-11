local timecheck = 0
local timer = 0
local duration = 0
local enable = false
local alpha = 0
local da = 0 
local SWEP = SWEP
hook.Add('HUDPaint', 'pointshoot.screenflash', function()
    if not enable then return end
    local curtime = CurTime()
    if timecheck == curtime then return end
    timecheck = curtime

    local dt = RealFrameTime()
    timer = timer + dt

    if timer >= duration then
        enable = false
        return
    end

    alpha = alpha + dt * da

    surface.SetDrawColor(255, 255, 255, alpha)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end)

function SWEP:ScreenFlash(startalpha, targetalpha, dura)
    alpha = startalpha
    da = targetalpha - startalpha / dura
    timer = 0
    duration = dura
    enable = true
end



