SWEP:RegisterClientToServer('CTSExecuteRequest')


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