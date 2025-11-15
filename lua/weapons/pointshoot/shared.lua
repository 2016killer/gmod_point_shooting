SWEP.Slot = 4
SWEP.SlotPos = 99
SWEP.PrintName = 'PointShoot'
SWEP.Category = 'Legend'
SWEP.Author = 'Zack'

SWEP.ViewModel = 'models/weapons/c_arms_citizen.mdl'
SWEP.WorldModel = 'models/weapons/w_pistol.mdl'
SWEP.Spawnable = true

SWEP.UseHands = false
SWEP.ViewModelFlip = false
SWEP.ViewModelFlip1 = true

SWEP.Primary.ClipSize = 0
SWEP.Primary.DefaultClip = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.PrimaryAttack = function() end
SWEP.SecondaryAttack = function() end

SWEP.DrawAmmo = false


local function LoadLuaFiles(dirname)
	local path = 'weapons/pointshoot/' .. dirname .. '/'
	local filelist = file.Find(path .. '*.lua', 'LUA')

	for _, filename in pairs(filelist) do
		client = string.StartWith(filename, 'cl_')
		server = string.StartWith(filename, 'sv_')

		if SERVER then
			if not client then
				include(path .. filename)
				print('[PointShootWeapon]: AddFile:' .. filename)
			end

			if not server then
				AddCSLuaFile(path .. filename)
			end
		else
			if client or not server then
				include(path .. filename)
				print('[PointShootWeapon]: AddFile:' .. filename)
			end
		end
	end
end


AddCSLuaFile()
AddCSLuaFile('common.lua')
include('common.lua')
LoadLuaFiles('core')
LoadLuaFiles('effects')



function SWEP:Deploy()
    if SERVER then
        local owner = self:GetOwner()
        if not IsValid(owner) or not owner:IsPlayer() then 
            return 
        end
        local idx = owner:EntIndex()
        self.Marks = {}
        pointshoot.Marks[idx] = {}
        self:CallOnClient('Deploy')
    elseif CLIENT then
        self.Marks = {}
        pointshoot.Marks = {}
        self.LockThink = false
    end
    self:StartEffect()

    return true
end

function SWEP:Holster()
    if SERVER then
        game.SetTimeScale(1)
        self:CallOnClient('Holster')
    elseif CLIENT then
        self:ClearPowerCost()
    end
    
    return true
end

function SWEP:Think()
	if SERVER or self.LockThink then return end

	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then 
		return 
	end

    local attackKeyDown = owner:KeyDown(IN_ATTACK)
    
    if not self.attackKey and attackKeyDown then
        self:MouseLeftPress()
    end
    self.attackKey = owner:KeyDown(IN_ATTACK)


    if owner:KeyDown(IN_ATTACK2) then
        self.LockThink = true
        self:CallDoubleEnd('CTSExecuteRequest', self:GetLeftMasks())
        self:ClearPowerCost()
        return
    end

    if self:PowerThink() then
        self.LockThink = true
        self:CallDoubleEnd('CTSExecuteRequest', self:GetLeftMasks())
        self:ClearPowerCost()
    end
end

function SWEP:MouseLeftPress()
    if self:Clip1() <= 0 then 
        return
    end

    self:AddMarkFromTrace(pointshoot:TracePenetration())
    self:MarkEffect()

    self:SetClip1(self:Clip1() - 1)
end