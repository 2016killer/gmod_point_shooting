SWEP.Slot = 4
SWEP.SlotPos = 99
SWEP.PrintName = 'PointShoot'
SWEP.Category = 'Legend'
SWEP.Author = 'Zack'

SWEP.ViewModel = 'models/weapons/c_arms_citizen.mdl'
SWEP.WorldModel = 'models/weapons/w_pistol.mdl'
SWEP.Spawnable = false

SWEP.UseHands = false
SWEP.ViewModelFlip = false
SWEP.ViewModelFlip1 = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.PrimaryAttack = function() end
SWEP.SecondaryAttack = function() end

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


-- ========= 切入时启动 =========
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
        self.attack2KeyLock = false
    end
    self:StartEffect()

    return true
end

function SWEP:Holster()
    game.SetTimeScale(1)
    return true
end

function SWEP:Think()
	if SERVER then return end

	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then 
		return 
	end

    local attackKeyDown = owner:KeyDown(IN_ATTACK)
    
    if not self.attackKey and attackKeyDown then
        self:MouseLeftPress()
    end
    self.attackKey = owner:KeyDown(IN_ATTACK)


    if not self.attack2KeyLock and owner:KeyDown(IN_ATTACK2) then
        self:MouseRightPress()
        self.attack2KeyLock = true
    end
end

function SWEP:MouseLeftPress()
	self:AddMarkFromTrace(LocalPlayer():GetEyeTrace())
    self:MarkEffect()
end

function SWEP:MouseRightPress()
    self:CallDoubleEnd('CTSExecuteRequest', self:GetLeftMasks())
end
