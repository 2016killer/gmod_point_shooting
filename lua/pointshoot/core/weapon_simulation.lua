--[[
    作者: 白狼
]]

function pointshoot:RegisterWhiteList(class, data)
    self.WhiteList[class] = data
end

function pointshoot:RegisterWhiteListBase(classbase, data, top_or_bottom)
    data.Base = classbase

    for i = #self.WhiteListBase, 1, -1 do
        local v = self.WhiteListBase[i]
        if v.Base == classbase then
            table.remove(self.WhiteListBase, i)
            break
        end
    end

    if top_or_bottom == true then
        table.insert(self.WhiteListBase, 1, data)
    else
        table.insert(self.WhiteListBase, data)
    end
end

function pointshoot:WeaponParse(wp)
    if not IsValid(wp) then 
        return false
    end

    if wp.ps_wppIsParsed then 
        return true
    end

    local class = wp:GetClass()
    local result = self.WhiteList[class]

    if not result then
        for _, data in ipairs(self.WhiteListBase) do
            if weapons.IsBasedOn(class, data.Base) then
                result = data
                break
            end
        end
    end
    
    if result then
        if result.Modify then result.Modify(wp) end

        wp.ps_wppGetRPM = result.GetRPM
        wp.ps_wppPlayAttackAnim = result.PlayAttackAnim
        wp.ps_wppGetBulletInfo = result.GetBulletInfo
        wp.ps_wppDecrClip = result.DecrClip
        wp.ps_wppGetClip = result.GetClip

        wp.ps_wppIsParsed = true
        wp.ps_wppdata = result
        return true
    else
        return false
    end
