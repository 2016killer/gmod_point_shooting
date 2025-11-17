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
