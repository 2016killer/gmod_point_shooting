SWEP:RegisterClientToServer('CTSExecuteRequest')
SWEP:RegisterServerToClient('STCExecute')

function SWEP:CTSExecuteRequest(endpower)
    local owner = self:GetOwner()

    if SERVER and (not IsValid(owner) or not owner:IsPlayer() or not IsValid(owner:GetWeapon(self.OriginWeaponClass or ''))) then
        pointshoot:TimeScaleFadeIn(1, nil)
    elseif SERVER then
        owner:SelectWeapon(owner:GetWeapon(self.OriginWeaponClass or ''))
        owner:SetNW2Float('psnw_power', math.Clamp(endpower or 1, 0, 1))
    elseif CLIENT then
        return
    end
end

function SWEP:STCExecute()
    if SERVER then
        local owner = self:GetOwner()
        pointshoot.Marks[owner:EntIndex()] = table.Reverse(self.Marks)
        pointshoot.PowerBuoyancyTime = CurTime() + 2
        self:ExecuteEffect()
        // PrintTable(pointshoot.Marks[owner:EntIndex()])
    elseif CLIENT and (not self.Marks or #self.Marks < 1) then
        pointshoot:DisableAim()
        RunConsoleCommand('pointshoot_remove')
    elseif CLIENT then
        pointshoot:ThinkTimerRemove('pointshoot_thinktimer_execute')

        local originwp = LocalPlayer():GetWeapon(self.OriginWeaponClass or '')
        local deployTime = CurTime()
        local deployDuration = originwp:ps_wppGetDeployDuration(LocalPlayer()) or 0
        pointshoot.Marks = table.Reverse(self.Marks)
        // PrintTable(pointshoot.Marks)
        pointshoot:ThinkTimer('pointshoot_thinktimer_execute', 
            deployDuration * pointshoot.CVarsCache.ps_deploy_duration_mul, 
            1, 
            function()
                pointshoot:EnableAim()
                if IsValid(self) then self:ExecuteEffect() end
                RunConsoleCommand('pointshoot_remove')
            end, 
            'cur'
        )
    end
end