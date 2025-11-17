SWEP:RegisterServerToClient('STCStart')

function SWEP:SetStartData(wpclass, power, powercost)
    self.OriginWeaponClass = wpclass
    // self.Power = powercost ~= 0 and power or nil
    // self.PowerCost = powercost ~= 0 and powercost or nil
    self.Power = power
    self.PowerCost = powercost
end

function SWEP:STCStart(wpclass, power, powercost)
    if SERVER then
        self.Marks = {}
        pointshoot.Marks[self:GetOwner():EntIndex()] = {}
    elseif CLIENT then
        self.Marks = {}
        pointshoot.Marks = {}
        self.LockThink = false

        if not game.SinglePlayer() then
            hook.Add('Think', 'PSWPThink', function()
                local wp = LocalPlayer():GetActiveWeapon()
                if not IsValid(self) or wp ~= self then
                    hook.Remove('Think', 'PSWPThink')
                    return
                end
                self:Think()
            end)
        end

        pointshoot:DisableAim()


        local originwp = LocalPlayer():GetWeapon(wpclass)
        local parseSucc = pointshoot:WeaponParse(originwp)
        if not parseSucc then return end
        
        self.OriginWeaponClass = wpclass
        self.Power = power
        self.PowerCost = powercost
        self.PowerStartTime = RealTime()
        self.Clip = originwp:ps_wppGetClip(LocalPlayer())
    end
    self:StartEffect()
end


if SERVER then
    hook.Add('PlayerSwitchWeapon', 'pointshoot.start', function(ply, oldwp, newwp)
        if not IsValid(oldwp) or oldwp:GetClass() == 'pointshoot'then
            return
        end

        if not IsValid(newwp) or newwp:GetClass() ~= 'pointshoot' then
            return
        end

        local parseSucc = pointshoot:WeaponParse(oldwp)
        if not parseSucc or oldwp:ps_wppGetClip(ply) < 1 then
            newwp:Remove()
            return true
        end
        
        newwp:SetStartData(oldwp:GetClass(), 1, pointshoot.CVarsCache.ps_power_cost)
    end)

    concommand.Add('+pointshoot', function(ply, cmd, args)
        local pswp = ents.Create('pointshoot')
        pswp:SetPos(ply:GetPos())
        pswp:Spawn()
        ply:PickupWeapon(pswp)
        ply:SelectWeapon(pswp)
    end)

    concommand.Add('-pointshoot', pointshoot.emptyfunc)

    concommand.Add('pointshoot_remove', function(ply, cmd, args)
        local wp = ply:GetWeapon('pointshoot')
        if IsValid(wp) then wp:Remove() end
    end)

end