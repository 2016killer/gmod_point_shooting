--[[
    作者: 白狼
]]
pointshoot = pointshoot or {}
pointshoot.emptyfunc = function() end
pointshoot.WhiteList = pointshoot.WhiteList or {}
pointshoot.WhiteListBase = pointshoot.WhiteListBase or {}
pointshoot.Marks = {}
pointshoot.Version = 'Version: beta2'

pointshoot.CVarsCache = {}
pointshoot.CVars = {}


concommand.Add('pointshoot_debug_' .. (SERVER and 'sv' or 'cl'), function(ply)
	PrintTable(pointshoot)
end)

function pointshoot:RegisterServerToClient(funcname)
    if not string.StartWith(funcname, 'STC') then
        ErrorNoHalt(string.format('[PointShoot]: RegisterServerToClient: funcname must not start with STC, "%s"\n', funcname))
        return false
    end

    local netname = 'PointShoot' .. funcname
	if SERVER then
        print('[PointShoot]: RegisterServerToClient:', netname)
		util.AddNetworkString(netname)
	elseif CLIENT then
		net.Receive(netname, function()
			local data = net.ReadTable(true)
			self[funcname](self, LocalPlayer(), unpack(data))
		end)
	end
end

function pointshoot:RegisterClientToServer(funcname)
    if not string.StartWith(funcname, 'CTS') then
        ErrorNoHalt(string.format('[PointShoot]: RegisterClientToServer: funcname must not start with CTS, "%s"\n', funcname))
        return false
    end

    local netname = 'PointShoot' .. funcname
	if SERVER then
        print('[PointShoot]: RegisterClientToServer:', netname)
		util.AddNetworkString(netname)

		net.Receive(netname, function(len, ply)
			local data = net.ReadTable(true)
			self[funcname](self, ply, unpack(data))
		end)
	end

    return netname
end

function pointshoot:CallDoubleEnd(funcname, ply, ...)
    local iscts = string.StartWith(funcname, 'CTS')
    local isstc = string.StartWith(funcname, 'STC')
  
    if iscts and CLIENT then
        local netname = 'PointShoot' .. funcname
        net.Start(netname)
            net.WriteTable({...}, true)
        net.SendToServer()

        return self[funcname](self, ply, ...)
    elseif isstc and SERVER then
        local netname = 'PointShoot' .. funcname
        net.Start(netname)
            net.WriteTable({...}, true)
        net.Send(owner)

        return self[funcname](self, ply, ...)
    else
        ErrorNoHalt(string.format('[PointShoot]: CallDoubleEnd: funcname must start with STC or CTS, "%s"\n', funcname))
        return nil
    end
end


-- ============= 标记数据处理 =============
function pointshoot:GetMarkPos(mark)
    local _, lpos, ent, _ = unpack(mark)
    if ent and not IsValid(ent) then
        return nil
    elseif ent and isvector(lpos) then
        return ent:LocalToWorld(lpos)
    elseif ent and isnumber(lpos) then
        return ent:GetBonePosition(lpos)
    else
        return lpos
    end
end

function pointshoot:GetMarkType(mark) return mark[1] end
function pointshoot:GetMarkSize(mark) return mark[4] end
function pointshoot:SetMarkSize(mark, size) mark[4] = size end

function pointshoot:PackMark(tr)
    local ent = tr.Entity
    if not IsValid(ent) then
       return {
            false,
            tr.HitPos,
            false,
            0
        }
    elseif ent:IsNPC() or ent:IsPlayer() then
        return {
            tr.HitGroup == HITGROUP_HEAD,
            tr.HitBoxBone or 0,
            ent,
            0
        }
    else
        return {
            tr.HitGroup == HITGROUP_HEAD,
            ent:WorldToLocal(tr.HitPos),
            ent,
            0
        }
    end 
end

-- ============= 穿墙标记 =============
function pointshoot:TracePenetration(dis)
    dis = dis or 4000
    local filter = {LocalPlayer()}
    local start = LocalPlayer():EyePos()

    // local dir = LocalPlayer():GetAimVector()
    local dir = (LocalPlayer():EyeAngles() + LocalPlayer():GetViewPunchAngles()):Forward()
    local tr = util.TraceLine({
        start = start,
        endpos = start + dir * dis,
        filter = filter,
        mask = MASK_SHOT
    })

    // debugoverlay.Sphere(tr.HitPos, 5, 5, Color(255, 0, 0))

    if tr.Entity:IsNPC() or tr.Entity:IsPlayer() then
        return tr
    end
    
    table.insert(filter, tr.Entity)
    local tr2 = util.TraceLine({
        start = tr.HitPos - dir * 3,
        endpos = tr.HitPos + 0.25 * (1 - tr.FractionLeftSolid) * dis * dir,
        filter = filter,
        mask = MASK_SHOT,
        ignoreworld = true
    })

    if tr2.Entity:IsNPC() or tr2.Entity:IsPlayer() then
        return tr2
    elseif IsValid(tr.Entity) then
        return tr
    elseif IsValid(tr2.Entity) then
        return tr2
    else
        return tr
    end
