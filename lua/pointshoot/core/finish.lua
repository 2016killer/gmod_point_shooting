pointshoot:RegisterServerToClient('CTSFinish')


function pointshoot:CTSFinish(ply)
    self:FinishEffect(ply)
end

function pointshoot:FinishEffect(ply)
    if SERVER then
        timer.Simple(0.15, function()
            self:TimeScaleFadeIn(1, nil)
        end)
        self:TimeScaleFadeIn(0.1, nil)
    elseif CLIENT then
        return
    end
end