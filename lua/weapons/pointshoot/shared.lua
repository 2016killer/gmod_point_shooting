SWEP.Slot = 4
SWEP.SlotPos = 99
SWEP.PrintName = '#pointsh.category'
SWEP.Category = '#legend'
SWEP.Author = 'Zack'

SWEP.ViewModel = 'models/weapons/c_arms_citizen.mdl'
SWEP.WorldModel = 'models/weapons/w_pistol.mdl'
SWEP.Spawnable = true

SWEP.UseHands = false
SWEP.ViewModelFlip = false
SWEP.ViewModelFlip1 = true

SWEP.Primary.ClipSize = 0
SWEP.Primary.DefaultClip = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.PrimaryAttack = function() end
SWEP.SecondaryAttack = function() end

SWEP.DrawAmmo = false
SWEP.IconOverride = 'hitman/pointshoot.jpg'


function SWEP:RegisterServerToClient(funcname)
    if not string.StartWith(funcname, 'STC') then
        ErrorNoHalt(string.format('RegisterServerToClient: funcname must not start with STC, "%s"\n', funcname))
        return false
    end

    local netname = 'PSWP' .. funcname
	if SERVER then
        print('RegisterServerToClient:', netname)
		util.AddNetworkString(netname)
	elseif CLIENT then
		net.Receive(netname, function()
			local data = net.ReadTable(true)

            -- fuck time
            local timername = 'pswp_' .. funcname
            timer.Remove(timername)
            timer.Create(timername, 0, 10, function()
                local wp = LocalPlayer():GetWeapon('pointshoot')
                if not IsValid(wp) then 
                    // print(timername, 'Adjust Delay', 0.05 * game.GetTimeScale())
                    timer.Adjust(timername, 0.05 * game.GetTimeScale())
                    return 
                end
                self[funcname](wp, unpack(data))
                timer.Remove(timername)
            end)
		end)
	end
end

function SWEP:RegisterClientToServer(funcname)
    if not string.StartWith(funcname, 'CTS') then
        ErrorNoHalt(string.format('RegisterClientToServer: funcname must not start with CTS, "%s"\n', funcname))
        return false
    end

    local netname = 'PSWP' .. funcname
	if SERVER then
        print('RegisterClientToServer:', netname)
		util.AddNetworkString(netname)

		net.Receive(netname, function(len, ply)
			local data = net.ReadTable(true)
            local wp = ply:GetWeapon('pointshoot')
            if not IsValid(wp) then return end
			self[funcname](wp, unpack(data))
		end)
	end

    return netname
end

function SWEP:CallDoubleEnd(funcname, ...)
    local iscts = string.StartWith(funcname, 'CTS')
    local isstc = string.StartWith(funcname, 'STC')
  
    if iscts and CLIENT then
        local netname = 'PSWP' .. funcname
        net.Start(netname)
            net.WriteTable({...}, true)
        net.SendToServer()

        return self[funcname](self, ...)
    elseif isstc and SERVER then
        local owner = self:GetOwner()
        if not IsValid(owner) or not owner:IsPlayer() then return end

        local netname = 'PSWP' .. funcname
        net.Start(netname)
            net.WriteTable({...}, true)
        net.Send(owner)

        return self[funcname](self, ...)
    else
        ErrorNoHalt(string.format('CallDoubleEnd: funcname must start with STC or CTS, "%s"\n', funcname))
        return nil
    end
end

SWEP.DrawHUDs = {}

function SWEP:DrawHUD()
    self.drawtime = RealTime()
    self.drawdt = self.drawtime - (self.drawtimelast or self.drawtime)
    self.drawtimelast = self.drawtime

    for _, drawhud in ipairs(self.DrawHUDs) do
        drawhud(self)
    end
end


local function LoadLuaFiles(dirname)
	local path = 'weapons/pointshoot/' .. dirname .. '/'
	local filelist = file.Find(path .. '*.lua', 'LUA')

	for _, filename in pairs(filelist) do
		client = string.StartWith(filename, 'cl_')
		server = string.StartWith(filename, 'sv_')

		if SERVER then
			if not client then
				include(path .. filename)
				print('[PointShootWeapon]: AddFile:' .. filename)
			end

			if not server then
				AddCSLuaFile(path .. filename)
			end
		else
			if client or not server then
				include(path .. filename)
				print('[PointShootWeapon]: AddFile:' .. filename)
			end
		end
	end
end

pointshoot = pointshoot or {}
local pointshoot = pointshoot

AddCSLuaFile()
LoadLuaFiles('core')
LoadLuaFiles('effects')


function SWEP:Deploy()
    // print('fuck you')
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end
    if not self.OriginWeaponClass then return end
    self:CallDoubleEnd('STCStart', self.OriginWeaponClass, self.Power, self.PowerCost)
    return true
end

function SWEP:Holster()
    // print('fuck you')
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() or not self.Marks or #self.Marks < 1 then
        pointshoot:TimeScaleFadeIn(1, nil)
        self:Remove()
        return true
    end
    self:CallDoubleEnd('STCExecute')

    return true
end

function SWEP:IsKeyDown(key)
    if key == 0 then
        return true
    else
        return input.IsKeyDown(key) or input.IsMouseDown(key)
    end
end

function SWEP:Think()
	if SERVER or self.LockThink then return end
    if gui.IsGameUIVisible() then return end

	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then 
		return 
	end

    local markKeyDown = self:IsKeyDown(pointshoot.CVarsCache.ps_key_mark)
    if not self.markKeyDown and markKeyDown then
        if not self.Clip or self.Clip <= 0 then 
            return
        end
        local mark = pointshoot:PackMark(pointshoot:TracePenetration())
        self:CallDoubleEnd('CTSAddMarks', mark)
        self:MarkEffect(mark)
        self.Clip = self.Clip - 1
    end
    self.markKeyDown = markKeyDown


    local executeKeyDown = self:IsKeyDown(pointshoot.CVarsCache.ps_key_execute)
    if executeKeyDown or self:PowerThink() then
        self.LockThink = true
        self:CallDoubleEnd('CTSExecuteRequest', self.Power)
        self:ClearPowerCost()
        return
    end

    local cancelKeyDown = self:IsKeyDown(pointshoot.CVarsCache.ps_key_cancel)
    if cancelKeyDown then
        self.LockThink = true
        self:CallDoubleEnd('CTSCancel', self.Power)
        self:ClearPowerCost()
        return
    end
end