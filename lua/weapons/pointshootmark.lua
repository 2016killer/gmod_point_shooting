SWEP.Slot = 4
SWEP.SlotPos = 99
SWEP.PrintName = 'PointShoot'
SWEP.Category = 'Other'
SWEP.Author = 'Zack'

SWEP.ViewModel = 'models/weapons/c_pistol.mdl'
SWEP.WorldModel = 'models/weapons/w_pistol.mdl'
SWEP.Spawnable = false

SWEP.UseHands = false
SWEP.ViewModelFlip = false
SWEP.ViewModelFlip1 = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0



function SWEP:Think()
	if SERVER then
		return
	end

	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then 
		return 
	end

	-- 单人模式客户端需要自行捕获攻击键
	if game.SinglePlayer() then
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

	-- 瞄准、射击
	if self.State == 'EXECUTE' then
		if not self.Marks or #self.Marks < 1 then
			self:CallDoubleEnd('CTSFinish')
			return
		end

		if self.aiming or not self:CheckFireAble() then
			return
		end

		self:AutoAim(self.Marks[#self.Marks], 0.1, true)
		self.aiming = true
	end

	return true
end

hook.Add('PointShootAutoAimFinish', 'pointshoot.fire', function(wp, targetDir)
	if not IsValid(wp) then
		return
	end
	wp.aiming = false

	wp:ClientFire(targetDir)
	table.remove(wp.Marks, #wp.Marks)
	wp.shootCount = wp.shootCount + 1
	
	if #wp.Marks < 1 or (wp.drawtime - wp.fireTime >= 0.25 and wp.shootCount > 0) then
		wp.fireTime = wp.drawtime
		wp:CallDoubleEnd('CTSShoot', wp.shootCount)
		wp.shootCount = 0
	end

	wp:SetNextPrimaryFire(RealTime() + 0.1)
end)
