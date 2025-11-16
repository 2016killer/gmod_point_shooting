function SWEP:SetStart(wpclass)
    self.OriginWeaponClass = wpclass
    if SERVER then 
        self:CallOnClient('SetStart', wpclass) 
    elseif CLIENT then
        local originwp = LocalPlayer():GetWeapon(wpclass)
        local wpdata = pointshoot:WeaponParse(originwp)
        if not wpdata then return end
        self.Clip = pointshoot.GetAmmo(originwp, LocalPlayer())
    end
end


if SERVER then
    hook.Add('PlayerSwitchWeapon', 'pointshoot.start', function(ply, oldwp, newwp)
        if not IsValid(oldwp) or oldwp:GetClass() == 'pointshoot'then
            return
        end

        if not IsValid(newwp) or newwp:GetClass() ~= 'pointshoot' then
            return
        end

        local wpdata = pointshoot:WeaponParse(oldwp)
        if not wpdata then
            return true
        end
        
        newwp:SetStart(oldwp:GetClass())
        if not pointshoot.CVarsCache.ps_inf_power then
            newwp:SetPowerCost(pointshoot.CVarsCache.ps_power_cost)
        end
    end)

    concommand.Add('pointshoot', function(ply, cmd, args)
        local pswp = ents.Create('pointshoot')
        pswp:SetPos(ply:GetPos())
        pswp:Spawn()
        ply:PickupWeapon(pswp)
        ply:SelectWeapon(pswp)
    end)

    concommand.Add('pointshoot_remove', function(ply, cmd, args)
        local wp = ply:GetWeapon('pointshoot')
        if IsValid(wp) then wp:Remove() end
    end)

end