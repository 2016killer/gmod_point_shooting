local target = nil
local realTimeMode = true
local duration = 0
local timer = 0

hook.Add('InputMouseApply', 'pointshoot.autoaim', function(cmd, x, y, ang)
    if not target then 
        return 
    end
    
    timer = timer + (realTimeMode and RealFrameTime() or FrameTime())

    local pos = self:GetMarkPos(target)
    if not pos then
        target = nil
        return
    end

    local targetDir = (pos - EyePos()):Angle()
    local origin = cmd:GetViewAngles()
    local rate = math.Clamp(timer / duration, 0, 1) 
    
    cmd:SetViewAngles(LerpAngle(rate, origin, targetDir))

    if rate == 1 then
        target, duration, timer = nil, 0, 0
    end
end)

function SWEP:AimIdle()
    return !target
end

function SWEP:AimClear()
    duration = 0
    realTimeMode = true
    timer = 0
    target = nil
end

function SWEP:AutoAim(mark, dura, timemode)
    duration = math.max(dura, 0.01)
    realTimeMode = timemode or true
    timer = 0
    target = mark
end