function SWEP:RegisterServerToClient(funcname)
    if not string.StartWith(funcname, 'STC') then
        ErrorNoHalt(
            string.format(
                'RegisterServerToClient: funcname must not start with STC, "%s"\n', 
                funcname
            )
        )
        return false
    end

    local netname = 'PointShoot' .. funcname
	if SERVER then
        print('RegisterServerToClient:', netname)
		util.AddNetworkString(netname)
	elseif CLIENT then
		net.Receive(netname, function(len, ply)
			local data = net.ReadTable(true)
			local wp = LocalPlayer():GetWeapon('pointshoot')
			if not IsValid(wp) then
				return
			end
			self[funcname](wp, unpack(data))
		end)
	end
end

function SWEP:RegisterClientToServer(funcname)
    if not string.StartWith(funcname, 'CTS') then
        ErrorNoHalt(
            string.format(
                'RegisterClientToServer: funcname must not start with CTS, "%s"\n', 
                funcname
            )
        )
        return false
    end

    local netname = 'pointShoot' .. funcname
	if SERVER then
        print('RegisterClientToServer:', netname)
		util.AddNetworkString(netname)

		net.Receive(netname, function(len, ply)
			local data = net.ReadTable(true)
			local wp = ply:GetWeapon('pointshoot')
			if not IsValid(wp) then
				return
			end
			self[funcname](wp, unpack(data))
		end)
	end

    return netname
end

function SWEP:CallDoubleEnd(funcname, ...)
    local iscts = string.StartWith(funcname, 'CTS')
    local isstc = string.StartWith(funcname, 'STC')
    local Base = self:GetTable()
    if iscts and CLIENT then
        local netname = 'PointShoot' .. funcname
        net.Start(netname)
            net.WriteTable({...}, true)
        net.SendToServer()

        return Base[funcname](self, ...)
    elseif isstc and SERVER then
        local netname = 'PointShoot' .. funcname
        local owner = self:GetOwner()
        if not IsValid(owner) or not owner:IsPlayer() then
            return
        end

        net.Start(netname)
            net.WriteTable({...}, true)
        net.Send(owner)

        return Base[funcname](self, ...)
    else
        ErrorNoHalt(
            string.format(
                'CallDoubleEnd: funcname must start with STC or CTS, "%s"\n',
                funcname
            )
        )
        return nil
    end
end
--[[
    mark = {
        ishead,
        lpos,
        ent,
        size
    }
]]
function SWEP:GetMarkPos(mark)
    local _, lpos, ent, _ = unpack(mark)
    if not isbool(ent) and not IsValid(ent) then
        return nil
    elseif not isbool(ent) then
        return ent:LocalToWorld(lpos)
    else
        return lpos
    end
end

function SWEP:GetMarkType(mark)
    return mark[1]
end

function SWEP:GetMarkSize(mark)
    return mark[4]
end

function SWEP:SetMarkSize(mark, size)
    mark[4] = size
end

function SWEP:PackMark(tr)
    return {
        tr.HitGroup == HITGROUP_HEAD,
        IsValid(tr.Entity) and tr.Entity:WorldToLocal(tr.HitPos) or tr.HitPos,
        IsValid(tr.Entity) and tr.Entity or false,
        0
    }
end

local function SetDrawTime(self)
    self.drawtime = RealTime()
    self.drawdt = self.drawtime - (self.drawtimelast or self.drawtime)
    self.drawtimelast = self.drawtime
end
SWEP.DrawHUDs = {SetDrawTime}

function SWEP:DrawHUD()
    for _, func in pairs(self.DrawHUDs) do
        func(self)
    end
end