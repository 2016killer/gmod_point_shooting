if SERVER then
	AddCSLuaFile()
end

SWEP.Slot = 4
SWEP.SlotPos = 99
SWEP.DrawAmmo = false
SWEP.PrintName = 'Fake Gun'
SWEP.Category = 'Other'
SWEP.Author = 'Zack'

SWEP.ViewModel = 'models/weapons/c_arms_hev.mdl'
SWEP.WorldModel = 'models/weapons/v_pistol.mdl'
SWEP.Spawnable = true
SWEP.HoldType = 'melee2'


SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFlip1 = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0

function SWEP:Init(wpclassList)
    local total = 0
    for _, wpclass in ipairs(wpclassList) do
        local wp = self:GetOwner():GetWeapon(wpclass)
        if IsValid(wp) then
            total = total + wp:Clip1()
        end
    end
    self:SetClip1(total)
    local wpdata = weapons.GetStored(wpclassList[1])
    if wpdata and wpdata.ViewModel then
        print(wpdata.ViewModel)
        self:GetOwner():GetViewModel(0):SetWeaponModel(wpdata.ViewModel, self)
        self:GetOwner():GetViewModel(1):SetWeaponModel(wpdata.ViewModel, self)
    end
end


function SWEP:Deploy()
	--get the second viewmodel
	local viewmodel1 = self:GetOwner():GetViewModel(1)
	if (IsValid(viewmodel1)) then
		--associate its weapon to us
		viewmodel1:SetWeaponModel(self.ViewModel , self)
	end
	
	self:SendViewModelAnim(ACT_VM_DEPLOY , 1)
	
	return true
end

function SWEP:Holster()
	local viewmodel1 = self:GetOwner():GetViewModel(1)
	if (IsValid(viewmodel1)) then
		--set its weapon to nil, this way the viewmodel won't show up again
		viewmodel1:SetWeaponModel(self.ViewModel , nil)
	end
	
	return true
end

--since self:SendWeaponAnim always sends the animation to the first viewmodel, we need this as a replacement
function SWEP:SendViewModelAnim(act , index , rate)
	
	if (not game.SinglePlayer() and not IsFirstTimePredicted()) then
		return
	end
	
	local vm = self:GetOwner():GetViewModel(index)
	
	if (not IsValid(vm)) then
		return
	end
	
	local seq = vm:SelectWeightedSequence(act)
	
	if (seq == -1) then
		return
	end
	
	vm:SendViewModelMatchingSequence(seq)
	vm:SetPlaybackRate(rate or 1)
end

function SWEP:PrimaryAttack()
	
	self:SendViewModelAnim(ACT_VM_PRIMARYATTACK , 0)--target the first viewmodel
	self:SetNextPrimaryFire(CurTime() + 0.25)
	
end

function SWEP:SecondaryAttack()
	
	self:SendViewModelAnim(ACT_VM_PRIMARYATTACK , 1)--target the second
	self:SetNextSecondaryFire(CurTime() + 0.25)
	
end