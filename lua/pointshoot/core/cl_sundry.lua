--[[
    作者: 白狼
]]
    
local cvars = {
    {
        name = 'ps_key_mark',
        default = '107',
        call = 'GetInt',
        widget = 'KeyBinder'
    },

    {
        name = 'ps_key_execute',
        default = '108',
        call = 'GetInt',
        widget = 'KeyBinder'
    },

    {
        name = 'ps_key_cancel',
        default = '12',
        call = 'GetInt',
        widget = 'KeyBinder'
    },

    {
        name = 'ps_hud_change',
        default = '1',
        call = 'GetBool',
        widget = 'CheckBox'
    },

    {
        name = 'ps_hud_full',
        default = '0',
        call = 'GetBool',
        widget = 'CheckBox'
    }
}

for _, cvar in ipairs(cvars) do pointshoot:RegisterClientCVar(cvar) end

hook.Add('PopulateToolMenu', 'pointshoot.menu.sundry', function()
    spawnmenu.AddToolMenuOption('Options', 
        language.GetPhrase('#pointsh.category'), 
        'pointshoot.menu.sundry', 
        language.GetPhrase('#pointsh.menu.sundry'), '', '', 
        function(panel) pointshoot:CreateCVarsMenu(panel, cvars) end
    )
end)

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

    if pointshoot.CVarsCache.ps_hud_change then 
        pointshoot:EnableDrawPowerTick(1.5) 
    end

    if oldval ~= 1 and newval == 1 and pointshoot.CVarsCache.ps_hud_full then 
        pointshoot:EnableDrawPowerTick(1.5) 
    end
end)