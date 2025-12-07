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
end