end

-- ============= 时间控制 =============
function pointshoot:TimeScaleFadeIn(target, duration)
	if CLIENT then return end
    timer.Remove('pointshoot_timescale')
    if duration == 0 or duration == nil then
        game.SetTimeScale(target)
        return
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
end


function pointshoot:ThinkTimer(identifier, delay, repetitions, func, timemode)
	local gettime = timemode == 'cur' and CurTime or RealTime
	local nexttime = gettime() + delay
	local lastcall = 0
	hook.Add('Think', identifier, function()
		local now = gettime()
		if now < nexttime then return end
		func()

		nexttime = now + delay
		lastcall = lastcall + 1
		if repetitions ~= 0 and lastcall >= repetitions then 
			gettime = nil
			nexttime = nil
			lastcall = nil
			hook.Remove('Think', identifier) 
		end  
	end)
end

function pointshoot:ThinkTimerRemove(identifier)
	hook.Remove('Think', identifier) 
end

function pointshoot:ThinkTimerSimple(delay, func, timemode)
	local identifier = 'pointshoot_thinktimer_simple_' .. math.random(-65536, 65535)
	self:ThinkTimer(identifier, delay, 1, func, timemode)
end


function pointshoot:UpdateCVarCache(data)
	if data ~= nil then
		local name = data.name
		local cvar = GetConVar(name)
		self.CVarsCache[name] = cvar[data.call](cvar)
		print('set cache', name, self.CVarsCache[name])
	else
		for _, v in ipairs(self.CVars) do
			self:UpdateCVarCache(v)
		end
	end
end

if SERVER then util.AddNetworkString('PointShootUpdateCVarCache') end
net.Receive('PointShootUpdateCVarCache', function() 
	pointshoot:UpdateCVarCache()
	if CLIENT then return end
	net.Start('PointShootUpdateCVarCache')
	net.Broadcast()
end)

function pointshoot:RegisterCVar(cvardata)
	CreateConVar(cvardata.name, tostring(cvardata.default), { FCVAR_ARCHIVE, FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE })
	table.insert(self.CVars, cvardata)
    self:UpdateCVarCache(cvardata)
end

function pointshoot:RegisterClientCVar(cvardata)
    CreateClientConVar(cvardata.name, tostring(cvardata.default), true, false, '')
	table.insert(self.CVars, cvardata)
    self:UpdateCVarCache(cvardata)
end


local function GetConVarPhrase(name)
	-- 替换第一个下划线为点号
	local start, ending, phrase = string.find(name, "_", 1)

	if start == nil then
		return name
	else
		return '#' .. name:sub(1, start - 1) .. '.' .. name:sub(ending + 1)
	end
end

function pointshoot:CreateCVarsMenu(panel, cvars)
	for _, v in ipairs(cvars) do
		local name = v.name
		local widget = v.widget or 'NumSlider'
		local default = v.default or '0'
		local label = v.label or GetConVarPhrase(name)

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
        elseif widget == 'KeyBinder' then
			panel:KeyBinder(label, name, nil, nil)
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
		net.Start('PointShootUpdateCVarCache')
		net.SendToServer()
	end

	local defaultButton = panel:Button('#default')
	defaultButton.DoClick = function()
		for _, v in ipairs(cvars) do
			RunConsoleCommand(v.name, v.default)
		end
	end

	panel:ControlHelp(self.Version)
end


local function LoadLuaFiles(dirname)
	local path = 'pointshoot/' .. dirname .. '/'
	local filelist = file.Find(path .. '*.lua', 'LUA')

	for _, filename in pairs(filelist) do
		client = string.StartWith(filename, 'cl_')
		server = string.StartWith(filename, 'sv_')

		if SERVER then
			if not client then
				include(path .. filename)
				print('[PointShoot]: AddFile:' .. filename)
			end

			if not server then
				AddCSLuaFile(path .. filename)
			end
		else
			if client or not server then
				include(path .. filename)
				print('[PointShoot]: AddFile:' .. filename)
			end
		end
	end
end


AddCSLuaFile()
LoadLuaFiles('core')
LoadLuaFiles('effects')
LoadLuaFiles('weapon_support')