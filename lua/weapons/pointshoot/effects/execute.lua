function SWEP:ExecuteEffect()
    if SERVER then
        pointshoot:TimeScaleFadeIn(0.3, nil)
    elseif CLIENT then
        surface.PlaySound('hitman/execute.mp3')
    end
end