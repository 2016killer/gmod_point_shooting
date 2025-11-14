local target = nil
local realTimeMode = true
local duration = 0
local timer = 0
local wp = nil

local pointshoot = pointshoot
hook.Add('InputMouseApply', 'pointshoot.aim', function(cmd, x, y, ang)
    if not target or not IsValid(wp) then 
        return 
    end
    
    timer = timer + (realTimeMode and RealFrameTime() or FrameTime())

    local pos = pointshoot:GetMarkPos(target)
    if not pos then
        target = nil
        hook.Run('PointShootAimFinish', wp, nil)
        return
    end

    local targetDir = (pos - EyePos()):GetNormal()
    local origin = cmd:GetViewAngles()
    local rate = math.Clamp(timer / duration, 0, 1) 
    
    cmd:SetViewAngles(LerpAngle(rate, origin, targetDir:Angle()))

    if rate == 1 or origin:Forward():Dot(targetDir) > 0.9995 then
        hook.Run('PointShootAimFinish', wp, targetDir)
        target, duration, timer = nil, 0, 0
    end
end)

function pointshoot:Aim(wp, mark, dura, timemode)
    wp = wp
    duration = math.max(dura, 0.01)
    realTimeMode = timemode or true
    timer = 0
    target = mark
end

function pointshoot:MouseListener()
	if SERVER then
		return
	end

    local attackKeyDown = input.IsMouseDown(MOUSE_LEFT)
    
    if not self.attackKey and attackKeyDown then
        self.MouseLeftPress()
    end
    self.attackKey = attackKeyDown

    local attack2KeyDown = input.IsMouseDown(MOUSE_RIGHT)
    if not self.attack2Key and attack2KeyDown then
        self:MouseLeftPress()
    end
    self.attack2Key = attack2KeyDown
	
	return true
end