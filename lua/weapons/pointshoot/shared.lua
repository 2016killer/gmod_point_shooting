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
    end
    self:StartEffect()

    return true
end

function SWEP:Holster()

    if SERVER then
        local originwp, _ = self:GetOriginWeapon(ply)
        if IsValid(originwp) then 
            ply:SelectWeapon(originwp)
        end

        if not IsValid(originwp) or not self.Marks[ply:EntIndex()] or #self.Marks[ply:EntIndex()] < 1 then
            self:TimeScaleFadeIn(1, nil)
            return 
        end

        net.Start('PointShootExecute')
        net.Send(ply)
    elseif CLIENT then
        self.aiming = false
        self.shootCount = 0
        self.fireSyncTime = RealTime()

        local originwp = self:GetOriginWeapon(LocalPlayer())
        if not IsValid(originwp) or #self.Marks < 0 then 
            hook.Remove('Think', 'pointshoot.autoaim')
            return 
        end

        self.NextPrimaryFire = 0

        hook.Add('Think', 'pointshoot.autoaim', function()
            self:AutoAim()
        end)
    end
    self:ExecuteEffect(ply)
    // PrintTable(self.Marks)


    if SERVER then 
        local owner = self:GetOwner()
        if not IsValid(owner) or not owner:IsPlayer() then return end
        self.Marks = self.Marks or {}
        table.Add(self.Marks, {...})

        pointshoot.Marks[owner:EntIndex()] = self.Marks

        pointshoot:Execute(owner)
    elseif CLIENT then
        pointshoot.Marks = self.Marks
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
        self:CallDoubleEnd('CTSExecuteRequest', self:GetLeftMasks())
        self:ClearPowerCost()
        return
    end
end

function SWEP:MouseLeftPress()
    if not self.Clip or self.Clip <= 0 then 
        return
    end
    self:CallDoubleEnd('CTSAddMarks', pointshoot:TracePenetration())
    self:MarkEffect()
    self.Clip = self.Clip - 1
end