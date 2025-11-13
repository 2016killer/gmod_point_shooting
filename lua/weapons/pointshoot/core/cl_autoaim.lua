local target = nil
local realTimeMode = true
local duration = 0
local timer = 0
local SWEP = SWEP
local wp = nil
hook.Add('InputMouseApply', 'pointshoot.autoaim', function(cmd, x, y, ang)
    if not target or not IsValid(wp) then 
        return 
    end
    
    timer = timer + (realTimeMode and RealFrameTime() or FrameTime())

    local pos = SWEP:GetMarkPos(target)
    if not pos then
        target = nil
        hook.Run('PointShootAutoAimFinish', wp, nil)
        return
    end

    local targetDir = (pos - EyePos()):GetNormal()
    local origin = cmd:GetViewAngles()
    local rate = math.Clamp(timer / duration, 0, 1) 
    
    cmd:SetViewAngles(LerpAngle(rate, origin, targetDir:Angle()))

    if rate == 1 or origin:Forward():Dot(targetDir) > 0.9995 then
        hook.Run('PointShootAutoAimFinish', wp, targetDir)
        target, duration, timer = nil, 0, 0
    end
end)

function SWEP:AutoAim(mark, dura, timemode)
    wp = self
    duration = math.max(dura, 0.01)
    realTimeMode = timemode or true
    timer = 0
    target = mark
end