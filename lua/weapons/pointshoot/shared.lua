if SERVER then
	AddCSLuaFile()
	AddCSLuaFile('core/cl_autoaim.lua')
	AddCSLuaFile('core/cl_calcview.lua')
	AddCSLuaFile('core/cl_drawselect.lua')
	AddCSLuaFile('core/cl_fakehand.lua')
	AddCSLuaFile('core/cl_fire.lua')
	AddCSLuaFile('core/cl_flash.lua')
	AddCSLuaFile('core/cl_particle.lua')
	AddCSLuaFile('core/timescale.lua')
	include('core/timescale.lua')
else
	include('core/cl_autoaim.lua')
	include('core/cl_calcview.lua')
	include('core/cl_drawselect.lua')
	include('core/cl_fakehand.lua')
	include('core/cl_fire.lua')
	include('core/cl_flash.lua')
	include('core/cl_particle.lua')
	include('core/timescale.lua')
end

SWEP.Slot = 4
SWEP.SlotPos = 99
SWEP.PrintName = 'Fake Gun'
SWEP.Category = 'Other'
SWEP.Author = 'Zack'

SWEP.ViewModel = 'models/weapons/c_pistol.mdl'
SWEP.WorldModel = 'models/weapons/v_pistol.mdl'
SWEP.Spawnable = true

SWEP.UseHands = false
SWEP.ViewModelFlip = false
SWEP.ViewModelFlip1 = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0


if CLIENT then
	concommand.Add('test', function(ply)
		print(ply:GetActiveWeapon():GetWeaponViewModel())
	end)
end


function SWEP:Deploy()
	print('fuckyou')
	// self:ScreenFlash(150, 0, 0.2)

	--get the second viewmodel
	// local viewmodel1 = self:GetOwner():GetViewModel(1)
	// if (IsValid(viewmodel1)) then
	// 	--associate its weapon to us
	// 	viewmodel1:SetWeaponModel(self.ViewModel , self)
	// end
	
	// self:SendViewModelAnim(ACT_VM_DEPLOY , 1)
	
	return true
end

function SWEP:Think()
	print('fuckyouaaa')
	// self:ScreenFlash(150, 0, 0.2)

	--get the second viewmodel
	// local viewmodel1 = self:GetOwner():GetViewModel(1)
	// if (IsValid(viewmodel1)) then
	// 	--associate its weapon to us
	// 	viewmodel1:SetWeaponModel(self.ViewModel , self)
	// end
	
	// self:SendViewModelAnim(ACT_VM_DEPLOY , 1)
	
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