end
-- ============= 鼠标控制 =============
if CLIENT then
    local target = nil
    local duration = 0
    local Timer = 0
    function pointshoot:InputMouseApply(cmd, x, y, ang)
        if not target then 
            return 
        end

        Timer = Timer + RealFrameTime()

        local pos = pointshoot:GetMarkPos(target)
        if not pos then
            target = nil
            hook.Run('PointShootAimFinish', nil, nil)
            return
        end

        local targetDir = (pos - LocalPlayer():EyePos()):GetNormal()
        local origin = cmd:GetViewAngles()
        local rate = math.Clamp(Timer / duration, 0, 1) 
        rate = origin:Forward():Dot(targetDir) > 0.9995 and 1 or rate
        
        cmd:SetViewAngles(LerpAngle(rate, origin, targetDir:Angle()))

        if rate == 1 then
            hook.Run('PointShootAimFinish', pos, targetDir)
            target, duration, Timer = nil, 0, 0
        end
    end

    function pointshoot:Aim(mark, dura)
        duration = math.max(dura, 0.01)
        Timer = 0
        target = mark
    end

    local punchOffset = 0
    local punchAcc = 0
    local punchVel = 0
    function pointshoot:Recoil(wep, vm, oP, oA, p, a)
        if math.abs(punchOffset) < 0.05 and math.abs(punchVel) < 0.05 and math.abs(punchAcc) < 0.05 then
            punchOffset = 0
            punchVel = 0
            punchAcc = 0
        end

        local dt = RealFrameTime()
        punchOffset = punchOffset + (punchVel + punchAcc * 0.5 * dt) * dt//二阶泰勒
        punchAcc = (-punchOffset) * 100 - 10 * punchVel
        punchVel = punchVel + punchAcc * dt	

        return p + punchOffset * a:Forward(), a
    end

    function pointshoot:SetRecoil(offset, vel, acc)
        punchOffset = offset or punchOffset
        punchVel = vel or punchVel
        punchAcc = acc or punchAcc
    end


    function pointshoot:AutoAim()
        if not self.Marks or #self.Marks < 1 or 
           not IsValid(LocalPlayer():GetActiveWeapon()) or 
           not LocalPlayer():Alive() or LocalPlayer():InVehicle() 
        then
            self:DisableAim()
            self:CallDoubleEnd('CTSFinish', LocalPlayer())
            return
        end

        local mark = self.Marks[#self.Marks]
        if self.aiming == mark then
            return
        end

        self.aiming = mark
        self:Aim(mark, self.CVarsCache.ps_aim_cost)
        

        return true
    end

    function pointshoot:AimFinish(pos, dir)
        self.aiming = false
        if self.NextPrimaryFire > RealTime() then
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

        local wp = LocalPlayer():GetActiveWeapon()
        local parseSucc = self:WeaponParse(wp)
        
        if not pos or not parseSucc or wp:ps_wppGetClip(LocalPlayer()) < 1 then 
            return
        end
  
        if pointshoot.CVarsCache.ps_rpm_mode then
            pointshoot.NextPrimaryFire = RealTime() + 60 / 
            pointshoot.CVarsCache.ps_rpm_mul / 
            (wp:ps_wppGetRPM() or 99999)
        else
            pointshoot.NextPrimaryFire = 0
        end

        wp:ps_wppPlayAttackAnim(LocalPlayer())
    end
    

    function pointshoot:EnableAim()
        self.aiming = false
        self.shootCount = 0
        self.fireSyncTime = 0
        self.NextPrimaryFire = 0
        
        target = nil
        duration = 0
        Timer = 0

        punchOffset = 0
        punchVel = 0
        punchAcc = 0

        hook.Add('InputMouseApply', 'pointshoot.autoaim', function(cmd, x, y, ang) self:InputMouseApply(cmd, x, y, ang) end)
        hook.Add('Think', 'pointshoot.autoaim', function() self:AutoAim() end)
        hook.Add('PointShootAimFinish', 'pointshoot.autoaim', function(pos, dir) self:AimFinish(pos, dir) end)
        timer.Remove('pointshoot_remove_recoil')
        hook.Add('CalcViewModelView', 'pointshoot.recoil', function(wep, vm, oP, oA, p, a)
            local wp, wa = p, a
            if isfunction(wep.CalcViewModelView) then wp, wa = wep:CalcViewModelView(vm, oP, oA, p, a) end
            if isfunction(wep.GetViewModelPosition) then wp, wa = wep:GetViewModelPosition(p, a) end
            if not (wp and wa) then wp, wa = p, a end
            return self:Recoil(wep, vm, oP, oA, wp, wa)
        end)
    end


    function pointshoot:DisableAim()
        hook.Remove('InputMouseApply', 'pointshoot.autoaim')
        hook.Remove('Think', 'pointshoot.autoaim')
        hook.Remove('PointShootAimFinish', 'pointshoot.autoaim')
        timer.Remove('pointshoot_remove_recoil')
        timer.Create('pointshoot_remove_recoil', 2, 1, function()
            hook.Remove('CalcViewModelView', 'pointshoot.recoil')
        end)
    end
elseif SERVER then
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
        local wp = ply:GetActiveWeapon()
        local parseSucc = self:WeaponParse(wp)

        if not parseSucc then 
            for i = len, math.max(len - count + 1, 1), -1 do
                table.remove(marks, i)
            end
        else
            for i = len, math.max(len - count + 1, 1), -1 do
                local mark = marks[i]
                table.remove(marks, i)

                if wp:ps_wppGetClip(ply) < 1 then continue end

                local endpos = pointshoot:GetMarkPos(mark)
                if not endpos then continue end

                local dir = (endpos - start):GetNormal()
                local bulletInfo = wp:ps_wppGetBulletInfo(ply, start, endpos, dir)
                if not bulletInfo then 
                    wp:ps_wppDecrClip(ply)
                    continue 
                end

                local damage = (bulletInfo.Damage or 1)
                bulletInfo.Dir = dir
                bulletInfo.Attacker = ply
                bulletInfo.Inflictor = wp

                bulletInfo.Src = start
                bulletInfo.Damage = damage * pointshoot.CVarsCache.ps_damage_mul
                wp:FireBullets(bulletInfo)

                bulletInfo.Src = endpos
                bulletInfo.Damage = damage * pointshoot.CVarsCache.ps_damage_penetration_mul
                wp:FireBullets(bulletInfo)

                wp:ps_wppDecrClip(ply)
            end
        end
    end
end