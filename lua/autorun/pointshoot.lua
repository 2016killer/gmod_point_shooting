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

-- ============= 穿墙 =============
function pointshoot:TracePenetration(dis)
    dis = dis or 4000
    local filter = {LocalPlayer()}
    local start = LocalPlayer():EyePos()

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

-- ============= 结束 =============
function pointshoot:FinishEffect(ply)
    if SERVER then
        timer.Simple(0.15, function()
            self:TimeScaleFadeIn(1, nil)
        end)
        self:TimeScaleFadeIn(0.1, nil)
    elseif CLIENT then
        return
    end
end

net.Receive('PointShootFinish', function(len, ply)
    pointshoot:FinishEffect(ply)
end)

-- ============= 鼠标控制 =============
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

        local targetDir = (pos - LocalPlayer():EyePos()):GetNormal()
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
        if not self.Marks or #self.Marks < 1 or 
            not LocalPlayer():Alive() or LocalPlayer():InVehicle() 
        then
            hook.Remove('Think', 'pointshoot.autoaim')
            net.Start('PointShootFinish')
            net.SendToServer()
            
            return
        end

        local originwp = pointshoot:GetOriginWeapon(LocalPlayer())
        if self.aiming or (IsValid(originwp) and self.NextPrimaryFire > RealTime()) then
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

        table.remove(self.Marks, #self.Marks)
        self.shootCount = self.shootCount + 1
        
        if #self.Marks < 1 or (RealTime() - self.fireSyncTime >= 0.5 and self.shootCount > 0) then
            self.fireSyncTime = RealTime()
        
            net.Start('PointShootFireSync')
                net.WriteInt(self.shootCount, 32)
            net.SendToServer()

            self.shootCount = 0
        end

        if pos then 
            local originwp = self:GetOriginWeapon(LocalPlayer())
            if IsValid(originwp) and originwp:Clip1() > 0 then
                self.Fire(originwp, LocalPlayer():EyePos(), pos, dir, LocalPlayer())
            end
        end
    end)

elseif SERVER then
    util.AddNetworkString('PointShootFinish')
    util.AddNetworkString('PointShootFireSync')

    net.Receive('PointShootFireSync', function(len, ply)
        local count = net.ReadInt(32)
        pointshoot:FireSync(ply, count)
    end)


    function pointshoot:FireSync(ply, count)
        local idx = ply:EntIndex()
        local marks = self.Marks[idx]

        local len = #marks
        if not istable(marks) or len < 1 then return end
        
        local start = ply:EyePos()
        local originwp = self:GetOriginWeapon(ply)
        if not IsValid(originwp) then 
            for i = len, math.max(len - count + 1, 1), -1 do
                table.remove(marks, i)
            end
        else
            for i = len, math.max(len - count + 1, 1), -1 do
                local mark = marks[i]
                table.remove(marks, i)

                local endpos = pointshoot:GetMarkPos(mark)
                if endpos then 
                    self.Fire(originwp, start, endpos, nil, ply)
                end
            end
        end
    end
end