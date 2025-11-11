util.AddNetworkString('PointShootTimeScaleFadeIn')

if SERVER then
    net.Receive('PointShootTimeScaleFadeIn', function(len, ply)
        local target = net.ReadFloat()
        local duration = net.ReadFloat()

        SWEP:TimeScaleFadeIn(target, duration)
    end)
end

function SWEP:TimeScaleFadeIn(target, duration)
    if SERVER then 
        if timer.Exists('pointshoot_timescale') then
            timer.Remove('pointshoot_timescale')
        end

        local StartTime = CurTime()
        local StartScale = game.GetTimeScale()
        timer.Create('pointshoot_timescale', 0, 0, function()
            local dt = CurTime() - StartTime

            if dt >= duration then
                timer.Remove('pointshoot_timescale')
                game.SetTimeScale(target)
            else
                game.SetTimeScale(
                    Lerp(
                        math.Clamp(dt / duration, 0, 1), 
                        StartScale,
                        target
                    )
                )
            end
        end)
    elseif CLIENT then
        net.Start('PointShootTimeScaleFadeIn')
            net.WriteFloat(target)
            net.WriteFloat(duration)
        net.SendToServer()
    end
end