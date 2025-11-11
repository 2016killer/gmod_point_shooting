local target = nil
local duration = 0
local timer = 0
local realTimeMode = true
hook.Add('InputMouseApply', 'pointshoot.autoaim', function(cmd, x, y, ang)
    if not target then 
        return 
    end
    
    timer = timer + (realTimeMode and RealFrameTime() or FrameTime())

    local pos = nil
    if istable(target) then
        local lpos, ent = unpack(target)
        pos = IsValid(ent) and ent:LocalToWorld(lpos) or nil
    else
        pos = target
    end

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

function SWEP:CheckTarget()
    return target
end

function SWEP:AutoAim(pos, ent, duration, timemode)
    if isentity(ent) then
        if IsValid(ent) then
            target = {ent:WorldToLocal(pos), ent}
        else
            return false
        end
    elseif isvector(pos) then
        target = pos
    else
        return false
    end

    duration = duration
    timer = 0
    realTimeMode = timemode or true

    return true
end