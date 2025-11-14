function pointshoot:RegisterServerToClient(funcname)
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
		net.Receive(netname, function()
			local data = net.ReadTable(true)
			self[funcname](self, LocalPlayer(), unpack(data))
		end)
	end
end

function pointshoot:RegisterClientToServer(funcname)
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
        net.Send(ply)

        return self[funcname](self, ply, ...)
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
function pointshoot:GetMarkPos(mark)
    local _, lpos, ent, _ = unpack(mark)
    if not isbool(ent) and not IsValid(ent) then
        return nil
    elseif not isbool(ent) then
        return ent:LocalToWorld(lpos)
    else
        return lpos
    end
end

function pointshoot:GetMarkType(mark)
    return mark[1]
end

function pointshoot:GetMarkSize(mark)
    return mark[4]
end

function pointshoot:SetMarkSize(mark, size)
    mark[4] = size
end

function pointshoot:PackMark(tr)
    return {
        tr.HitGroup == HITGROUP_HEAD,
        IsValid(tr.Entity) and tr.Entity:WorldToLocal(tr.HitPos) or tr.HitPos,
        IsValid(tr.Entity) and tr.Entity or false,
        0
    }
end