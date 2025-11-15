--[[
    作者: 白狼
]]

pointshoot = pointshoot or {}
pointshoot.Marks = {}
pointshoot.OriginWeaponClass = SERVER and {} or nil
local pointshoot = pointshoot

-- ============= 时间控制 =============
function pointshoot:TimeScaleFadeIn(target, duration)
	if CLIENT then return end
    if timer.Exists('pointshoot_timescale') then
        timer.Remove('pointshoot_timescale')
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

-- ============= 穿墙 =============
function pointshoot:TracePenetration(dis)
    dis = dis or 4000
    local filter = {LocalPlayer()}
    local start = EyePos()

    local dir = LocalPlayer():GetAimVector()
    local tr = util.TraceLine({
        start = start,
        endpos = start + dir * dis,
        filter = filter,
        mask = MASK_SHOT
    })

    if tr.Entity:IsNPC() or tr.Entity:IsPlayer() then
        return tr
    end
    
    table.insert(filter, tr.Entity)
    local tr2 = util.TraceLine({
        start = tr.HitPos - dir * 3,
        endpos = tr.HitPos + (1 - tr.FractionLeftSolid) * dis * dir,
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

-- ============= 执行请求处理 =============
function pointshoot:ExecuteEffect(ply)
    if SERVER then
        game.SetTimeScale(0.3)
    elseif CLIENT then
        surface.PlaySound('hitman/execute.mp3')
    end
end

if SERVER then
    util.AddNetworkString('PointShootExecute')
elseif CLIENT then
    net.Receive('PointShootExecute', function()
        pointshoot:Execute()
    end)
end

function pointshoot:Execute(ply, marks)
    if SERVER then
        ply:SelectWeapon(self:GetOriginWeapon(ply))
        if not self.Marks[ply:EntIndex()] or #self.Marks[ply:EntIndex()] < 1 then 
            game.SetTimeScale(1)
            return 
        end

        net.Start('PointShootExecute')
        net.Send(ply)
    elseif CLIENT then
        if #self.Marks < 0 then return end
        local wp = self:GetOriginWeapon(LocalPlayer())
        if not IsValid(wp) then return end
        wp:SetNextPrimaryFire(0)

        self.aiming = false
        self.shootCount = 0
        self.fireSyncTime = RealTime()

        hook.Add('Think', 'pointshoot.autoaim', function()
            self:AutoAim()
        end)
    end
    self:ExecuteEffect(ply)
    // PrintTable(self.Marks)
end


function pointshoot:FinishEffect(ply)
    if SERVER then
        timer.Remove('pointshoot_timescale')
        timer.Simple(0.1, function()
            game.SetTimeScale(1) 
        end)
        game.SetTimeScale(0.1)
    elseif CLIENT then
        return
    end
end

-- ============= 鼠标控制 =============
function pointshoot:GetOriginWeapon(ply)
    if SERVER then
        local idx = ply:EntIndex()
        local class = self.OriginWeaponClass[idx] or ''
        local wp = ply:GetWeapon(class)

        if IsValid(wp) then
            return wp, class
        else
            return nil
        end
    elseif CLIENT then
        local class = self.OriginWeaponClass or ''
        local wp = ply:GetWeapon(class)

        if IsValid(wp) then
            return wp, class
        else
            return nil
        end
    end
end


if CLIENT then
    local target = nil
    local duration = 0
    local timer = 0
    hook.Add('InputMouseApply', 'pointshoot.aim', function(cmd, x, y, ang)
        if not target then 
            return 
        end

        timer = timer + RealFrameTime()

        local pos = pointshoot:GetMarkPos(target)
        if not pos then
            target = nil
            hook.Run('PointShootAimFinish', nil, nil)
            return
        end

        local targetDir = (pos - EyePos()):GetNormal()
        local origin = cmd:GetViewAngles()
        local rate = math.Clamp(timer / duration, 0, 1) 
        rate = origin:Forward():Dot(targetDir) > 0.9995 and 1 or rate
     
        cmd:SetViewAngles(LerpAngle(rate, origin, targetDir:Angle()))

        if rate == 1 then
            hook.Run('PointShootAimFinish', pos, targetDir)
            target, duration, timer = nil, 0, 0
        end
    end)

    function pointshoot:Aim(mark, dura)
        duration = math.max(dura, 0.01)
        timer = 0
        target = mark
    end

    function pointshoot:AutoAim()
        if not LocalPlayer():Alive() or LocalPlayer():InVehicle() then
            hook.Remove('Think', 'pointshoot.autoaim')
            net.Start('PointShootFinish')
            net.SendToServer()
            self:FinishEffect(LocalPlayer())
            return
        end

        -- 瞄准、射击
        if not self.Marks or #self.Marks < 1 then
            hook.Remove('Think', 'pointshoot.autoaim')
            net.Start('PointShootFinish')
            net.SendToServer()
            self:FinishEffect(LocalPlayer())
            return
        end

        local wp = pointshoot:GetOriginWeapon(LocalPlayer())
        if self.aiming or (IsValid(wp) and wp:GetNextPrimaryFire() > RealTime()) then
            return
        end

        self:Aim(self.Marks[#self.Marks], pointshoot.CVarsCache.ps_aim_cost)
        self.aiming = true

        return true
    end

    hook.Add('PointShootAimFinish', 'pointshoot.fire', function(pos, dir)
        local self = pointshoot
        self.aiming = false

        if not LocalPlayer():Alive() or LocalPlayer():InVehicle() then
            return
        end

        local wp = self:GetOriginWeapon(LocalPlayer())
        if pos and dir and IsValid(wp) and istable(wp.ps_wpdata) and wp:Clip1() > 0 then 
            wp.ps_wpdata.FireHandle(wp, LocalPlayer():EyePos(), pos, dir, LocalPlayer())
        end
        
        table.remove(self.Marks, #self.Marks)
        self.shootCount = self.shootCount + 1
        
        if #self.Marks < 1 or (RealTime() - self.fireSyncTime >= 0.5 and self.shootCount > 0) then
            self.fireSyncTime = RealTime()
        
            net.Start('PointShootFireSync')
                net.WriteInt(self.shootCount, 32)
            net.SendToServer()

            self.shootCount = 0
            if #self.Marks < 1 then wp:SetNextPrimaryFire(0) end
        end
    end)

elseif SERVER then
    util.AddNetworkString('PointShootFinish')
    util.AddNetworkString('PointShootFireSync')

    net.Receive('PointShootFireSync', function(len, ply)
        local count = net.ReadInt(32)
        pointshoot:FireSync(ply, count)
    end)

    net.Receive('PointShootFinish', function(len, ply)
        pointshoot:FinishEffect(ply)
    end)

    function pointshoot:FireSync(ply, count)
        local idx = ply:EntIndex()
        local marks = self.Marks[idx]
        local wp = self:GetOriginWeapon(ply)
        if not IsValid(wp) or not wp.ps_wpdata then return end


        local len = #marks
        if not istable(marks) or len < 1 then
            return
        end
        
        local start = ply:EyePos()
        for i = len, math.max(len - count + 1, 1), -1 do
            local endpos = pointshoot:GetMarkPos(marks[i])
            if endpos then 
                wp.ps_wpdata.FireHandle(wp, start, endpos, nil, ply)
            end
            
            table.remove(marks, i)
        end
    end
end