SWEP:RegisterClientToServer('CTSExecuteRequest')
SWEP:RegisterServerToClient('STCExecute')

function SWEP:CTSExecuteRequest()
    local owner = self:GetOwner()

    if SERVER and (not IsValid(owner) or not owner:IsPlayer() or not IsValid(owner:GetWeapon(self.OriginWeaponClass or ''))) then
        pointshoot:TimeScaleFadeIn(1, nil)
    elseif SERVER then
        owner:SelectWeapon(owner:GetWeapon(self.OriginWeaponClass or ''))
    elseif CLIENT then
        return
    end
end

function SWEP:STCExecute()
    if SERVER then
        local owner = self:GetOwner()
        pointshoot.Marks[owner:EntIndex()] = table.Reverse(self.Marks)
        self:ExecuteEffect()
    elseif CLIENT and (not self.Marks or #self.Marks < 1) then
        pointshoot:DisableAim()
    elseif CLIENT then
        pointshoot.Marks = table.Reverse(self.Marks)
        pointshoot:EnableAim()
        self:ExecuteEffect()
        RunConsoleCommand('pointshoot_remove')
    end
end