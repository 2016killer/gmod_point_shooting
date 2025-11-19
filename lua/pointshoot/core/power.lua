local cvars = {
    {
        name = 'ps_buoyancy',
        default = '0.1',
        call = 'GetFloat',
        widget = 'NumSlider',
        min = 0,
        max = 1,
        decimals = 1,
        help = true
    },

    {
        name = 'ps_headshot_reward',
        default = '0.3',
        call = 'GetFloat',
        widget = 'NumSlider',
        min = 0,
        max = 1,
        decimals = 1,
        help = true
    },

    {
        name = 'ps_power_cost',
        default = '0.1',
        call = 'GetFloat',
        widget = 'NumSlider',
        min = 0,
        max = 1,
        decimals = 1,
    }
}
for _, cvar in ipairs(cvars) do pointshoot:RegisterCVar(cvar) end
if SERVER then 
    cvars = nil 
elseif CLIENT then
    hook.Add('PopulateToolMenu', 'pointshoot.menu.power', function()
        spawnmenu.AddToolMenuOption('Options', 
            language.GetPhrase('#pointsh.category'), 
            'pointshoot.menu.power', 
            language.GetPhrase('#pointsh.menu.power'), '', '', 
            function(panel) pointshoot:CreateCVarsMenu(panel, cvars) end
        )
    end)
end

pointshoot:RegisterClientToServer('CTSDecrPower')

function pointshoot:CTSDecrPower(ply, delta)
    if SERVER then 
        local oldPower = ply:GetNW2Float('psnw_power', 1)
        local newPower = math.Clamp(oldPower - delta, 0, 1)
        if oldPower == newPower then return end
        self.PowerBuoyancyTime = CurTime() + 2
        ply:SetNW2Float('psnw_power', newPower)
    elseif CLIENT then
        return
    end
end

if SERVER then
    local pointshoot = pointshoot
    pointshoot.PowerBuoyancyTime = 0
    hook.Add('PlayerPostThink', 'pointshoot.buoyancy', function(ply)
        local curtime = CurTime()
        if curtime < pointshoot.PowerBuoyancyTime then return end
        pointshoot.PowerBuoyancyTime = curtime + 1

        local oldPower = ply:GetNW2Float('psnw_power', 1)
        local newPower = math.Clamp(oldPower + pointshoot.CVarsCache.ps_buoyancy, 0, 1)
        if oldPower == newPower then return end
        ply:SetNW2Float('psnw_power', newPower)
    end)

    hook.Add('ScaleNPCDamage', 'pointshoot.headshot.reward' , function(npc, hitgroup, dmginfo)
        if hitgroup ~= HITGROUP_HEAD or not IsValid(dmginfo) or dmginfo:GetInflictor().ps_flag then 
            return 
        end

        local attacker = dmginfo:GetAttacker()
        if not IsValid(attacker) or not attacker:IsPlayer() then 
            return 
        end
        
        local oldPower = attacker:GetNW2Float('psnw_power', 1)
        local newPower = math.Clamp(oldPower + pointshoot.CVarsCache.ps_headshot_reward, 0, 1)
        if oldPower == newPower then return end

        attacker:SetNW2Float('psnw_power', newPower)
    end)
elseif CLIENT then 
    local function Elasticity(x)
        if x >= 1 then return 1 end
        return x * 1.4301676 + math.sin(x * 4.0212386) * 0.55866
    end
    
    local ready_mat = Material('hitman/ready.png')
    function pointshoot:DrawReadyEffect(endtime, duration)
        local curtime = CurTime()
        if curtime > endtime then 
            self:RemoveReadyEffect()
            return
        end

        local rate = Elasticity(1 - (endtime - curtime) / duration)
        local scrW, scrH = ScrW(), ScrH()
        local size = 64 * rate
        local alpha = 400 * (1 - rate)
        local x, y = scrW * 0.5, scrH - 128
        surface.SetDrawColor(255, 255, 255, alpha)
        surface.SetMaterial(ready_mat)
        surface.DrawTexturedRectRotated(x, y, size, size, 0)
    end

    function pointshoot:EnableReadyEffect(duration)
        local endtime = CurTime() + duration
        hook.Add('HUDPaint', 'pointshoot.readyeffect', function() self:DrawReadyEffect(endtime, duration) end)
    end

    function pointshoot:RemoveReadyEffect()
        hook.Remove('HUDPaint', 'pointshoot.readyeffect')
    end

    function pointshoot:DrawPowerTick(endtime, duration)
        if CurTime() > endtime then 
            self:RemoveDrawPowerTick()
            return 
        end

        local scrW, scrH = ScrW(), ScrH()
        local w, h = scrW * 0.2, 20
        local x = (scrW - w) * 0.5
        local y = scrH - 3 * h

        local alphaRate = math.Clamp((endtime - CurTime()) / duration, 0, 1)
        local curpower = LocalPlayer():GetNW2Float('psnw_power', 1)

        surface.SetDrawColor(170, 170, 170, 255 * alphaRate)
        surface.DrawOutlinedRect(x, y, w, h)
        surface.SetDrawColor(255, 255, 0, 100 * alphaRate)
        surface.DrawRect(x, y, w * curpower, h)
    end

    function pointshoot:EnableDrawPowerTick(duration)
        local endtime = CurTime() + duration
        hook.Add('HUDPaint', 'pointshoot.drawpower', function() self:DrawPowerTick(endtime, duration) end)
    end

    function pointshoot:RemoveDrawPowerTick()
        hook.Remove('HUDPaint', 'pointshoot.drawpower')
    end

    hook.Add('EntityNetworkedVarChanged', 'pointshoot.power.change', function(ent, name, oldval, newval)
        if ent ~= LocalPlayer() then return end
        if name ~= 'psnw_power' then return end
        pointshoot:EnableDrawPowerTick(1.5)
        // if oldval ~= 1 and newval == 1 then
        //     pointshoot:EnableReadyEffect(1)
        // end
    end)
end