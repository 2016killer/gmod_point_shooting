AddCSLuaFile()

ENT.Type = 'anim'
ENT.Base = 'base_gmodentity'
ENT.PrintName = 'Melee World'
ENT.Spawnable = true
ENT.Category = 'Other'

function ENT:Bind(wp)
    self.wp = wp
    self:SetModel(wp:GetModel())
    wp:SetPos(self:GetPos())
    wp:SetAngles(self:GetAngles())
    wp:SetParent(self)
end

function ENT:Initialize()
    if CLIENT then return end
    if not IsValid(self.wp) then
        local wp = ents.Create('weapon_crowbar')
        wp = wp
        wp:SetPos(self:GetPos())
        wp:SetAngles(self:GetAngles())
        wp:Spawn()
        self:Bind(wp)
    end

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
end

function ENT:Use(activator, caller, useType, value)
    if IsValid(self.wp) then activator:PickupWeapon(self.wp) end
    self:Remove()
end