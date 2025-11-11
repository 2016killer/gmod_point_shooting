local function LoadLuaFiles(dirname)
	local path = 'weapons/pointshoot/' .. dirname .. '/'
	local filelist = file.Find(path .. '*.lua', 'LUA')

	for _, filename in pairs(filelist) do
		client = string.StartWith(filename, 'cl_')
		server = string.StartWith(filename, 'sv_')

		if SERVER then
			if not client then
				include(path .. filename)
				print('[PointShoot]: AddFile:' .. filename)
			end

			if not server then
				AddCSLuaFile(path .. filename)
			end
		else
			if client or not server then
				include(path .. filename)
				print('[PointShoot]: AddFile:' .. filename)
			end
		end
	end
end
AddCSLuaFile()
AddCSLuaFile('call.lua')
include('call.lua')
LoadLuaFiles('core')



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

SWEP:RegisterServerToClient('STCStart')
SWEP:RegisterClientToServer('CTSFinish')

function SWEP:STCStart()
	self.State = 'START'
	if SERVER then
		self:TimeScaleFadeIn(0, 0.1)
	elseif CLIENT then
		surface.PlaySound('hitman/start.mp3')
		self:ParticleEffect()
		self:ScreenFlash(150, 0, 0.2)
	end
end


function SWEP:CTSFinish()
	self.State = 'FINISH'
	if SERVER then
		self:TimeScaleFadeIn(1, 0.1)
	end
end


function SWEP:Deploy()
	if SERVER and self.StartAtOnce then
		self:CallDoubleEnd('STCStart')
	end
	return true
end

function SWEP:Think()
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then 
		return 
	end

	-- 单人模式客户端需要自行捕获攻击键
	if game.SinglePlayer() and CLIENT then
		local attackKeyDown = owner:KeyDown(IN_ATTACK)
		
		if not self.attackKey and attackKeyDown then
			self:PrimaryAttack()
		end
		self.attackKey = owner:KeyDown(IN_ATTACK)

		local attack2KeyDown = owner:KeyDown(IN_ATTACK2)
		if not self.attack2Key and attack2KeyDown then
			self:SecondaryAttack()
		end
		self.attack2Key = owner:KeyDown(IN_ATTACK2)
	end
	
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
	if SERVER and self.State ~= 'START' then
		self:CallDoubleEnd('STCStart')
	elseif CLIENT then
		surface.PlaySound('hitman/mark.mp3')
	end
end

function SWEP:SecondaryAttack()
	if CLIENT then
		self:CallDoubleEnd('CTSFinish')
	end
end

