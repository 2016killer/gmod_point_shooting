pointshoot = pointshoot or {}
pointshoot.CVarsCache = {}
pointshoot.CVars = {
	{
		name = 'ps_aim_cost',
		default = '0.2',
		widget = 'NumSlider',
		min = 0,
		max = 5,
		decimals = 2,
	},

	{
		name = 'ps_rpm_mode',
		default = '1',
		widget = 'CheckBox',
        help = true,
	},    

    {
		name = 'ps_rpm_mul',
		default = '1.2',
		widget = 'NumSlider',
		min = 0.1,
		max = 5,
		decimals = 1,
	}, 

	{
		name = 'ps_damage_mul',
		default = '1',
		widget = 'NumSlider',
		min = 0,
		max = 5,
		decimals = 1,
	},

	{
		name = 'ps_damage_penetration_mul',
		default = '1',
		widget = 'NumSlider',
		min = 0,
		max = 5,
		decimals = 1,
	},

	{
		name = 'ps_power_cost',
		default = '0.1',
		widget = 'NumSlider',
		min = 0,
		max = 1,
		decimals = 1,
	}

}

if SERVER then
    util.AddNetworkString('PointShootingUpdateCVarCache')
    net.Receive('PointShootingUpdateCVarCache', function(len, ply)
        pointshoot:UpdateCVarCache()
    end)
end

function pointshoot:UpdateCVarCache(fromclient)
    if CLIENT and fromclient then 
        net.Start('PointShootingUpdateCVarCache')
        net.SendToServer()
    end
    for _, v in ipairs(self.CVars) do
        if v.widget == 'CheckBox' then 
            self.CVarsCache[v.name] = GetConVar(v.name):GetBool() 
        elseif v.widget == 'NumSlider' then
            self.CVarsCache[v.name] = GetConVar(v.name):GetFloat()
        elseif v.widget == 'TextEntry' then
            self.CVarsCache[v.name] = GetConVar(v.name):GetString()
        end
    end
    
    PrintTable(pointshoot.CVarsCache)
end



function pointshoot:GetConVarPhrase(name)
	-- 替换第一个下划线为点号
	local start, ending, phrase = string.find(name, "_", 1)

	if start == nil then
		return name
	else
		return '#' .. name:sub(1, start - 1) .. '.' .. name:sub(ending + 1)
	end
end


for _, v in ipairs(pointshoot.CVars) do
    CreateConVar(v.name, v.default, { FCVAR_ARCHIVE, FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE })
end
pointshoot:UpdateCVarCache()

pointshoot.CreateGlobalMenu = function(panel)
	for _, v in ipairs(pointshoot.CVars) do
		local name = v.name
		local widget = v.widget or 'NumSlider'
		local default = v.default or '0'
		local label = v.label or pointshoot:GetConVarPhrase(name)

		if widget == 'NumSlider' then
			panel:NumSlider(
				label, 
				name, 
				v.min or 0, v.max or 1, 
				v.decimals or 2
			)
		elseif widget == 'CheckBox' then
			panel:CheckBox(label, name)
		elseif widget == 'TextEntry' then
			panel:TextEntry(label, name)
		end

		if v.help then
			if isstring(v.help) then
				panel:ControlHelp(v.help)
			else
				panel:ControlHelp(label .. '.' .. 'help')
			end
		end
	end

    local updateButton = panel:Button('#save')
	updateButton.DoClick = function()
        pointshoot:UpdateCVarCache(true)
	end

	local defaultButton = panel:Button('#default')
	defaultButton.DoClick = function()
        for _, v in ipairs(pointshoot.CVars) do
            RunConsoleCommand(v.name, v.default)
        end
	end
end


hook.Add('PopulateToolMenu', 'pointshoot.menu', function()
    spawnmenu.AddToolMenuOption('Options', 
        language.GetPhrase('#pointsh.category'), 
        '#pointsh.menu', 
        'Setting', '', '', 
        pointshoot.CreateGlobalMenu
    )
end)






