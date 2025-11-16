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
SWEP.IconOverride = 'hitman/pointshoot.jpg'

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
        if not IsValid(owner) or not owner:IsPlayer() then return end
        local idx = owner:EntIndex()
        self.Marks = {}
        pointshoot.Marks[idx] = {}
        self:CallOnClient('Deploy')
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
    end
    self:StartEffect()

    return true
end

function SWEP:Holster()
    local owner = self:GetOwner()
    if SERVER and (not IsValid(owner) or not owner:IsPlayer()) then
        pointshoot:TimeScaleFadeIn(1, nil)
    elseif SERVER and (not self.Marks or #self.Marks < 1) then
        pointshoot:TimeScaleFadeIn(1, nil)
    elseif SERVER then
        pointshoot.Marks[owner:EntIndex()] = table.Reverse(self.Marks)
        self:ExecuteEffect()
        self:CallOnClient('Holster')
    elseif CLIENT and (not self.Marks or #self.Marks < 1) then
        pointshoot:DisableAim()
    elseif CLIENT then
        pointshoot.Marks = table.Reverse(self.Marks)
        pointshoot:EnableAim()
        self:ExecuteEffect()
        // RunConsoleCommand('pointshoot_remove')
    end

    return true
end

function SWEP:Think()
	if SERVER or self.LockThink then return end

	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then 
		return 
	end

    local attackKeyDown = game.SinglePlayer() and owner:KeyDown(IN_ATTACK) or input.IsMouseDown(MOUSE_LEFT)
    if not self.attackKey and attackKeyDown then
        self:MouseLeftPress()
    end
    self.attackKey = attackKeyDown


    local rightKeyDown = game.SinglePlayer() and owner:KeyDown(IN_ATTACK2) or input.IsMouseDown(MOUSE_RIGHT)
    if rightKeyDown or self:PowerThink() then
        self.LockThink = true
        self:CallDoubleEnd('CTSExecuteRequest')
        self:ClearPowerCost()
        return
    end
end

function SWEP:MouseLeftPress()
    if not self.Clip or self.Clip <= 0 then 
        return
    end
    self:CallDoubleEnd('CTSAddMarks', pointshoot:PackMark(pointshoot:TracePenetration()))
    self:MarkEffect()
    self.Clip = self.Clip - 1
end