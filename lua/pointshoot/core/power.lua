if SERVER then
    local checktime = 0
    local pointshoot = pointshoot
    hook.Add('PlayerPostThink', 'pointshoot.buoyancy', function(ply)
        local curtime = CurTime()
        if curtime < checktime then return end
        checktime = curtime + 1

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
    function pointshoot:DrawReadyEffect(hookname, endtime, duration)
        local curtime = CurTime()
        if curtime > endtime then 
            hook.Remove('HUDPaint', hookname)
        end
        local rate = Elasticity(1 - (endtime - curtime) / duration)
        local scrW, scrH = ScrW(), ScrH()
        local size = 128 * rate
        local alpha = 400 * (1 - rate)
        local x, y = scrW * 0.5, scrH - 128
        surface.SetDrawColor(255, 255, 255, alpha)
        surface.SetMaterial(ready_mat)
        surface.DrawTexturedRectRotated(x, y, size, size, 0)
    end

    function pointshoot:ReadyEffect(hookname, duration)
        local endtime = CurTime() + duration
        hook.Add('HUDPaint', hookname, function() self:DrawReadyEffect(hookname, endtime, duration) end)
    end



    hook.Add('EntityNetworkedVarChanged', 'pointshoot.power.change', function(ent, name, oldval, newval)
        if ent ~= LocalPlayer() then return end
        if name ~= 'psnw_power' then return end
        if oldval ~= 1 and newval == 1 then
            pointshoot:ReadyEffect('pointshoot.readyeffect', 1)
        end
    end)
end